import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Style Quiz Screen - Interactive fashion quiz using swipe mechanics
/// User swipes on fashion items to learn their style preferences
class StyleQuizScreen extends StatefulWidget {
  const StyleQuizScreen({super.key});

  @override
  State<StyleQuizScreen> createState() => _StyleQuizScreenState();
}

class _StyleQuizScreenState extends State<StyleQuizScreen> {
  final Map<int, bool> _answers = {}; // true = like, false = dislike
  bool _isCompleting = false;
  List<StyleQuizItem> _quizItems = [];
  String _gender = 'female';
  String _hijabPreference = 'uncovered';
  int _currentCardIndex = 0;
  final ValueNotifier<double> _dragProgressNotifier = ValueNotifier<double>(
    0.0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_quizItems.isEmpty) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _gender = args['gender'] as String? ?? 'female';
        _hijabPreference = args['hijabPreference'] as String? ?? 'uncovered';
      }

      _loadQuizImages();
    }
  }

  void _loadQuizImages() async {
    String folderPath;

    if (_gender == 'male') {
      folderPath = 'lib/img/style_quiz/male/';
    } else {
      if (_hijabPreference == 'covered') {
        folderPath = 'lib/img/style_quiz/female/covered/';
      } else {
        folderPath = 'lib/img/style_quiz/female/uncovered/';
      }
    }

    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final imagePaths = manifestMap.keys
        .where((String key) => key.startsWith(folderPath))
        .where(
          (String key) =>
              key.endsWith('.jpg') ||
              key.endsWith('.jpeg') ||
              key.endsWith('.png') ||
              key.endsWith('.webp'),
        )
        .toList();

    imagePaths.sort();

    final l10n = AppLocalizations.of(context)!;
    final categories = _getStyleCategories(l10n);

    setState(() {
      _quizItems = List.generate(
        imagePaths.length,
        (index) => StyleQuizItem(
          id: index + 1,
          imagePath: imagePaths[index],
          category: categories[index % categories.length],
          description: l10n.discoverYourStylePreference,
        ),
      );
    });
  }

  List<String> _getStyleCategories(AppLocalizations l10n) {
    return [
      l10n.casualWear,
      l10n.businessFormal,
      l10n.streetwear,
      l10n.athleticWear,
      l10n.vintageFashion,
      l10n.minimalist,
      l10n.boldPatterns,
      l10n.bohemian,
      l10n.elegantEvening,
      l10n.smartCasual,
      l10n.modernChic,
      l10n.classicStyle,
      l10n.trendy,
      l10n.sporty,
      l10n.sophisticated,
      l10n.comfortable,
      l10n.dressy,
      l10n.everyday,
      l10n.weekend,
      l10n.office,
      l10n.evening,
      l10n.casualChic,
      l10n.urban,
      l10n.contemporary,
      l10n.timeless,
      l10n.fashionForward,
      l10n.relaxed,
      l10n.polished,
      l10n.effortless,
      l10n.statement,
    ];
  }

  void _onSwipeLeft() {
    if (_currentCardIndex >= _quizItems.length) return;

    HapticFeedback.lightImpact();

    final item = _quizItems[_currentCardIndex];
    _answers[item.id] = false;

    final manager = context.read<OnboardingDataManager>();
    manager.addQuizResult(productId: item.id.toString(), action: 'dislike');

    setState(() {
      _currentCardIndex++;
      // Reset drag progress for next card
      _dragProgressNotifier.value = 0.0;
    });

    if (_currentCardIndex >= _quizItems.length) {
      _completeQuiz();
    }
  }

  void _onSwipeRight() {
    if (_currentCardIndex >= _quizItems.length) return;

    HapticFeedback.mediumImpact();

    final item = _quizItems[_currentCardIndex];
    _answers[item.id] = true;

    final manager = context.read<OnboardingDataManager>();
    manager.addQuizResult(productId: item.id.toString(), action: 'like');

    setState(() {
      _currentCardIndex++;
      // Reset drag progress for next card
      _dragProgressNotifier.value = 0.0;
    });

    if (_currentCardIndex >= _quizItems.length) {
      _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.of(context).pushNamed('/style-categories');
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(context, l10n.completionError);
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _dragProgressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: OnboardingProgressBar(currentStep: 7, totalSteps: 10),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.styleQuiz,
                          style: AppTypography.heading2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentCardIndex + 1} of ${_quizItems.length}',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _quizItems.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.black),
                    )
                  : _currentCardIndex >= _quizItems.length
                  ? _buildCompletionState(l10n)
                  : _buildCardStack(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    return Column(
      children: [
        // Card Stack Area
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Show 3 cards in stack
                for (int i = 2; i >= 0; i--)
                  if (_currentCardIndex + i < _quizItems.length)
                    _SwipeableQuizCard(
                      key: ValueKey(
                        'card_${_quizItems[_currentCardIndex + i].id}',
                      ),
                      item: _quizItems[_currentCardIndex + i],
                      isTopCard: i == 0,
                      stackIndex: i,
                      onSwipeLeft: i == 0 ? _onSwipeLeft : null,
                      onSwipeRight: i == 0 ? _onSwipeRight : null,
                      dragProgressNotifier: (i == 0 || i == 1)
                          ? _dragProgressNotifier
                          : null,
                    ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action Buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dislike Button
          Expanded(
            child: _ActionButton(
              icon: Icons.thumb_down_outlined,
              color: AppColors.gray700,
              backgroundColor: AppColors.white,
              borderColor: AppColors.gray300,
              size: 56,
              onPressed: _onSwipeLeft,
            ),
          ),

          const SizedBox(width: 16),

          // Like Button
          Expanded(
            child: _ActionButton(
              icon: Icons.favorite,
              color: AppColors.white,
              backgroundColor: AppColors.black,
              borderColor: Colors.transparent,
              size: 56,
              onPressed: _onSwipeRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.black),
          const SizedBox(height: 24),
          Text(
            l10n.analyzingYourStyle,
            style: AppTypography.heading4.copyWith(color: AppColors.black),
          ),
        ],
      ),
    );
  }
}

/// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final double size;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.size,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Center(
            child: Icon(icon, color: color, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}

/// Style Quiz Item Model
class StyleQuizItem {
  final int id;
  final String imagePath;
  final String category;
  final String description;

  StyleQuizItem({
    required this.id,
    required this.imagePath,
    required this.category,
    required this.description,
  });
}

/// Swipeable Quiz Card Widget
class _SwipeableQuizCard extends StatefulWidget {
  final StyleQuizItem item;
  final bool isTopCard;
  final int stackIndex;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final ValueNotifier<double>? dragProgressNotifier;

  const _SwipeableQuizCard({
    super.key,
    required this.item,
    this.isTopCard = true,
    this.stackIndex = 0,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.dragProgressNotifier,
  });

  @override
  State<_SwipeableQuizCard> createState() => _SwipeableQuizCardState();
}

class _SwipeableQuizCardState extends State<_SwipeableQuizCard>
    with TickerProviderStateMixin {
  AnimationController? _swipeController;
  Animation<Offset> _offsetAnimation = const AlwaysStoppedAnimation(
    Offset.zero,
  );
  Animation<double> _rotationAnimation = const AlwaysStoppedAnimation(0.0);

  Offset _dragOffset = Offset.zero;
  double _dragRotation = 0.0;
  bool _isDragging = false;

  static const double _swipeThreshold = 100.0;
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
  void didUpdateWidget(_SwipeableQuizCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle listener when stackIndex changes
    if (oldWidget.stackIndex != widget.stackIndex) {
      if (oldWidget.stackIndex == 1 && oldWidget.dragProgressNotifier != null) {
        oldWidget.dragProgressNotifier!.removeListener(_onDragProgressChanged);
      }

      if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
        widget.dragProgressNotifier!.addListener(_onDragProgressChanged);
      }
    }

    // Handle listener when dragProgressNotifier changes
    if (oldWidget.dragProgressNotifier != widget.dragProgressNotifier) {
      if (oldWidget.stackIndex == 1 && oldWidget.dragProgressNotifier != null) {
        oldWidget.dragProgressNotifier!.removeListener(_onDragProgressChanged);
      }

      if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
        widget.dragProgressNotifier!.addListener(_onDragProgressChanged);
      }
    }
  }

  @override
  void dispose() {
    if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
      widget.dragProgressNotifier!.removeListener(_onDragProgressChanged);
    }
    _swipeController?.dispose();
    super.dispose();
  }

  void _onDragProgressChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isTopCard) return;
    _swipeController?.stop();
    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isTopCard || !_isDragging) return;

    setState(() {
      _dragOffset += details.delta;
      _dragRotation = (_dragOffset.dx / 400) * 12;
      _dragRotation = _dragRotation.clamp(-12.0, 12.0);

      // Update drag progress for cards behind
      if (widget.dragProgressNotifier != null) {
        final distance =
            (_dragOffset.dx * _dragOffset.dx + _dragOffset.dy * _dragOffset.dy)
                .abs();
        final progress = (distance / (_swipeThreshold * _swipeThreshold)).clamp(
          0.0,
          1.0,
        );
        widget.dragProgressNotifier!.value = progress;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isTopCard || !_isDragging) return;

    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond;
    final velocityMagnitude = velocity.distance;

    bool shouldSwipe = false;
    bool? swipeRight;

    if (velocityMagnitude > _velocityThreshold) {
      if (velocity.dx.abs() > velocity.dy.abs()) {
        swipeRight = velocity.dx > 0;
        shouldSwipe = true;
      }
    }

    if (!shouldSwipe && _dragOffset.dx.abs() > _swipeThreshold) {
      swipeRight = _dragOffset.dx > 0;
      shouldSwipe = true;
    }

    if (shouldSwipe && swipeRight != null) {
      _animateSwipeAway(swipeRight, velocity);
    } else {
      _animateBack();
    }
  }

  void _animateSwipeAway(bool right, Offset velocity) {
    final screenSize = MediaQuery.of(context).size;

    final targetOffset = right
        ? Offset(screenSize.width * 1.5, _dragOffset.dy)
        : Offset(-screenSize.width * 1.5, _dragOffset.dy);
    final targetRotation = right ? 15.0 : -15.0;

    final distance = (targetOffset - _dragOffset).distance;
    final velocityMag = velocity.distance.clamp(500.0, 3000.0);

    // Calculate duration safely, avoiding division issues
    double durationMs = (distance / velocityMag * 1000).clamp(150.0, 400.0);
    if (!durationMs.isFinite) {
      durationMs = 300.0; // Default fallback
    }

    final duration = Duration(milliseconds: durationMs.toInt());

    final controller = _swipeController;
    if (controller == null) return;

    controller.duration = duration;

    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    _rotationAnimation = Tween<double>(
      begin: _dragRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    controller.forward(from: 0).then((_) {
      if (right) {
        widget.onSwipeRight?.call();
      } else {
        widget.onSwipeLeft?.call();
      }
      _resetCard();
    });

    controller.addListener(_updateFromAnimation);
  }

  void _animateBack() {
    final controller = _swipeController;
    if (controller == null) return;

    controller.duration = const Duration(milliseconds: 250);

    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    _rotationAnimation = Tween<double>(
      begin: _dragRotation,
      end: 0.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    controller.forward(from: 0).then((_) {
      _resetCard();
    });

    controller.addListener(_updateFromAnimation);
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
      });
    }
  }

  double _getCardScale() {
    final baseScale = 1.0 - (widget.stackIndex * 0.05);

    // If this is the second card, animate scale based on drag progress
    if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
      final dragProgress = widget.dragProgressNotifier!.value;
      return baseScale + (0.05 * dragProgress);
    }

    return baseScale;
  }

  Offset _getStackOffset() {
    final baseOffset = widget.stackIndex * 10.0;

    // If this is the second card, animate Y offset based on drag progress
    if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
      final dragProgress = widget.dragProgressNotifier!.value;
      final animatedY = baseOffset * (1.0 - dragProgress);
      return Offset(0, animatedY);
    }

    return Offset(0, baseOffset);
  }

  List<BoxShadow> _getCardShadow() {
    const topCardBlur = 20.0;
    const topCardOpacity = 0.12;
    const behindCardBlur = 12.0;
    const behindCardOpacity = 0.08;

    // If this is the second card, interpolate shadow based on drag progress
    if (widget.stackIndex == 1 && widget.dragProgressNotifier != null) {
      final dragProgress = widget.dragProgressNotifier!.value;
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

  double _getOverlayOpacity() {
    if (_dragOffset.dx.abs() < _swipeThreshold) return 0.0;
    final progress = _dragOffset.dx.abs() / _swipeThreshold;
    return (progress - 1.0).clamp(0.0, 1.0) * 0.7;
  }

  @override
  Widget build(BuildContext context) {
    final cardScale = _getCardScale();
    final stackOffset = _getStackOffset();
    final totalOffset = widget.isTopCard
        ? _dragOffset + stackOffset
        : stackOffset;
    final rotation = widget.isTopCard ? _dragRotation * (3.14159 / 180) : 0.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85;
    final cardHeight = MediaQuery.of(context).size.height * 0.65;

    return RepaintBoundary(
      child: Transform(
        transform: Matrix4.identity()
          ..translate(totalOffset.dx, totalOffset.dy)
          ..rotateZ(rotation)
          ..scale(cardScale),
        alignment: Alignment.center,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Stack(
              children: [
                _buildCardContent(cardWidth, cardHeight),
                if (widget.isTopCard && _dragOffset.dx.abs() > 50)
                  _buildSwipeOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(double cardWidth, double cardHeight) {
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
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.gray200,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: AppColors.gray500,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Text(
                      widget.item.category,
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeOverlay() {
    final overlayOpacity = _getOverlayOpacity();
    final isRight = _dragOffset.dx > 0;

    final overlayColor = isRight ? Colors.green : Colors.red;
    final overlayIcon = isRight ? Icons.favorite : Icons.close;

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
