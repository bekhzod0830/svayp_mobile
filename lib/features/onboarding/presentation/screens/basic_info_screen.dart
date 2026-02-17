import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/validators.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Basic Info Screen - First step of profile setup
/// User enters name, gender, and date of birth
class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Always set gender to female
  final String _selectedGender = 'female';

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

      // Load saved data from OnboardingDataManager
      final manager = context.read<OnboardingDataManager>();
      if (manager.fullName != null) {
        _nameController.text = manager.fullName!;
      }
      if (manager.email != null) {
        _emailController.text = manager.email!;
      }
      if (manager.dateOfBirth != null) {
        setState(() {
          _selectedDay = manager.dateOfBirth!.day;
          _selectedMonth = manager.dateOfBirth!.month;
          _selectedYear = manager.dateOfBirth!.year;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  DateTime? get _selectedDate {
    if (_selectedDay != null &&
        _selectedMonth != null &&
        _selectedYear != null) {
      return DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
    }
    return null;
  }

  List<int> _getDaysInMonth() {
    if (_selectedMonth == null || _selectedYear == null) {
      return List.generate(31, (index) => index + 1);
    }
    final daysInMonth = DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
    return List.generate(daysInMonth, (index) => index + 1);
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
                              totalSteps: 10,
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

                            // Date of Birth - Simple Dropdowns
                            Text(
                              l10n.dateOfBirth,
                              style: AppTypography.body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Day Dropdown
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.standardBorder,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: _selectedDay,
                                        dropdownColor: AppColors.white,
                                        hint: Text(
                                          l10n.day,
                                          style: AppTypography.body2.copyWith(
                                            color: AppColors.gray600,
                                          ),
                                        ),
                                        isExpanded: true,
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: AppColors.gray600,
                                        ),
                                        selectedItemBuilder:
                                            (BuildContext context) {
                                              return _getDaysInMonth().map((
                                                day,
                                              ) {
                                                return Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    day.toString(),
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                );
                                              }).toList();
                                            },
                                        items: _getDaysInMonth().map((day) {
                                          return DropdownMenuItem<int>(
                                            value: day,
                                            child: Text(
                                              day.toString(),
                                              style: AppTypography.body2,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: _isLoading
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _selectedDay = value;
                                                });
                                              },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Month Dropdown
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.standardBorder,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: _selectedMonth,
                                        dropdownColor: AppColors.white,
                                        hint: Text(
                                          l10n.month,
                                          style: AppTypography.body2.copyWith(
                                            color: AppColors.gray600,
                                          ),
                                        ),
                                        isExpanded: true,
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: AppColors.gray600,
                                        ),
                                        selectedItemBuilder:
                                            (BuildContext context) {
                                              return [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.january,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.february,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.march,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.april,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.may,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.june,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.july,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.august,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.september,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.october,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.november,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    l10n.december,
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                              ];
                                            },
                                        items: [
                                          DropdownMenuItem(
                                            value: 1,
                                            child: Text(
                                              l10n.january,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 2,
                                            child: Text(
                                              l10n.february,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 3,
                                            child: Text(
                                              l10n.march,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 4,
                                            child: Text(
                                              l10n.april,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 5,
                                            child: Text(
                                              l10n.may,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 6,
                                            child: Text(
                                              l10n.june,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 7,
                                            child: Text(
                                              l10n.july,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 8,
                                            child: Text(
                                              l10n.august,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 9,
                                            child: Text(
                                              l10n.september,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 10,
                                            child: Text(
                                              l10n.october,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 11,
                                            child: Text(
                                              l10n.november,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 12,
                                            child: Text(
                                              l10n.december,
                                              style: AppTypography.body2,
                                            ),
                                          ),
                                        ],
                                        onChanged: _isLoading
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _selectedMonth = value;
                                                  // Reset day if it's invalid for the new month
                                                  if (_selectedDay != null &&
                                                      _selectedYear != null) {
                                                    final daysInMonth =
                                                        DateTime(
                                                          _selectedYear!,
                                                          value! + 1,
                                                          0,
                                                        ).day;
                                                    if (_selectedDay! >
                                                        daysInMonth) {
                                                      _selectedDay =
                                                          daysInMonth;
                                                    }
                                                  }
                                                });
                                              },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Year Dropdown
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.standardBorder,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: _selectedYear,
                                        dropdownColor: AppColors.white,
                                        hint: Text(
                                          l10n.year,
                                          style: AppTypography.body2.copyWith(
                                            color: AppColors.gray600,
                                          ),
                                        ),
                                        isExpanded: true,
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: AppColors.gray600,
                                        ),
                                        selectedItemBuilder:
                                            (BuildContext context) {
                                              return List.generate(
                                                (DateTime.now().year - 1950) +
                                                    1,
                                                (index) =>
                                                    DateTime.now().year -
                                                    13 -
                                                    index,
                                              ).map((year) {
                                                return Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    year.toString(),
                                                    style: AppTypography.body2
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                );
                                              }).toList();
                                            },
                                        items:
                                            List.generate(
                                              (DateTime.now().year - 1950) + 1,
                                              (index) =>
                                                  DateTime.now().year -
                                                  13 -
                                                  index,
                                            ).map((year) {
                                              return DropdownMenuItem<int>(
                                                value: year,
                                                child: Text(
                                                  year.toString(),
                                                  style: AppTypography.body2,
                                                ),
                                              );
                                            }).toList(),
                                        onChanged: _isLoading
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _selectedYear = value;
                                                  // Reset day if it's invalid for the new month/year
                                                  if (_selectedDay != null &&
                                                      _selectedMonth != null) {
                                                    final daysInMonth =
                                                        DateTime(
                                                          value!,
                                                          _selectedMonth! + 1,
                                                          0,
                                                        ).day;
                                                    if (_selectedDay! >
                                                        daysInMonth) {
                                                      _selectedDay =
                                                          daysInMonth;
                                                    }
                                                  }
                                                });
                                              },
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
