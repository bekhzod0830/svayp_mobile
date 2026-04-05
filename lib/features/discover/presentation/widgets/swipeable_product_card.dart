import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';

// Pre-computed colors to avoid withOpacity() allocations during drag/animation frames
const _kShadowTop = BoxShadow(
  color: Color(0x28000000), // subtle outer shadow
  blurRadius: 36,
  offset: Offset(0, 16),
  spreadRadius: -4, // negative spread = depth illusion (floating)
);
const _kShadowAmbient = BoxShadow(
  color: Color(0x10000000), // wide ambient
  blurRadius: 64,
  offset: Offset(0, 24),
  spreadRadius: 0,
);
const _kShadowBehind = BoxShadow(
  color: Color(0x14000000),
  blurRadius: 18,
  offset: Offset(0, 6),
  spreadRadius: 0,
);

/// Swipe Direction Enum
enum SwipeDirection { left, right, up }

/// Swipeable Product Card - Interactive card with smooth drag gestures
/// Uses physics-based animations for natural feel on iOS and Android
class SwipeableProductCard extends StatefulWidget {
  final Product product;
  final bool isTopCard;
  final int stackIndex;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onTap;
  final ValueNotifier<double>? dragProgressNotifier;

  const SwipeableProductCard({
    super.key,
    required this.product,
    this.isTopCard = true,
    this.stackIndex = 0,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onTap,
    this.dragProgressNotifier,
  });

  @override
  State<SwipeableProductCard> createState() => SwipeableProductCardState();
}

