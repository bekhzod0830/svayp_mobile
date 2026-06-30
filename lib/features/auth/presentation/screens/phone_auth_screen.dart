import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/features/auth/presentation/screens/partner_login_screen.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_constants.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/validators.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/core/localization/widgets/language_selector.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/utils/error_message_helper.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/features/auth/presentation/screens/verify_method_screen.dart';

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
  int _logoTapCount = 0;
  Timer? _logoTapResetTimer;
  // Backend feature flag (feature.guest_login.enabled), cached on splash.
  // Defaults to true so the button shows until the flag is read.
  bool _guestLoginEnabled = true;
  late final AuthService _authService;

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
    AnalyticsService.instance.logEvent(AnalyticsEvents.authScreenOpened);
    _loadGuestLoginFlag();
  }

  Future<void> _loadGuestLoginFlag() async {
    final storage = await LocalStorageHelper.getInstance();
    if (!mounted) return;
    setState(() => _guestLoginEnabled = storage.isGuestLoginEnabled());
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

  /// Check phone status then route to the correct screen:
  /// - New user → SocialAuthScreen (Google/Apple only)
  /// - Existing + has email → SocialAuthScreen (Google/Apple only)
  /// - Existing + no email → OTP → SocialAuthScreen (linking)
  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = '+998${_phoneController.text}';
    setState(() => _isLoading = true);

    try {
      // Whitelisted number → straight to OTP, no email verification needed.
      if (AppConstants.otpOnlyPhones
          .contains(phoneNumber.replaceAll(RegExp(r'\D'), ''))) {
        await _authService.sendOTP(phoneNumber);
        if (!mounted) return;
        Navigator.of(context).pushNamed(
          '/otp-verification',
          arguments: phoneNumber,
        );
        return;
      }

      final status = await _authService.checkPhone(phoneNumber);

      if (!mounted) return;

      if (status.exists && !status.hasEmail) {
        // Case 1: existing user without email → send OTP first
        await _authService.sendOTP(phoneNumber);
        if (!mounted) return;
        Navigator.of(context).pushNamed(
          '/otp-verification',
          arguments: phoneNumber,
        );
      } else {
        // Case 2 (existing + email) or Case 3 (new user) → social auth directly
        Navigator.of(context).pushNamed(
          '/verify-method',
          arguments: VerifyMethodArgs(
            phoneNumber: phoneNumber,
            isNew: !status.exists,
            isLinking: false,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          ErrorMessageHelper.getLocalizedMessage(context, e),
        );
      }
    } catch (_) {
      // Network error — still navigate to social auth (optimistic)
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/verify-method',
          arguments: VerifyMethodArgs(
            phoneNumber: phoneNumber,
            isNew: false,
            isLinking: false,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Enters guest mode and lands on the Discover (LIBΛS) feed. The closet tab
  /// is gated for guests, so Discover — not the closet — is their home.
  Future<void> _continueAsGuest() async {
    final storage = await LocalStorageHelper.getInstance();
    await storage.setGuestMode(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/main',
      arguments: {'initialIndex': 0}, // 0 = Feed (Лента) — default landing
    );
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
        // Guest entry — top-right corner, gated by the backend feature flag.
        actions: [
          if (_guestLoginEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _continueAsGuest,
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.black,
                ),
                child: Text(
                  l10n.guest,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
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
                                child: RichText(
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
                                      TextSpan(text: 'Λ', style: TextStyle(color: Color(0xFFF370A7))),
                                      TextSpan(text: 'S'),
                                    ],
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
                                      'https://libas.uz/$locale/terms',
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
                                      'https://libas.uz/$locale/privacy',
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
                        onPressed: _isLoading ? null : _continue,
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
