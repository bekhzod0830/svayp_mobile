import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/services/recommendation_cache_service.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

/// Onboarding Completion Screen - Celebration screen after style quiz
/// Shows success message with Sephora-style animation and transitions to main app
class OnboardingCompletionScreen extends StatefulWidget {
  const OnboardingCompletionScreen({super.key});

  @override
  State<OnboardingCompletionScreen> createState() =>
      _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends State<OnboardingCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late ConfettiController _confettiController;

  bool _isLoading = true; // Start with loading state
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Start loading after the first frame when context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startLoadingProcess();
      }
    });
  }

  void _setupAnimations() {
    // Scale animation for the success icon (Sephora-style pop-in)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Fade animation for text content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Continuous pulse animation for the icon (subtle)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Smooth progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  /// Update progress with smooth animation
  void _updateProgress(double progress, String message) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    _progressAnimation =
        Tween<double>(begin: _loadingProgress, end: clampedProgress).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );

    _progressController.forward(from: 0.0);

    setState(() {
      _loadingProgress = clampedProgress;
    });
  }

  /// Auto-start loading process when screen loads
  Future<void> _startLoadingProcess() async {
    print('🚀 Starting loading process...');

    try {
      if (!mounted) {
        print('⚠️ Widget not mounted, aborting loading');
        return;
      }

      final l10n = AppLocalizations.of(context);
      if (l10n == null) {
        print('⚠️ Localization not available, using fallback');
        _showSuccessImmediately();
        return;
      }

      print('📊 Step 1: Initialize (10%)');
      // Step 1: Initialize (10%)
      _updateProgress(0.1, l10n.preparingYourFeed);
      await Future.delayed(const Duration(milliseconds: 300));

      print('📊 Step 2: Fetching recommendations (30%)');
      // Step 2: Fetch recommendations (50%)
      _updateProgress(0.3, l10n.preparingYourFeed);

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken != null && authToken.isNotEmpty) {
        try {
          print('🎯 Fetching recommendations for first-time user...');
          final apiService = ProductApiService();

          final response = await apiService.getRecommendedProducts(
            limit: 50,
            minScore: 25.0,
            token: authToken,
          );

          print('✅ Received ${response.products.length} recommendations');
          _updateProgress(0.6, l10n.preparingYourFeed);

          // Step 3: Cache recommendations (70%)
          await RecommendationCacheService.cacheRecommendations(
            response.products,
          );
          _updateProgress(0.7, l10n.preparingYourFeed);

          // Step 4: Preload images (90%)
          if (mounted) {
            await _preloadImagesWithProgress(response.products);
          }

          print('✅ Cached and preloaded recommendations');
        } catch (e) {
          print('⚠️ Failed to fetch recommendations: $e');
          // Continue anyway
        }
      }

      // Step 5: Complete (100%)
      _updateProgress(1.0, l10n.preparingYourFeed);
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // BOOM! Confetti celebration
      _confettiController.play();
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Show success animation
      setState(() {
        _isLoading = false;
      });

      // Start success animation sequence
      _startSuccessAnimationSequence();
    } catch (e, stackTrace) {
      print('⚠️ Error in loading process: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      // Show success animation even if loading fails
      _showSuccessImmediately();
    }
  }

  /// Show success screen immediately (fallback for errors)
  void _showSuccessImmediately() {
    print('🎯 Showing success immediately');

    if (!mounted) return;

    setState(() {
      _loadingProgress = 1.0;
      _isLoading = false;
    });

    _confettiController.play();
    _startSuccessAnimationSequence();
  }

  void _startSuccessAnimationSequence() async {
    print('✨ Starting success animation sequence');
    // Sephora-style entrance: icon pops in, then text fades in
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _fadeController.forward();

    // Start subtle pulse after entrance completes
    await Future.delayed(const Duration(milliseconds: 800));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _navigateToMain() async {
    try {
      final manager = context.read<OnboardingDataManager>();

      // Clear the manager data
      manager.reset();

      // Save onboarding completion status locally
      final storage = await LocalStorageHelper.getInstance();
      await storage.setOnboarded(true);

      if (!mounted) return;

      // Navigate to main app (discover screen)
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(
        context,
        '${l10n.completionError}: ${e.toString()}',
      );
    }
  }

  /// Preload only 5 product images with progress tracking
  Future<void> _preloadImagesWithProgress(List<dynamic> products) async {
    try {
      print('🖼️ Preloading product images...');

      // Preload only first 5 images
      final imagesToPreload = products.take(5).toList();
      final totalImages = imagesToPreload.length;
      int preloadedCount = 0;

      for (int i = 0; i < imagesToPreload.length; i++) {
        final product = imagesToPreload[i];
        if (product.images != null && product.images!.isNotEmpty) {
          // Preload only the first image of each product
          try {
            await ImageCacheManager.instance.downloadFile(
              product.images!.first,
            );
            preloadedCount++;

            // Update progress: 70% -> 95% (25% range for image preloading)
            final imageProgress = 0.7 + (0.25 * (preloadedCount / totalImages));
            if (mounted) {
              _updateProgress(
                imageProgress,
                AppLocalizations.of(context)!.preparingYourFeed,
              );
            }
          } catch (e) {
            print('⚠️ Failed to preload image: ${product.images!.first}');
          }
        }
      }

      print('✅ Preloaded $preloadedCount images');
    } catch (e) {
      print('⚠️ Error preloading images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Show loading progress OR success animation
                  if (_isLoading) ...[
                    // Circular Loading Animation
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Circular Progress Indicator with smooth animation
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: _progressAnimation.value,
                                  strokeWidth: 6,
                                  backgroundColor: AppColors.gray200,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.black,
                                      ),
                                  strokeCap: StrokeCap.round,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                            ),
                            child: Text(
                              l10n.preparingYourFeed,
                              style: AppTypography.body1.copyWith(
                                color: AppColors.secondaryText,
                                height: 1.6,
                                fontSize: 17,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Success Icon with Sephora-style animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.black,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 80,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Headline with fade animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        l10n.youreAllSet,
                        style: AppTypography.display2.copyWith(
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle with fade animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        l10n.startDiscoveringFashion,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.6,
                          fontSize: 17,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const Spacer(flex: 3),

                  // CTA Button - only show when loading is complete
                  if (!_isLoading)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _navigateToMain,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.black,
                            foregroundColor: AppColors.white,
                            elevation: 4,
                            shadowColor: AppColors.shadow12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            l10n.startExploring,
                            style: AppTypography.button.copyWith(
                              color: AppColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Confetti overlay - SEPHORA-style birthday celebration
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Down
              maxBlastForce: 5, // Low power for gentle fall
              minBlastForce: 2,
              emissionFrequency: 0.05, // High frequency for dense confetti
              numberOfParticles: 50, // Many particles per emission
              gravity: 0.3, // Slow fall like in Sephora
              shouldLoop: false, // One-time celebration
              colors: const [
                Color(0xFFFF6B9D), // Pink
                Color(0xFFFFC107), // Gold
                Color(0xFF00BCD4), // Cyan
                Color(0xFFE91E63), // Deep pink
                Color(0xFF9C27B0), // Purple
                Color(0xFF00E676), // Green
              ],
            ),
          ),
        ],
      ),
    );
  }
}
