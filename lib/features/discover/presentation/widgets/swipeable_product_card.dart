import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';

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

  double _getCardOpacity() {
    // All cards fully opaque - no transparency to prevent ghost effect
    return 1.0;
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
    // Base shadow values
    const topCardBlur = 20.0;
    const topCardOpacity = 0.12;
    const behindCardBlur = 12.0;
    const behindCardOpacity = 0.08;

    // If this is the second card, interpolate shadow based on drag progress
    if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
      final dragProgress = widget.dragProgressNotifier!.value;
      // Interpolate blur and opacity
      final blurRadius =
          behindCardBlur + (topCardBlur - behindCardBlur) * dragProgress;
      final opacity =
          behindCardOpacity +
          (topCardOpacity - behindCardOpacity) * dragProgress;

      return [
        BoxShadow(
          color: AppColors.black.withOpacity(opacity),
          blurRadius: blurRadius,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];
    }

    // Top card gets full shadow
    if (widget.stackIndex == 0) {
      return [
        BoxShadow(
          color: AppColors.black.withOpacity(topCardOpacity),
          blurRadius: topCardBlur,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];
    }

    // Cards further back get lighter shadow
    return [
      BoxShadow(
        color: AppColors.black.withOpacity(behindCardOpacity),
        blurRadius: behindCardBlur,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ];
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

    return (progress - 1.0).clamp(0.0, 1.0) * 0.7;
  }

  @override
  Widget build(BuildContext context) {
    final cardScale = _getCardScale();
    final cardOpacity = _getCardOpacity();
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
            child: Opacity(
              opacity: cardOpacity,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTap: widget.isTopCard ? widget.onTap : null,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Stack(
                    children: [
                      // Main Card Content
                      _buildCardContent(cardWidth, cardHeight),

                      // Swipe Direction Overlay
                      if (widget.isTopCard && _swipeDirection != null)
                        _buildSwipeOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(double cardWidth, double cardHeight) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate info section height based on screen size
    // Smaller screens get less space for image to ensure info doesn't overflow
    final infoHeight = screenHeight < 700 ? 130.0 : 140.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _getCardShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images Section - takes remaining space
            Expanded(child: _buildImageSection()),
            // Product Info Section - fixed height to prevent overflow
            SizedBox(height: infoHeight, child: _buildInfoSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkCardBackground : AppColors.white,
      child: Stack(
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
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                key: ValueKey('img_${widget.product.id}_$index'),
                imageUrl: widget.product.images[index],
                fit: BoxFit.contain,
                cacheManager: ImageCacheManager.instance,
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
          ),

          // Gradient Overlay (bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.black.withOpacity(0.25),
                  ],
                ),
              ),
            ),
          ),

          // Page Indicators
          if (widget.product.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: widget.product.images.length,
                  effect: const WormEffect(
                    dotWidth: 8,
                    dotHeight: 8,
                    activeDotColor: AppColors.white,
                    dotColor: AppColors.gray400,
                    spacing: 6,
                  ),
                ),
              ),
            ),

          // NEW Badge
          if (widget.product.isNew)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'NEW',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    // Reduce padding on smaller screens
    final verticalPadding = screenHeight < 700 ? 12.0 : 16.0;
    final horizontalPadding = screenHeight < 700 ? 16.0 : 20.0;

    return Container(
      color: isDark ? AppColors.darkCardBackground : AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Flexible(
            child: Text(
              widget.product.title,
              style: AppTypography.body1.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.black,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: screenHeight < 700 ? 2 : 4),
          // Seller Name
          Text(
            widget.product.seller ?? 'SVAYP',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.gray400 : AppColors.gray600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: screenHeight < 700 ? 6 : 8),
          // Price & Rating Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price Column with Discount Badge
              Flexible(
                // flex: widget.product.reviewCount > 0 ? 3 : 1,
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Final price and discount badge row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.product.formattedPrice,
                            style: AppTypography.heading3.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: screenHeight < 700 ? 16 : 18,
                              color: isDark ? AppColors.white : AppColors.black,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Discount badge next to final price
                        if (widget.product.hasDiscount &&
                            widget.product.discountPercentage != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${widget.product.discountPercentage}%',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Original price below (strikethrough)
                    if (widget.product.hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          widget.product.formattedDiscountPrice ?? '',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.gray400
                                : AppColors.gray500,
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
              // COMMENTED OUT - Rating display (for future use)
              // if (widget.product.reviewCount > 0) ...[
              //   const SizedBox(width: 8),
              //   Flexible(
              //     flex: 2,
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       crossAxisAlignment: CrossAxisAlignment.center,
              //       children: [
              //         const Icon(Icons.star, size: 15, color: Colors.amber),
              //         const SizedBox(width: 3),
              //         Flexible(
              //           child: Text(
              //             widget.product.formattedRating,
              //             style: AppTypography.body2.copyWith(
              //               fontWeight: FontWeight.w600,
              //               fontSize: 13,
              //               color: isDark ? AppColors.white : AppColors.black,
              //             ),
              //             maxLines: 1,
              //             overflow: TextOverflow.ellipsis,
              //           ),
              //         ),
              //         const SizedBox(width: 2),
              //         Flexible(
              //           child: Text(
              //             '(${widget.product.reviewCount})',
              //             style: AppTypography.caption.copyWith(
              //               fontSize: 11,
              //               color: isDark
              //                   ? AppColors.gray400
              //                   : AppColors.gray600,
              //             ),
              //             maxLines: 1,
              //             overflow: TextOverflow.ellipsis,
              //           ),
              //         ),
              //       ],
              // //     ),
              //   ),
              // ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeOverlay() {
    final overlayOpacity = _getOverlayOpacity();

    Color overlayColor;
    IconData overlayIcon;

    switch (_swipeDirection!) {
      case SwipeDirection.left:
        overlayColor = Colors.red;
        overlayIcon = Icons.close;
        break;
      case SwipeDirection.right:
        overlayColor = Colors.green;
        overlayIcon = Icons.favorite;
        break;
      case SwipeDirection.up:
        overlayColor = AppColors.black;
        overlayIcon = Icons.shopping_bag;
        break;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: overlayOpacity,
      child: Container(
        decoration: BoxDecoration(
          color: overlayColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Icon(overlayIcon, size: 80, color: AppColors.white),
        ),
      ),
    );
  }
}
