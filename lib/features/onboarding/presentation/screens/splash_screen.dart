import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/services/version_check_service.dart';
import 'package:swipe/core/services/feature_flag_service.dart';
import 'package:swipe/features/auth/data/models/auth_models.dart';
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
    final apiClient = getIt<ApiClient>();
    final versionService = VersionCheckService(apiClient);
    final featureFlagService = FeatureFlagService(apiClient);

    // Run the minimum splash delay, version check and feature-flag refresh
    // concurrently. Feature flags are cached for the phone-auth screen.
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 2500)),
      versionService.check(),
      featureFlagService.refresh(),
    ]);

    if (!mounted) return;

    // results[1] is the VersionCheckResult (or null on error)
    final versionResult = results[1] as dynamic;
    if (versionResult != null && versionResult.needsUpdate == true) {
      Navigator.of(context).pushReplacementNamed(
        '/force-update',
        arguments: <String, String>{
          'version': versionResult.latestVersion as String,
          'storeUrl': versionResult.storeUrl as String,
        },
      );
      return;
    }

    final storage = await LocalStorageHelper.getInstance();
    if (!mounted) return;

    // Guest mode — no auth needed. Land on Feed (Лента, public browse).
    if (storage.isGuestMode()) {
      Navigator.of(context).pushReplacementNamed(
        '/main',
        arguments: {'initialIndex': 0}, // 0 = Feed (Лента)
      );
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
      } catch (e) {
        if (!mounted) return;
        await _handleVerificationError(e);
      }
      return;
    }

    // Regular user — verify token AND profile existence.
    // The two calls are independent — run them in parallel to save one RTT
    // on every cold start (Future.wait rethrows the first error, same
    // 401/404 handling as the sequential version).
    try {
      final results = await Future.wait([
        getIt<AuthService>().getCurrentUser(),
        getIt<ProfileService>().getProfile(),
      ]);
      // Identify на СТАРТЕ (юзер зашёл уже залогиненным): без этого мобильная
      // session-replay запись анонимна — identify раньше был только в момент
      // логина. Тот же user_id, что в вебвью → PostHog сшивает в одну персону.
      final me = results[0] as UserResponse;
      unawaited(AnalyticsService.instance.setUser(
        userId: me.id,
        phone: me.phoneNumber,
        username: me.username,
      ));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/main');
    } catch (e) {
      if (!mounted) return;
      await _handleVerificationError(e);
    }
  }

  /// Decide what to do when the startup token/profile verification fails.
  ///
  /// We must NOT log the user out for transient backend problems — clearing
  /// the session would force a paid SMS re-login. Only a genuine auth/account
  /// failure (401/403, or a missing profile 404) clears the tokens and sends
  /// the user to login. Server outages (5xx), timeouts and network errors keep
  /// the session intact and show the maintenance screen instead.
  Future<void> _handleVerificationError(Object error) async {
    final apiClient = getIt<ApiClient>();
    final statusCode = error is ApiException ? error.statusCode : null;
    final isAuthFailure =
        statusCode == 401 || statusCode == 403 || statusCode == 404;

    if (isAuthFailure) {
      await apiClient.clearToken();
      await apiClient.clearRefreshToken();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/phone-auth');
      return;
    }

    // Transient server/network error — keep the session, let the user retry.
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/server-maintenance');
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
                // Brand Name - LIBΛS
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.display1.copyWith(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 12,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          height: 1.0,
                        ),
                        children: const [
                          TextSpan(text: 'LIB'),
                          TextSpan(text: 'Λ', style: TextStyle(color: Color(0xFFF370A7))),
                          TextSpan(text: 'S'),
                        ],
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
