import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';

/// Splash Screen - Initial screen when app launches
/// Clean, minimalist Sephora-style splash with text animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _taglineFadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNext();

    // Set status bar to dark content for white background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _setupAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo name fade in and scale
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Tagline fade in (delayed)
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Check authentication and onboarding status
    final storage = await LocalStorageHelper.getInstance();
    final apiClient = getIt<ApiClient>();

    final isAuthenticated = apiClient.isAuthenticated();
    final isOnboarded = await storage.isOnboarded();

    if (!mounted) return;

    // Priority 1: If user is authenticated, go to correct home screen
    if (isAuthenticated) {
      final destination =
          apiClient.isPartnerLogin() ? '/partner-main' : '/main';
      Navigator.of(context).pushReplacementNamed(destination);
    }
    // Priority 2: If user completed onboarding but not authenticated (shouldn't happen)
    // Still send to main, they might have cleared auth but kept onboarding flag
    else if (isOnboarded) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
    // Priority 3: New user - go directly to phone authentication
    else {
      Navigator.of(context).pushReplacementNamed('/phone-auth');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Name - SVΛYP
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Text(
                      'SVΛYP',
                      style: AppTypography.display1.copyWith(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 12,
                        color: AppColors.black,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
