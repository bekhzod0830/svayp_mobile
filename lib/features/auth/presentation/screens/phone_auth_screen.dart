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
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/utils/error_message_helper.dart';

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
  bool _isLoading = false;
  late final AuthService _authService;
  int _logoTapCount = 0;
  Timer? _logoTapResetTimer;

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
    _logoTapResetTimer?.cancel();
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
      SnackBarHelper.showError(
        context,
        ErrorMessageHelper.getLocalizedMessage(context, e),
      );
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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
                          // SVΛYP Logo — tap 5 times to open partner login
                          Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _logoTapCount++;
                                _logoTapResetTimer?.cancel();
                                if (_logoTapCount >= 5) {
                                  _logoTapCount = 0;
                                  _openPartnerLogin();
                                } else {
                                  // Reset counter if no tap within 2 seconds
                                  _logoTapResetTimer = Timer(
                                    const Duration(seconds: 2),
                                    () => _logoTapCount = 0,
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
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
                          const SizedBox(height: 16),

                          // Terms & Privacy notice
                          Text.rich(
                            TextSpan(
                              text: l10n.byContinuingYouAgreeTo,
                              style: AppTypography.body2.copyWith(
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.secondaryText,
                                fontSize: 12,
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
                                    fontSize: 12,
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
                                    fontSize: 12,
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
                                    fontSize: 12,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _launchUrl(
                                      'https://svaypai.com/$locale/privacy',
                                    ),
                                ),
                                if (l10n.agreeToTermsSuffix.isNotEmpty)
                                  TextSpan(
                                    text: l10n.agreeToTermsSuffix,
                                    style: AppTypography.body2.copyWith(
                                      color: isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.secondaryText,
                                      fontSize: 12,
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
                      const SizedBox(height: 8),
                      // Browse as Guest
                      TextButton(
                        onPressed: () async {
                          final storage =
                              await LocalStorageHelper.getInstance();
                          await storage.setGuestMode(true);
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/main');
                          }
                        },
                        child: Text(
                          l10n.browseAsGuest,
                          style: const TextStyle(fontSize: 14),
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
