import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/core/utils/error_message_helper.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/features/auth/data/services/social_auth_service.dart';

/// Arguments passed to [VerifyMethodScreen] via named route.
class VerifyMethodArgs {
  final String phoneNumber;
  final bool isNew;
  final bool isLinking;

  const VerifyMethodArgs({
    required this.phoneNumber,
    this.isNew = false,
    this.isLinking = false,
  });
}

/// Social auth screen — Google / Apple sign-in (+ SMS fallback for new users).
///
/// Modes:
/// - [isNew] = true → "Создать аккаунт" title, SMS visible
/// - [isLinking] = true → "Привяжите аккаунт" title, SMS hidden
/// - Both false (existing user) → "Войти" title, SMS hidden
class VerifyMethodScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isNew;
  final bool isLinking;

  const VerifyMethodScreen({
    super.key,
    required this.phoneNumber,
    this.isNew = false,
    this.isLinking = false,
  });

  @override
  State<VerifyMethodScreen> createState() => _VerifyMethodScreenState();
}

class _VerifyMethodScreenState extends State<VerifyMethodScreen> {
  late final SocialAuthService _social;
  late final AuthService _authService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
    _social = getIt<SocialAuthService>();
  }

  /// Format as +998 (90) 123-12-12.
  String _formatPhone(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.length == 12 && d.startsWith('998')) {
      return '+${d.substring(0, 3)} (${d.substring(3, 5)}) '
          '${d.substring(5, 8)}-${d.substring(8, 10)}-${d.substring(10, 12)}';
    }
    return phone;
  }

  void _routeAfter(bool hasProfile) {
    if (!mounted) return;
    if (hasProfile) {
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (_) => false);
    } else {
      Navigator.of(context).pushReplacementNamed('/basic-info');
    }
  }

  Future<void> _googleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result =
          await _social.signInWithGoogle(phoneNumber: widget.phoneNumber);
      if (result != null) {
        _routeAfter(result.hasProfile);
        return;
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          ErrorMessageHelper.getLocalizedMessage(context, e),
        );
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _appleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result =
          await _social.signInWithApple(phoneNumber: widget.phoneNumber);
      if (result != null) {
        _routeAfter(result.hasProfile);
        return;
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          ErrorMessageHelper.getLocalizedMessage(context, e),
        );
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// SMS is only sent here, on explicit user choice.
  Future<void> _smsSignIn() async {
    if (_isLoading) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      await _authService.sendOTP(widget.phoneNumber);
      if (!mounted) return;
      await Navigator.of(context)
          .pushNamed('/otp-verification', arguments: widget.phoneNumber);
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          ErrorMessageHelper.getLocalizedMessage(context, e),
        );
      }
    } catch (_) {
      if (mounted) SnackBarHelper.showError(context, l10n.otpSendError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pad = ResponsiveUtils.getHorizontalPadding(context);
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.black;
    final secondaryText =
        isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor:
            isDark ? AppColors.darkMainBackground : AppColors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Logo
              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.heading2.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 44,
                      letterSpacing: -1,
                      color: primaryText,
                    ),
                    children: const [
                      TextSpan(text: 'LIB'),
                      TextSpan(
                        text: 'Λ',
                        style: TextStyle(color: Color(0xFFF370A7)),
                      ),
                      TextSpan(text: 'S'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Title + subtitle
              Text(
                widget.isLinking
                    ? l10n.linkAccountTitle
                    : widget.isNew
                        ? l10n.createAccountTitle
                        : l10n.signInTitle,
                style: AppTypography.display2.copyWith(
                  height: 1.2,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.verifyMethodSubtitle,
                style: AppTypography.body1.copyWith(color: secondaryText),
              ),
              const SizedBox(height: 20),

              // Phone chip
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardBackground
                        : AppColors.gray50,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkStandardBorder
                          : AppColors.standardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_outlined, size: 18, color: secondaryText),
                      const SizedBox(width: 8),
                      Text(
                        _formatPhone(widget.phoneNumber),
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Google
              _SocialButton(
                label: l10n.continueWithGoogle,
                icon: SvgPicture.asset(
                  'assets/icons/ic_google.svg',
                  width: 22,
                  height: 22,
                ),
                onPressed: _isLoading ? null : _googleSignIn,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Apple — iOS only
              if (Platform.isIOS) ...[
                _SocialButton(
                  label: l10n.continueWithApple,
                  icon: SvgPicture.asset(
                    'assets/icons/ic_apple.svg',
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(primaryText, BlendMode.srcIn),
                  ),
                  onPressed: _isLoading ? null : _appleSignIn,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
              ],

              // SMS fallback — shown only for new users, not when linking or for existing users with email
              if (!widget.isLinking && widget.isNew)
                TextButton(
                  onPressed: _isLoading ? null : _smsSignIn,
                  child: Text(
                    l10n.verifyWithSms,
                    style: AppTypography.button.copyWith(
                      color: primaryText,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

              SizedBox(
                height: 24,
                child: _isLoading
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryText,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined, pill-shaped social button (secondary style per DESIGN.md).
class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isDark;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkPrimaryText : AppColors.black;
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(
            color: isDark
                ? AppColors.darkStandardBorder
                : AppColors.standardBorder,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.button.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