class SwipeableProductCardState extends State<SwipeableProductCard>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  // Animation controllers for smooth physics-based animations
  AnimationController? _swipeController;
  Animation<Offset> _offsetAnimation = const AlwaysStoppedAnimation(
    Offset.zero,
  );
  Animation<double> _rotationAnimation = const AlwaysStoppedAnimation(0.0);

  // Current drag values
  Offset _dragOffset = Offset.zero;
  double _dragRotation = 0.0;
  SwipeDirection? _swipeDirection;

  // Gesture tracking
  bool _isDragging = false;

  // Image carousel tracking
  int _currentImageIndex = 0;

  // Thresholds
  static const double _swipeThreshold = 100.0;
  static const double _swipeUpThreshold = 120.0;
  static const double _velocityThreshold = 800.0;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(vsync: this);

    // Listen to drag progress changes for cards behind the top card
    if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
      widget.dragProgressNotifier!.addListener(_onDragProgressChanged);
    }
  }

  @override
  void didUpdateWidget(SwipeableProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle listener when stackIndex changes (e.g., card moves from index 2 to 1)
    if (oldWidget.stackIndex != widget.stackIndex) {
      // Remove old listener if needed
      if (oldWidget.stackIndex == 1 && oldWidget.dragProgressNotifier != null) {
        oldWidget.dragProgressNotifier!.removeListener(_onDragProgressChanged);
      }

      // Add new listener if needed
      if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
        widget.dragProgressNotifier!.addListener(_onDragProgressChanged);
      }
    }

    // Handle listener when dragProgressNotifier changes
    if (oldWidget.dragProgressNotifier != widget.dragProgressNotifier) {
      // Remove old listener
      if (oldWidget.stackIndex == 1 && oldWidget.dragProgressNotifier != null) {
        oldWidget.dragProgressNotifier!.removeListener(_onDragProgressChanged);
      }

      // Add new listener
      if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
        widget.dragProgressNotifier!.addListener(_onDragProgressChanged);
      }
    }

    // Reset image index when the displayed product changes
    if (oldWidget.product.id != widget.product.id) {
      _currentImageIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    // Remove listener before disposing
    if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
      widget.dragProgressNotifier!.removeListener(_onDragProgressChanged);
    }
    _pageController.dispose();
    _swipeController?.dispose();
    super.dispose();
  }

  void _onDragProgressChanged() {
    // Update the state to reflect the new scale
    if (mounted) {
      setState(() {});
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isTopCard) return;

    // Stop any ongoing animation
    _swipeController?.stop();

    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isTopCard || !_isDragging) return;

    setState(() {
      _dragOffset += details.delta;

      // Calculate rotation based on horizontal drag (max ±12°)
      _dragRotation = (_dragOffset.dx / 400) * 12;
      _dragRotation = _dragRotation.clamp(-12.0, 12.0);

      // Determine swipe direction based on dominant movement
      _updateSwipeDirection();

      // Notify cards behind about drag progress
      _updateDragProgress();
    });
  }

  void _updateDragProgress() {
    if (widget.dragProgressNotifier == null) return;

    // Calculate progress (0.0 to 1.0) based on distance dragged
    final distance = math.sqrt(
      _dragOffset.dx * _dragOffset.dx + _dragOffset.dy * _dragOffset.dy,
    );
    final progress = (distance / _swipeThreshold).clamp(0.0, 1.0);
    widget.dragProgressNotifier!.value = progress;
  }

  void _updateSwipeDirection() {
    final absX = _dragOffset.dx.abs();
    final absY = _dragOffset.dy.abs();

    if (absX > _swipeThreshold && absX > absY) {
      _swipeDirection = _dragOffset.dx > 0
          ? SwipeDirection.right
          : SwipeDirection.left;
    } else if (_dragOffset.dy < -_swipeUpThreshold && absY > absX) {
      _swipeDirection = SwipeDirection.up;
    } else {
      _swipeDirection = null;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isTopCard || !_isDragging) return;

    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond;
    final velocityMagnitude = velocity.distance;

    // Check if swipe was fast enough or far enough
    bool shouldSwipe = false;
    SwipeDirection? direction;

    // Velocity-based swipe detection (for quick flicks)
    if (velocityMagnitude > _velocityThreshold) {
      if (velocity.dx.abs() > velocity.dy.abs()) {
        // Horizontal swipe
        direction = velocity.dx > 0
            ? SwipeDirection.right
            : SwipeDirection.left;
        shouldSwipe = true;
      } else if (velocity.dy < -_velocityThreshold) {
        // Upward swipe
        direction = SwipeDirection.up;
        shouldSwipe = true;
      }
    }

    // Position-based swipe detection (for slow drags)
    if (!shouldSwipe && _swipeDirection != null) {
      direction = _swipeDirection;
      shouldSwipe = true;
    }

    if (shouldSwipe && direction != null) {
      // For swipe up, call callback first without animating away
      // This allows the callback to show dialog and cancel if needed
      if (direction == SwipeDirection.up) {
        // Don't animate - just reset position and call callback
        setState(() {
          _dragOffset = Offset.zero;
          _dragRotation = 0.0;
          _swipeDirection = null;
        });
        // Call the callback which will show dialog
        widget.onSwipeUp?.call();
      } else {
        _animateSwipeAway(direction, velocity);
      }
    } else {
      _animateBack();
    }
  }

  void _animateSwipeAway(
    SwipeDirection direction,
    Offset velocity, {
    bool useFixedDuration = false,
  }) {
    final screenSize = MediaQuery.of(context).size;

    Offset targetOffset;
    double targetRotation;

    switch (direction) {
      case SwipeDirection.left:
        targetOffset = Offset(-screenSize.width * 1.5, _dragOffset.dy);
        targetRotation = -15.0;
        break;
      case SwipeDirection.right:
        targetOffset = Offset(screenSize.width * 1.5, _dragOffset.dy);
        targetRotation = 15.0;
        break;
      case SwipeDirection.up:
        targetOffset = Offset(_dragOffset.dx * 0.5, -screenSize.height);
        targetRotation = _dragRotation;
        break;
    }

    // Use fixed duration for button animations, velocity-based for gesture swipes
    final Duration duration;
    if (useFixedDuration) {
      duration = const Duration(
        milliseconds: 500,
      ); // Slower fixed duration for buttons
    } else {
      // Calculate duration based on velocity (faster swipe = shorter animation)
      final distance = (targetOffset - _dragOffset).distance;
      final velocityMag = velocity.distance.clamp(500.0, 3000.0);
      duration = Duration(
        milliseconds: (distance / velocityMag * 1000).clamp(150, 400).toInt(),
      );
    }

    final controller = _swipeController;
    if (controller == null) return;

    // Reset controller to ensure clean state
    controller.reset();
    controller.duration = duration;

    // Create smooth animations
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    _rotationAnimation = Tween<double>(
      begin: _dragRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    // Store listener references for cleanup
    void progressListener() {
      if (widget.dragProgressNotifier != null && mounted) {
        final animProgress = controller.value;
        final currentProgress = widget.dragProgressNotifier!.value;
        widget.dragProgressNotifier!.value =
            currentProgress + (1.0 - currentProgress) * animProgress;
      }
    }

    void animationListener() {
      if (mounted) {
        _updateFromAnimation();
      }
    }

    // Add listeners
    if (widget.dragProgressNotifier != null) {
      controller.addListener(progressListener);
    }
    controller.addListener(animationListener);

    controller.forward(from: 0).then((_) {
      // Remove listeners to prevent leaks
      if (widget.dragProgressNotifier != null) {
        controller.removeListener(progressListener);
      }
      controller.removeListener(animationListener);

      // Trigger callback after animation completes (for left/right only)
      if (mounted) {
        switch (direction) {
          case SwipeDirection.left:
            widget.onSwipeLeft?.call();
            break;
          case SwipeDirection.right:
            widget.onSwipeRight?.call();
            break;
          case SwipeDirection.up:
            // Handled separately in _onDragEnd
            break;
        }
      }
    });
  }

  void _animateBack() {
    final controller = _swipeController;
    if (controller == null) return;

    // Reset controller to ensure clean state
    controller.reset();
    controller.duration = const Duration(milliseconds: 250);

    final startOffset = _dragOffset;
    final startRotation = _dragRotation;

    _offsetAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    _rotationAnimation = Tween<double>(
      begin: startRotation,
      end: 0.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    // Store listener reference for cleanup
    void animationListener() {
      if (mounted) {
        _updateFromAnimation();
      }
    }

    // Animate drag progress back to 0.0
    if (widget.dragProgressNotifier != null) {
      final startProgress = widget.dragProgressNotifier!.value;
      controller.addListener(() {
        if (mounted && widget.dragProgressNotifier != null) {
          widget.dragProgressNotifier!.value =
              startProgress * (1.0 - controller.value);
        }
      });
    }

    controller.addListener(animationListener);

    controller.forward(from: 0).then((_) {
      // Remove animation listener
      controller.removeListener(animationListener);
      _resetCard();
    });
  }

  void _updateFromAnimation() {
    if (mounted) {
      setState(() {
        _dragOffset = _offsetAnimation.value;
        _dragRotation = _rotationAnimation.value;
      });
    }
  }

  void _resetCard() {
    _swipeController?.removeListener(_updateFromAnimation);
    if (mounted) {
      setState(() {
        _dragOffset = Offset.zero;
        _dragRotation = 0.0;
        _swipeDirection = null;
      });
      // Don't reset drag progress here - it causes glitches
      // The parent widget will reset it after the card is removed
    }
  }

  /// Public method to programmatically trigger a swipe animation
  /// Used when action buttons are pressed
  void animateSwipe(SwipeDirection direction) {
    if (!widget.isTopCard) return;

    // Trigger the swipe animation with fixed duration for smoother button animations
    _animateSwipeAway(direction, Offset.zero, useFixedDuration: true);
  }

  double _getCardScale() {
    // Base scale for cards in the stack
    final baseScale = 1.0 - (widget.stackIndex * 0.05);

    // If this is the second card (index 1), animate scale based on top card's drag progress
    if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
      final dragProgress = widget.dragProgressNotifier!.value;
      // Interpolate from baseScale (0.95) to 1.0 as drag progresses
      return baseScale + (0.05 * dragProgress);
    }

    return baseScale;
  }

  Offset _getStackOffset() {
    final baseOffset = widget.stackIndex * 10.0;

    // If this is the second card (index 1), animate Y offset based on top card's drag progress
    if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
      final dragProgress = widget.dragProgressNotifier!.value;
      // Interpolate from baseOffset (10px down) to 0 as drag progresses
      final animatedY = baseOffset * (1.0 - dragProgress);
      return Offset(0, animatedY);
    }

    return Offset(0, baseOffset);
  }

  List<BoxShadow> _getCardShadow() {
    // Top card: dual-layer shadow for floating glass depth
    if (widget.stackIndex == 0) {
      return const [_kShadowAmbient, _kShadowTop];
    }

    // For the second card during drag, interpolate (unavoidable allocation)
    if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
      final dragProgress = widget.dragProgressNotifier!.value;
      if (dragProgress > 0.01) {
        // Only allocate new shadow when actively dragging
        const behindCardBlur = 12.0;
        const topCardBlur = 20.0;
        const behindCardOpacity = 0.08;
        const topCardOpacity = 0.12;
        final blurRadius =
            behindCardBlur + (topCardBlur - behindCardBlur) * dragProgress;
        final opacity =
            behindCardOpacity +
            (topCardOpacity - behindCardOpacity) * dragProgress;

        return [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, opacity),
            blurRadius: blurRadius,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ];
      }
    }

    return const [_kShadowBehind];
  }

  // Calculate overlay opacity based on drag distance
  double _getOverlayOpacity() {
    if (_swipeDirection == null) return 0.0;

    double progress;
    switch (_swipeDirection!) {
      case SwipeDirection.left:
      case SwipeDirection.right:
        progress = _dragOffset.dx.abs() / _swipeThreshold;
        break;
      case SwipeDirection.up:
        progress = _dragOffset.dy.abs() / _swipeUpThreshold;
        break;
    }

    return (progress - 1.0).clamp(0.0, 1.0) * 0.85;
  }

  @override
  Widget build(BuildContext context) {
    final cardScale = _getCardScale();
    final stackOffset = _getStackOffset();
    final cardWidth = ResponsiveUtils.getCardWidth(context);
    final cardHeight = ResponsiveUtils.getCardHeight(context);

    // Calculate total offset
    final totalOffset = widget.isTopCard
        ? _dragOffset + stackOffset
        : stackOffset;
    final rotation = widget.isTopCard ? _dragRotation * (math.pi / 180) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure we have valid constraints before rendering
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          child: Transform(
            transform: Matrix4.identity()
              ..translate(totalOffset.dx, totalOffset.dy)
              ..rotateZ(rotation)
              ..scale(cardScale),
            alignment: Alignment.center,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTap: widget.isTopCard ? widget.onTap : null,
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                // Swipe overlay is inside _buildCardContent (clipped to card corners)
                child: _buildCardContent(cardWidth, cardHeight),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(double cardWidth, double cardHeight) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: _getCardShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // ── Column: image fills top, info panel sits below ──
            Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Full-bleed product image
                      _buildImageSection(),

                      // Page indicators near bottom of image area
                      if (widget.product.images.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _pageController,
                              count: widget.product.images.length,
                              effect: const WormEffect(
                                dotWidth: 7,
                                dotHeight: 7,
                                activeDotColor: Colors.white,
                                dotColor: Color(0x88FFFFFF),
                                spacing: 5,
                              ),
                            ),
                          ),
                        ),

                      // Glass navigation arrows
                      if (widget.product.images.length > 1 &&
                          widget.isTopCard) ...[
                        if (_currentImageIndex > 0)
                          Positioned(
                            left: 10,
                            top: 0,
                            bottom: 0,
                            child: Center(child: _buildNavArrow(isLeft: true)),
                          ),
                        if (_currentImageIndex <
                            widget.product.images.length - 1)
                          Positioned(
                            right: 10,
                            top: 0,
                            bottom: 0,
                            child: Center(child: _buildNavArrow(isLeft: false)),
                          ),
                      ],
                    ],
                  ),
                ),

                // ── Info panel below image — not overlaid ──
                _buildInfoSection(),
              ],
            ),

            // ── Inner highlight rim for glass depth (all 4 corners) ──
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0x33FFFFFF),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),

            // ── Swipe direction overlay (full card) ──
            if (widget.isTopCard && _swipeDirection != null)
              Positioned.fill(child: _buildSwipeOverlay()),
          ],
        ),
      ),
    );
  }

  /// Glass nav arrow button
  Widget _buildNavArrow({required bool isLeft}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isLeft) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
          );
        }
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0x33FFFFFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLeft ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid background to prevent ghosting
        Container(
          color: isDark ? AppColors.darkMainBackground : AppColors.gray100,
        ),
        // Image PageView
        PageView.builder(
          key: ValueKey('pageview_${widget.product.id}'),
          controller: _pageController,
          physics: widget.isTopCard && !_isDragging
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: widget.product.images.length,
          onPageChanged: (index) {
            if (mounted) setState(() => _currentImageIndex = index);
          },
          itemBuilder: (context, index) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final cacheWidth = (constraints.maxWidth * 2).toInt();
                return CachedNetworkImage(
                  key: ValueKey('img_${widget.product.id}_$index'),
                  imageUrl: widget.product.images[index],
                  fit: BoxFit.cover,
                  cacheManager: ImageCacheManager.instance,
                  memCacheWidth: cacheWidth,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) => Container(
                    color: isDark
                        ? AppColors.darkMainBackground
                        : AppColors.gray100,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark
                        ? AppColors.darkCardBackground
                        : AppColors.gray200,
                    child: Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray500,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTabletOrDesktop = MediaQuery.of(context).size.width >= 600;

    final verticalPadding = screenHeight < 700
        ? 12.0
        : isTabletOrDesktop
        ? 20.0
        : 14.0;
    final horizontalPadding = screenHeight < 700
        ? 16.0
        : isTabletOrDesktop
        ? 24.0
        : 20.0;

    final titleFontSize = isTabletOrDesktop ? 18.0 : null;
    final sellerFontSize = isTabletOrDesktop ? 14.0 : 12.0;
    final priceFontSize = screenHeight < 700
        ? 16.0
        : isTabletOrDesktop
        ? 22.0
        : 18.0;
    final discountBadgeFontSize = isTabletOrDesktop ? 12.0 : 10.0;

    final titleColor = isDark ? Colors.white : Colors.black;
    final sellerColor = isDark
        ? const Color(0xAAFFFFFF)
        : const Color(0x88000000);
    final priceColor = isDark ? Colors.white : Colors.black;
    final strikeColor = isDark
        ? const Color(0x66FFFFFF)
        : const Color(0x66000000);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xE8111111) : const Color(0xEEFFFFFF),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0x22FFFFFF)
                    : const Color(0x22000000),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                widget.product.localizedTitle(
                  Localizations.localeOf(context).languageCode,
                ),
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: titleFontSize,
                  color: titleColor,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenHeight < 700 ? 2 : 3),
              // Seller Name
              Text(
                widget.product.seller ?? 'SVAYP',
                style: AppTypography.caption.copyWith(
                  color: sellerColor,
                  fontSize: sellerFontSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenHeight < 700 ? 6 : 8),
              // Price Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                widget.product.formattedPrice,
                                style: AppTypography.heading3.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: priceFontSize,
                                  color: priceColor,
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.product.hasDiscount &&
                                widget.product.discountPercentage != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xAAFF3B30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${widget.product.discountPercentage}%',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: discountBadgeFontSize,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (widget.product.hasDiscount)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.product.formattedDiscountPrice ?? '',
                              style: AppTypography.caption.copyWith(
                                color: strikeColor,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Liquid Glass swipe overlay — colored tint with icon + label
  Widget _buildSwipeOverlay() {
    final overlayOpacity = _getOverlayOpacity();

    Color tintColor;
    IconData overlayIcon;

    switch (_swipeDirection!) {
      case SwipeDirection.left:
        tintColor = const Color(0xAAFF3B30); // iOS red, 67% opacity
        overlayIcon = Icons.thumb_down_rounded;
        break;
      case SwipeDirection.right:
        tintColor = const Color(0xAA30D158); // iOS green, 67% opacity
        overlayIcon = Icons.favorite_rounded;
        break;
      case SwipeDirection.up:
        tintColor = const Color(0xAA0A84FF); // iOS blue, 67% opacity
        overlayIcon = Icons.shopping_bag_rounded;
        break;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: overlayOpacity,
      child: Container(
        decoration: BoxDecoration(
          color: tintColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(child: Icon(overlayIcon, size: 72, color: Colors.white)),
      ),
    );
  }
}
