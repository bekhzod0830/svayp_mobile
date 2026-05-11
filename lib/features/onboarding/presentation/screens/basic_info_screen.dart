import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/validators.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/onboarding_analytics_mixin.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

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

  // Always set gender to female
  final String _selectedGender = 'female';

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
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: AppTypography.body2.copyWith(color: AppColors.gray600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.standardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.standardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.black, width: 1.5),
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
      style: AppTypography.body2.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    if (_selectedDate == null) {
      SnackBarHelper.showError(context, l10n.selectDateError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save basic info to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      manager.setBasicInfo(
        fullName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        gender: _selectedGender, // Always female
        dateOfBirth: _selectedDate!,
      );

      if (!mounted) return;

      trackStepCompleted();

      // Navigate to hijab preference screen (since gender is always female)
      Navigator.of(
        context,
      ).pushNamed('/hijab-preference', arguments: {'gender': _selectedGender});
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
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Scrollable content
            SafeArea(
              child: SingleChildScrollView(
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
                            // Progress Indicator
                            const OnboardingProgressBar(
                              currentStep: 1,
                              totalSteps: 6,
                            ),
                            const SizedBox(height: 32),

                            // Title
                            Text(
                              l10n.tellUsAboutYourself,
                              style: AppTypography.display2.copyWith(
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              l10n.personalizeExperience,
                              style: AppTypography.body1.copyWith(
                                color: AppColors.secondaryText,
                              ),
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
                            Text(
                              l10n.dateOfBirth,
                              style: AppTypography.body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom Navigation - Only Continue button (no back button)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: AppColors.white,
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          (_nameController.text.isEmpty ||
                              _selectedDay == null ||
                              _selectedMonth == null ||
                              _selectedYear == null ||
                              _isLoading)
                          ? null
                          : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.gray300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                          : Text(
                              l10n.continueButton,
                              style: AppTypography.button.copyWith(
                                color: AppColors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ), // closes Positioned
          ], // closes Stack children
        ), // closes Stack
      ), // closes SizedBox
    ); // closes Scaffold
  }
}
