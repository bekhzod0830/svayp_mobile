import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/config/api_config.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/core/utils/error_message_helper.dart';
import 'package:swipe/core/services/seen_products_service.dart';
import 'package:swipe/core/services/notification_service.dart';
import 'package:swipe/features/auth/presentation/screens/verify_method_screen.dart';

/// OTP Verification Screen
/// User enters 6-digit OTP code sent to their phone
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _canResend = false;
  int _secondsRemaining = 60;
  Timer? _timer;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
    _startResendTimer();
    AnalyticsService.instance.logEvent(AnalyticsEvents.otpScreenOpened);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _getOtpCode() {
    return _otpController.text;
  }

  /// Format phone number as +998 (90) 123-12-12
  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters and the + sign
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // Expected format: 99890XXXXXXX (12 digits)
    if (digitsOnly.length == 12 && digitsOnly.startsWith('998')) {
      final countryCode = digitsOnly.substring(0, 3); // 998
      final areaCode = digitsOnly.substring(3, 5); // 90
      final part1 = digitsOnly.substring(5, 8); // 123
      final part2 = digitsOnly.substring(8, 10); // 12
      final part3 = digitsOnly.substring(10, 12); // 12

      return '+$countryCode ($areaCode) $part1-$part2-$part3';
    }

    // Return original if format doesn't match
    return phone;
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOTP() async {
    final otpCode = _getOtpCode();
    final l10n = AppLocalizations.of(context)!;

    if (otpCode.length != 6) {
      SnackBarHelper.showError(context, l10n.completeOtpError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    AnalyticsService.instance.logEvent(AnalyticsEvents.otpSubmitted);

    try {
      // Verify OTP with backend API

      final tokenResponse = await _authService.verifyOTP(
        phoneNumber: widget.phoneNumber,
        otpCode: otpCode,
      );

      // Debug: Verify token was saved

      if (!mounted) return;

      // Clear any leftover partner role from a previous admin session
      await getIt<ApiClient>().clearUserRole();

      // Clear guest mode if user was browsing as guest
      final storage = await LocalStorageHelper.getInstance();
      await storage.clearGuestMode();

      // Clear seen product IDs only if a different account is logging in
      await SeenProductsService.clearIfUserChanged(tokenResponse.user.id);

      // Register FCM token (fire-and-forget — non-critical)
      unawaited(NotificationService.instance.registerTokenWithBackend());

      if (!mounted) return;

      AnalyticsService.instance.logEvent(AnalyticsEvents.loginCompleted);
      await AnalyticsService.instance.setUser(
        userId: tokenResponse.user.id.toString(),
        phone: tokenResponse.user.phoneNumber,
        username: tokenResponse.user.username,
      );

      if (!mounted) return;

      // Case 1: OTP verified for existing user without email — link social account
      Navigator.of(context).pushReplacementNamed(
        '/verify-method',
        arguments: VerifyMethodArgs(
          phoneNumber: widget.phoneNumber,
          isNew: false,
          isLinking: true,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AnalyticsService.instance.logEvent(
        AnalyticsEvents.otpVerificationFailed,
        parameters: {AnalyticsEvents.paramErrorCode: e.statusCode.toString()},
      );
      SnackBarHelper.showError(
        context,
        ErrorMessageHelper.getLocalizedMessage(context, e),
      );
    } catch (e) {
      if (!mounted) return;
      AnalyticsService.instance.logEvent(
        AnalyticsEvents.otpVerificationFailed,
        parameters: {AnalyticsEvents.paramErrorCode: 'unknown'},
      );
      SnackBarHelper.showError(context, l10n.invalidOtpError);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Resend OTP via backend API
      await _authService.sendOTP(widget.phoneNumber);

      if (!mounted) return;

      AnalyticsService.instance.logEvent(AnalyticsEvents.otpResendTapped);

      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showSuccess(context, l10n.otpSentSuccess);

      _startResendTimer();
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        ErrorMessageHelper.getLocalizedMessage(context, e),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(context, l10n.resendOtpError);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Title
                      Text(
                        l10n.verifyPhoneNumber,
                        style: AppTypography.display2.copyWith(
                          height: 1.2,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle with phone number
                      Text.rich(
                        TextSpan(
                          text: l10n.enterDigitCode,
                          style: AppTypography.body1.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.secondaryText,
                          ),
                          children: [
                            TextSpan(
                              text: _formatPhoneNumber(widget.phoneNumber),
                              style: AppTypography.body1.copyWith(
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // OTP Input — single field for 6-digit code
                      TextField(
                        controller: _otpController,
                        focusNode: _otpFocusNode,
                        keyboardType: TextInputType.number,
                        keyboardAppearance: isDark
                            ? Brightness.dark
                            : Brightness.light,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        maxLength: 6,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: AppTypography.heading3.copyWith(
                          height: 1.0,
                          letterSpacing: 12,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkCardBackground
                              : AppColors.gray50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkStandardBorder
                                  : AppColors.standardBorder,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkStandardBorder
                                  : AppColors.standardBorder,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.black,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 6) _verifyOTP();
                        },
                      ),
                      const SizedBox(height: 32),

                      // Development Mode Indicator
                      if (ApiConfig.skipOtpInDev)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            border: Border.all(color: Colors.amber.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.developer_mode,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '🔓 DEV MODE: Any 6-digit code works',
                                  style: AppTypography.body2.copyWith(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Resend Code
                      Center(
                        child: _canResend
                            ? TextButton(
                                onPressed: _isLoading ? null : _resendOTP,
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.black,
                                ),
                                child: Text(
                                  l10n.resendCode,
                                  style: AppTypography.button.copyWith(
                                    decoration: TextDecoration.underline,
                                    color: isDark
                                        ? AppColors.darkPrimaryText
                                        : AppColors.black,
                                  ),
                                ),
                              )
                            : Text(
                                l10n.resendCodeIn(_secondsRemaining),
                                style: AppTypography.body2.copyWith(
                                  color: isDark
                                      ? AppColors.darkTertiaryText
                                      : AppColors.tertiaryText,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // Sticky bottom Verify button
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkMainBackground
                        : AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: PrimaryButton(
                    text: l10n.verify,
                    onPressed: _verifyOTP,
                    isLoading: _isLoading,
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
