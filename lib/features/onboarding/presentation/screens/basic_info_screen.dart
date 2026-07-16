import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/core/utils/validators.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/analytics/onboarding_analytics_mixin.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_buttons.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_inputs.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';
import 'package:swipe/features/profile/data/services/profile_service.dart';

/// Blocks digit input that would make the field value exceed [max].
/// The [min] is only enforced once the text length reaches [fullLength]
/// so that leading zeros like "05" are allowed as intermediate input.
class _RangeInputFormatter extends TextInputFormatter {
  final int min;
  final int max;
  final int fullLength;
  const _RangeInputFormatter({
    required this.min,
    required this.max,
    required this.fullLength,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null) return oldValue;
    // Always block if value already exceeds the maximum.
    if (n > max) return oldValue;
    // Only enforce minimum once the field is completely filled.
    if (newValue.text.length >= fullLength && n < min) return oldValue;
    return newValue;
  }
}

/// Basic Info Screen - First step of profile setup
/// User enters name, gender, and date of birth
class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen>
    with OnboardingAnalyticsMixin {
  @override
  String get viewedEvent => AnalyticsEvents.onboardingBasicInfoViewed;
  @override
  String get completedEvent => AnalyticsEvents.onboardingBasicInfoCompleted;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Selected gender ('male' or 'female'), null until the user picks one
  String? _selectedGender;

  // Date input controllers
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _dayFocus = FocusNode();
  final _monthFocus = FocusNode();
  final _yearFocus = FocusNode();

  // Simple date picker state
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;
      trackStepViewed();

      // Load saved data from OnboardingDataManager
      final manager = context.read<OnboardingDataManager>();
      if (manager.fullName != null) {
        _nameController.text = manager.fullName!;
      }
      if (manager.email != null) {
        _emailController.text = manager.email!;
      }
      if (manager.gender != null) {
        _selectedGender = manager.gender;
      }
      if (manager.dateOfBirth != null) {
        final d = manager.dateOfBirth!;
        setState(() {
          _selectedDay = d.day;
          _selectedMonth = d.month;
          _selectedYear = d.year;
        });
        _dayController.text = d.day.toString().padLeft(2, '0');
        _monthController.text = d.month.toString().padLeft(2, '0');
        _yearController.text = d.year.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _dayFocus.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  /// Parse and validate day/month/year text fields, updating state.
  void _parseDateFields() {
    final day = int.tryParse(_dayController.text);
    final month = int.tryParse(_monthController.text);
    final year = int.tryParse(_yearController.text);

    setState(() {
      // Validate ranges
      _selectedDay = (day != null && day >= 1 && day <= 31) ? day : null;
      _selectedMonth = (month != null && month >= 1 && month <= 12)
          ? month
          : null;
      _selectedYear = (year != null && year >= 1900 && year <= 2026)
          ? year
          : null;

      // Clamp day to actual days in month
      if (_selectedDay != null &&
          _selectedMonth != null &&
          _selectedYear != null) {
        final maxDay = DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
        if (_selectedDay! > maxDay) _selectedDay = null;
      }
    });
  }

  DateTime? get _selectedDate {
    if (_selectedDay != null &&
        _selectedMonth != null &&
        _selectedYear != null) {
      return DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
    }
    return null;
  }

  String? _validateDay(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 1 || n > 31) return 'DD';
    return null;
  }

  String? _validateMonth(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 1 || n > 12) return 'MM';
    return null;
  }

  String? _validateYear(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 1900 || n > 2026) return 'YYYY';
    return null;
  }

  /// Build a compact numeric date input field
  Widget _buildDateField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required int maxLength,
    required int minValue,
    required int maxValue,
    required String? Function(String?) validator,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: maxLength,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _RangeInputFormatter(
          min: minValue,
          max: maxValue,
          fullLength: maxLength,
        ),
      ],
      validator: validator,
      onChanged: onChanged,
      decoration: IntroInputs.decoration(hint: hint).copyWith(
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      ),
      style: IntroInputs.field,
    );
  }

  /// Build a single selectable gender option (Male / Female).
  Widget _buildGenderOption({required String label, required String value}) {
    final bool isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: _isLoading
            ? null
            : () {
                // Gender is the last field, so dismiss the keyboard to reveal
                // the Continue button at the bottom.
                FocusScope.of(context).unfocus();
                setState(() => _selectedGender = value);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? null : IntroPalette.chipBg,
            gradient: isSelected ? IntroPalette.diamondGradient : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: IntroPalette.gem.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: IntroPalette.label(
              size: 15,
              weight: FontWeight.w700,
              color: isSelected ? Colors.white : IntroPalette.ink,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    if (_selectedGender == null) {
      SnackBarHelper.showError(context, l10n.selectGenderError);
      return;
    }

    if (_selectedDate == null) {
      SnackBarHelper.showError(context, l10n.selectDateError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Keep the manager in sync (other screens may read it later).
      final manager = context.read<OnboardingDataManager>();
      manager.setBasicInfo(
        fullName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        gender: _selectedGender!,
        dateOfBirth: _selectedDate!,
      );

      // v2 registration: this is the only profile step — measurements and
      // style preferences moved into the Libas AI guided flow (Closet tab).
      final dob = '${_selectedYear!.toString().padLeft(4, '0')}-'
          '${_selectedMonth!.toString().padLeft(2, '0')}-'
          '${_selectedDay!.toString().padLeft(2, '0')}';
      try {
        await getIt<ProfileService>().createProfileV2(
          fullName: _nameController.text.trim(),
          dateOfBirth: dob,
          gender: _selectedGender!.toUpperCase(),
        );
      } on ApiException catch (e) {
        // 409 PROFILE_ALREADY_EXISTS — a previous attempt landed; proceed.
        if (e.statusCode != 409) rethrow;
      }

      if (!mounted) return;

      trackStepCompleted();
      AnalyticsService.instance.logEvent(AnalyticsEvents.onboardingCompleted);

      final storage = await LocalStorageHelper.getInstance();
      // Survives process death between this POST and the first /main frame.
      await storage.setWelcomeGiftPending(true);
      // Covers users who reached auth without the carousel (deep links).
      await storage.setSeenIntro(true);

      if (!mounted) return;

      // Land on the Closet tab: its WebView shows the "Welcome to Libas AI"
      // guided flow (add items → outfit → try-on) on first open.
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (_) => false,
        arguments: {'initialIndex': 1, 'showWelcomeGift': true},
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, l10n.saveInfoError);
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
      // Resize when the keyboard opens so the Continue button rides above it
      // and the form stays scrollable. The numeric date keypad has no "Done"
      // key, so both a tap-outside (GestureDetector below) and a scroll drag
      // (keyboardDismissBehavior) are wired up to dismiss it.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(
                          ResponsiveUtils.getHorizontalPadding(context),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Single-step registration — no progress bar.
                              const SizedBox(height: 16),

                              // Title
                              Text(
                                l10n.tellUsAboutYourself,
                                style: IntroPalette.headline(size: 28)
                                    .copyWith(height: 1.2),
                              ),
                              const SizedBox(height: 12),

                              // Subtitle
                              Text(
                                l10n.personalizeExperience,
                                style: IntroPalette.subtitle(size: 16),
                              ),
                              const SizedBox(height: 40),

                              // Name Input
                              CustomTextField(
                                controller: _nameController,
                                label: l10n.fullName,
                                hintText: l10n.enterYourName,
                                validator: Validators.name,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 24),

                              // Date of Birth - Numeric input fields
                              Text(l10n.dateOfBirth, style: IntroInputs.label),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Day field
                                  Expanded(
                                    flex: 2,
                                    child: _buildDateField(
                                      controller: _dayController,
                                      focusNode: _dayFocus,
                                      hint: l10n.day,
                                      maxLength: 2,
                                      minValue: 1,
                                      maxValue: 31,
                                      validator: _validateDay,
                                      onChanged: (v) {
                                        _parseDateFields();
                                        // Auto-advance to month when 2 digits entered
                                        if (v.length == 2) {
                                          FocusScope.of(
                                            context,
                                          ).requestFocus(_monthFocus);
                                        }
                                      },
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 14,
                                    ),
                                    child: Text(
                                      '.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Month field
                                  Expanded(
                                    flex: 2,
                                    child: _buildDateField(
                                      controller: _monthController,
                                      focusNode: _monthFocus,
                                      hint: l10n.month,
                                      maxLength: 2,
                                      minValue: 1,
                                      maxValue: 12,
                                      validator: _validateMonth,
                                      onChanged: (v) {
                                        _parseDateFields();
                                        // Auto-advance to year when 2 digits entered
                                        if (v.length == 2) {
                                          FocusScope.of(
                                            context,
                                          ).requestFocus(_yearFocus);
                                        }
                                      },
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 14,
                                    ),
                                    child: Text(
                                      '.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Year field
                                  Expanded(
                                    flex: 3,
                                    child: _buildDateField(
                                      controller: _yearController,
                                      focusNode: _yearFocus,
                                      hint: l10n.year,
                                      maxLength: 4,
                                      minValue: 1900,
                                      maxValue: 2026,
                                      validator: _validateYear,
                                      onChanged: (_) => _parseDateFields(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Gender
                              Text(l10n.gender, style: IntroInputs.label),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildGenderOption(
                                    label: l10n.female,
                                    value: 'female',
                                  ),
                                  const SizedBox(width: 12),
                                  _buildGenderOption(
                                    label: l10n.male,
                                    value: 'male',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation - Only Continue button (no back button).
              // Sits below the scroll area so it always rides just above the
              // keyboard (or the safe-area inset) and stays tappable.
              Container(
                width: double.infinity,
                color: AppColors.white,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: IntroPrimaryButton(
                  label: l10n.continueButton,
                  isLoading: _isLoading,
                  enabled:
                      _nameController.text.isNotEmpty &&
                      _selectedGender != null &&
                      _selectedDay != null &&
                      _selectedMonth != null &&
                      _selectedYear != null,
                  onTap: _continue,
                ),
              ),
            ], // closes Column children
          ), // closes Column
        ), // closes GestureDetector
      ), // closes SafeArea
    ); // closes Scaffold
  }
}
