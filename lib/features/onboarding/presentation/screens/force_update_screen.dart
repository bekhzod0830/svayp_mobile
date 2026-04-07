import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Force Update Screen
///
/// Shown when the running app version is older than the latest version
/// published by the backend. Fully blocks the app (no back navigation).
class ForceUpdateScreen extends StatefulWidget {
  final String latestVersion;
  final String storeUrl;

  const ForceUpdateScreen({
    super.key,
    required this.latestVersion,
    required this.storeUrl,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  bool _isLaunching = false;

  static const String _fallbackUrl =
      'https://apps.apple.com/us/app/svayp-ai/id6759787092';

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

  Future<void> _openStore() async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);
    final rawUrl = widget.storeUrl.isNotEmpty ? widget.storeUrl : _fallbackUrl;
    try {
      // On iOS, replace https://apps.apple.com with itms-apps://apps.apple.com
      // so the OS opens the App Store app directly instead of Safari.
      final iosUrl = rawUrl.replaceFirst(
        'https://apps.apple.com',
        'itms-apps://apps.apple.com',
      );
      final preferredUri = Uri.parse(Platform.isIOS ? iosUrl : rawUrl);
      final fallbackUri = Uri.parse(rawUrl);

      if (await canLaunchUrl(preferredUri)) {
        await launchUrl(preferredUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // silently ignore — user can try again
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
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

                    // ── SVΛYP logo ────────────────────────────────────
                    Text(
                      'SVΛYP',
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 48,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                        letterSpacing: -1,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // ── title ─────────────────────────────────────────
                    Text(
                      l10n.forceUpdateTitle,
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
                      l10n.forceUpdateSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.body1.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                        height: 1.55,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // ── update button ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLaunching ? null : _openStore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.white
                              : AppColors.black,
                          foregroundColor: isDark
                              ? AppColors.black
                              : AppColors.white,
                          disabledBackgroundColor: isDark
                              ? AppColors.white.withValues(alpha: 0.4)
                              : AppColors.black.withValues(alpha: 0.4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLaunching
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: isDark
                                      ? AppColors.black
                                      : AppColors.white,
                                ),
                              )
                            : Text(
                                l10n.forceUpdateButton,
                                style: AppTypography.button.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.black
                                      : AppColors.white,
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
