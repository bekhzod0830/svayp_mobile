import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/config/api_config.dart';

/// OTP Verification Screen
/// User enters 6-digit OTP code sent to their phone
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
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

    // Focus the first field as soon as the screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNodes[0].requestFocus();
    });

    // Listen to every field for paste / SMS autofill of full OTP
    for (int i = 0; i < 6; i++) {
      final idx = i;
      _otpControllers[i].addListener(() => _handlePasteOrAutofill(idx));
    }

    // Detect backspace on already-empty fields so user can delete backwards
    // without needing to tap each field manually.
    for (int i = 1; i < 6; i++) {
      final idx = i;
      _otpFocusNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _otpControllers[idx].text.isEmpty) {
          _otpFocusNodes[idx - 1].requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  /// Handle paste or SMS autofill — any field may receive the full OTP string
  void _handlePasteOrAutofill(int index) {
    final text = _otpControllers[index].text;

    if (text.length < 2) return; // Normal single-digit input — ignore

    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return;

    // Distribute first 6 digits starting from position 0 (regardless of
    // which field received the autofill / paste)
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = digits[i];
      _otpControllers[i].selection = TextSelection.fromPosition(
        TextPosition(offset: 1),
      );
    }

    // Move focus to last field and dismiss the keyboard
    _otpFocusNodes[5].requestFocus();

    // Auto-verify after a brief delay so the UI settles first
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _verifyOTP();
    });
  }

  String _getOtpCode() {
    return _otpControllers.map((c) => c.text).join();
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

      if (!mounted) return;

      // Check if user has completed their profile
      if (tokenResponse.user.hasProfile) {
        // User has profile - go to main app
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        // User needs to complete profile - start onboarding
        Navigator.of(context).pushReplacementNamed('/basic-info');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
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

      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showSuccess(context, l10n.otpSentSuccess);

      _startResendTimer();
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e.message);
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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
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
                        style: AppTypography.display2.copyWith(height: 1.2),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle with phone number
                      Text.rich(
                        TextSpan(
                          text: l10n.enterDigitCode,
                          style: AppTypography.body1.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          children: [
                            TextSpan(
                              text: _formatPhoneNumber(widget.phoneNumber),
                              style: AppTypography.body1.copyWith(
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // OTP Input (6 digits)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                          (index) => SizedBox(
                            width: 48,
                            height: 56,
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _otpFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              textAlignVertical: TextAlignVertical.center,
                              maxLength:
                                  6, // All fields accept up to 6 chars for autofill/paste
                              autofillHints: const [AutofillHints.oneTimeCode],
                              style: AppTypography.heading3.copyWith(
                                height: 1.0,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: AppColors.gray50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.standardBorder,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.standardBorder,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.black,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                // Multi-char input (paste / autofill) is handled
                                // by the per-controller listener; skip here.
                                if (value.length > 1) return;

                                // Handle forward movement (typing single digit)
                                if (value.length == 1 && index < 5) {
                                  _otpFocusNodes[index + 1].requestFocus();
                                }

                                // Handle backward movement (deletion/backspace)
                                if (value.isEmpty && index > 0) {
                                  _otpFocusNodes[index - 1].requestFocus();
                                  _otpControllers[index - 1].clear();
                                }

                                // Auto-verify when last digit is entered manually
                                if (index == 5 && value.length == 1) {
                                  _verifyOTP();
                                }
                              },
                              onTap: () {
                                // Select all text when tapped for easier editing
                                _otpControllers[index].selection =
                                    TextSelection(
                                      baseOffset: 0,
                                      extentOffset:
                                          _otpControllers[index].text.length,
                                    );
                              },
                            ),
                          ),
                        ),
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
                                child: Text(
                                  l10n.resendCode,
                                  style: AppTypography.button.copyWith(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              )
                            : Text(
                                l10n.resendCodeIn(_secondsRemaining),
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.tertiaryText,
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
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
