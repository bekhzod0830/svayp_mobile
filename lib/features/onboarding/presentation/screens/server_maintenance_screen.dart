import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/app/routes.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Server Maintenance Screen
///
/// Shown when the backend is temporarily unreachable (5xx responses,
/// timeouts or network errors) while the user already has a valid session.
///
/// IMPORTANT: this screen does NOT clear the auth tokens. It exists so a
/// transient server outage never logs the user out — losing the session
/// would force a paid SMS re-login. Retry simply re-runs the splash gate,
/// which re-verifies the (still valid) token once the backend recovers.
class ServerMaintenanceScreen extends StatefulWidget {
  const ServerMaintenanceScreen({super.key});

  @override
  State<ServerMaintenanceScreen> createState() =>
      _ServerMaintenanceScreenState();
}

class _ServerMaintenanceScreenState extends State<ServerMaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Re-run the splash gate. Tokens are still intact, so once the backend
  /// is healthy again the user lands straight back in the app — no re-login.
  void _retry() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.splash,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor:
              isDark ? AppColors.darkMainBackground : AppColors.white,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // ── LIBΛS logo ────────────────────────────────────────
                    RichText(
                      text: TextSpan(
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 48,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          letterSpacing: -1,
                        ),
                        children: const [
                          TextSpan(text: 'LIB'),
                          TextSpan(
                              text: 'Λ',
                              style: TextStyle(color: Color(0xFFF370A7))),
                          TextSpan(text: 'S'),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // ── title ─────────────────────────────────────────
                    Text(
                      l10n.serverMaintenanceTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── subtitle ──────────────────────────────────────
                    Text(
                      l10n.serverMaintenanceSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.body1.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                        height: 1.55,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // ── retry button ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _retry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? AppColors.white : AppColors.black,
                          foregroundColor:
                              isDark ? AppColors.black : AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.tryAgain,
                          style: AppTypography.button.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.black : AppColors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
