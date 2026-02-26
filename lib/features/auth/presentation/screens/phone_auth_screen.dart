import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/features/auth/presentation/screens/partner_login_screen.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/validators.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/core/localization/widgets/language_selector.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/core/network/api_client.dart';

/// Phone Authentication Screen
/// User enters their phone number to receive OTP
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _checkboxKey = GlobalKey();
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _showCheckboxError = false;
  late final AuthService _authService;
  Timer? _longPressTimer;

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // If launch fails, show error to user
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Could not open link. Please check your browser settings.',
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Could not open link. Please try again.',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openPartnerLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PartnerLoginScreen()));
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    if (!_agreedToTerms) {
      // Show error state on checkbox
      setState(() {
        _showCheckboxError = true;
      });

      // Scroll to checkbox to make it visible
      Future.delayed(const Duration(milliseconds: 100), () {
        final context = _checkboxKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      });

      SnackBarHelper.showError(context, l10n.agreeToTermsError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format phone number with country code
      final phoneNumber = '+998${_phoneController.text}';

      // Send OTP to the phone number
      await _authService.sendOTP(phoneNumber);

      if (!mounted) return;

      // Navigate to OTP verification screen
      Navigator.of(
        context,
      ).pushNamed('/otp-verification', arguments: phoneNumber);
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, l10n.otpSendError);
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
    final locale = Localizations.localeOf(context).languageCode;
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final maxWidth = ResponsiveUtils.responsive<double>(
      context: context,
      mobile: double.infinity,
      tablet: 700,
      desktop: 800,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SVΛYP Logo — hold for 3 s to open partner login
                          Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (_) {
                                _longPressTimer?.cancel();
                                _longPressTimer = Timer(
                                  const Duration(seconds: 3),
                                  _openPartnerLogin,
                                );
                              },
                              onTapUp: (_) => _longPressTimer?.cancel(),
                              onTapCancel: () => _longPressTimer?.cancel(),
                              child: Text(
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
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Title
                          Text(
                            l10n.enterPhoneNumber,
                            style: AppTypography.display2.copyWith(
                              height: 1.2,
                              fontSize:
                                  28 *
                                  ResponsiveUtils.getFontSizeScale(context),
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Subtitle
                          Text(
                            l10n.phoneVerificationSubtitle,
                            style: AppTypography.body1.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.secondaryText,
                              fontSize:
                                  16 *
                                  ResponsiveUtils.getFontSizeScale(context),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Language Selector
                          LanguageSelector(
                            showLabel: true,
                            onLanguageChanged: (locale) {
                              // Language changed, rebuild to show translations
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 24),

                          // Phone Input
                          PhoneTextField(
                            controller: _phoneController,
                            label: l10n.phoneNumber,
                            validator: Validators.phone,
                          ),
                          const SizedBox(height: 24),

                          // Terms & Privacy
                          Row(
                            key: _checkboxKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: _showCheckboxError
                                    ? BoxDecoration(
                                        border: Border.all(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      )
                                    : null,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: _isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _agreedToTerms = value ?? false;
                                            if (_agreedToTerms) {
                                              _showCheckboxError = false;
                                            }
                                          });
                                        },
                                  activeColor: isDark
                                      ? AppColors.white
                                      : AppColors.black,
                                  checkColor: isDark
                                      ? AppColors.black
                                      : AppColors.white,
                                  side: _showCheckboxError
                                      ? const BorderSide(
                                          color: Colors.red,
                                          width: 2,
                                        )
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: l10n.iAgreeToThe,
                                    style: AppTypography.body2.copyWith(
                                      color: isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.secondaryText,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: l10n.termsOfService,
                                        style: AppTypography.body2.copyWith(
                                          color: isDark
                                              ? AppColors.darkPrimaryText
                                              : AppColors.black,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => _launchUrl(
                                            'https://svaypai.com/$locale/terms',
                                          ),
                                      ),
                                      TextSpan(
                                        text: l10n.and,
                                        style: AppTypography.body2.copyWith(
                                          color: isDark
                                              ? AppColors.darkSecondaryText
                                              : AppColors.secondaryText,
                                        ),
                                      ),
                                      TextSpan(
                                        text: l10n.privacyPolicy,
                                        style: AppTypography.body2.copyWith(
                                          color: isDark
                                              ? AppColors.darkPrimaryText
                                              : AppColors.black,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => _launchUrl(
                                            'https://svaypai.com/$locale/privacy',
                                          ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom section with button
                Container(
                  padding: EdgeInsets.all(horizontalPadding),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkMainBackground
                        : AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.white : AppColors.black)
                            .withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Continue Button
                      PrimaryButton(
                        text: l10n.continueButton,
                        onPressed: _sendOTP,
                        isLoading: _isLoading,
                        isFullWidth: true,
                      ),
                    ],
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
