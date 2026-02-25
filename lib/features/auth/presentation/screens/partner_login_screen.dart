import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/shared/widgets/widgets.dart';

/// Partner Login Screen
/// Hidden screen for sellers and sales representatives.
/// They can log in here to reply to users and give cashback.
class PartnerLoginScreen extends StatefulWidget {
  const PartnerLoginScreen({super.key});

  @override
  State<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends State<PartnerLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.adminLogin(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Navigate to partner main screen (no consumer tabs)
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/partner-main', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        AppLocalizations.of(context)!.partnerLoginFailed,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Logo + badge — centered
                  Center(
                    child: Column(
                      children: [
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
                        const SizedBox(height: 10),

                        // Partner badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.white : AppColors.black)
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.partnerPortal,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.secondaryText,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    l10n.partnerWelcomeBack,
                    style: AppTypography.display2.copyWith(
                      height: 1.2,
                      fontSize: 28 * ResponsiveUtils.getFontSizeScale(context),
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.partnerSignInSubtitle,
                    style: AppTypography.body1.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Username / Email field
                  _PartnerTextField(
                    controller: _usernameController,
                    label: l10n.partnerUsernameLabel,
                    hint: l10n.partnerUsernameHint,
                    prefixIcon: Icons.person_outline_rounded,
                    isDark: isDark,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username or email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  _PartnerTextField(
                    controller: _passwordController,
                    label: l10n.partnerPasswordLabel,
                    hint: l10n.partnerPasswordHint,
                    prefixIcon: Icons.lock_outline_rounded,
                    isDark: isDark,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: forgot password flow
                      },
                      child: Text(
                        l10n.partnerForgotPassword,
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Sign in button
                  PrimaryButton(
                    text: l10n.partnerSignIn,
                    onPressed: _login,
                    isLoading: _isLoading,
                    isFullWidth: true,
                  ),

                  const SizedBox(height: 24),

                  // Support note
                  Center(
                    child: Text(
                      l10n.partnerNeedAccess,
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkTertiaryText
                            : AppColors.tertiaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable text field for the partner login form
class _PartnerTextField extends StatelessWidget {
  const _PartnerTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.isDark,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isDark;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? AppColors.darkSecondaryText
        : AppColors.gray300;
    final focusedBorderColor = isDark
        ? AppColors.darkPrimaryText
        : AppColors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body2.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body1.copyWith(
              color: isDark ? AppColors.darkTertiaryText : AppColors.gray400,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? AppColors.darkCardBackground : AppColors.gray50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
