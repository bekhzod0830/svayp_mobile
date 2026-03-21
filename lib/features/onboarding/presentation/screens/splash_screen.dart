import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/features/profile/data/services/profile_service.dart';

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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNext();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Quick fade-in so the text is visible while it's still small
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // Scale from tiny to full size with a springy overshoot
    _scaleAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _mainController.forward();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final storage = await LocalStorageHelper.getInstance();
    final apiClient = getIt<ApiClient>();

    // Guest mode — no auth needed
    if (storage.isGuestMode()) {
      Navigator.of(context).pushReplacementNamed('/main');
      return;
    }

    // No local token or it's expired — go to login
    if (!apiClient.isAuthenticated()) {
      Navigator.of(context).pushReplacementNamed('/phone-auth');
      return;
    }

    // Token looks valid locally — verify with the server before entering the app.
    // This catches revoked tokens, deleted accounts, and missing profiles
    // without waiting for the user to open the profile tab.
    if (apiClient.isPartnerLogin()) {
      // Partners don't have a /users/profile — just verify the token is live
      try {
        await getIt<AuthService>().getCurrentUser();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/partner-main');
      } catch (_) {
        if (!mounted) return;
        await apiClient.clearToken();
        await apiClient.clearRefreshToken();
        Navigator.of(context).pushReplacementNamed('/phone-auth');
      }
      return;
    }

    // Regular user — verify token AND profile existence
    try {
      await getIt<AuthService>().getCurrentUser();
      await getIt<ProfileService>().getProfile();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/main');
    } catch (e) {
      if (!mounted) return;
      // Any auth or profile failure → clear tokens and go to login
      await apiClient.clearToken();
      await apiClient.clearRefreshToken();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
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
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
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
