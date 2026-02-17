import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
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
  bool _isLoading = false;
  bool _agreedToTerms = false;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    if (!_agreedToTerms) {
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
      final response = await _authService.sendOTP(phoneNumber);

      print('✅ OTP sent successfully: ${response.message}');

      if (!mounted) return;

      // Navigate to OTP verification screen
      Navigator.of(
        context,
      ).pushNamed('/otp-verification', arguments: phoneNumber);
    } on ApiException catch (e) {
      print('❌ API Error: ${e.message}');
      if (!mounted) return;
      SnackBarHelper.showError(context, e.message);
    } catch (e) {
      print('❌ Unexpected error: $e');
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
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final maxWidth = ResponsiveUtils.responsive<double>(
      context: context,
      mobile: double.infinity,
      tablet: 700,
      desktop: 800,
    );
    final fontScale = ResponsiveUtils.getFontSizeScale(context);

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
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: _isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _agreedToTerms = value ?? false;
                                          });
                                        },
                                  activeColor: isDark
                                      ? AppColors.white
                                      : AppColors.black,
                                  checkColor: isDark
                                      ? AppColors.black
                                      : AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _agreedToTerms = !_agreedToTerms;
                                          });
                                        },
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
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.w600,
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
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
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
                      const SizedBox(height: 16),

                      // Help Text
                      Text(
                        l10n.contactSupport,
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkTertiaryText
                              : AppColors.tertiaryText,
                        ),
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
