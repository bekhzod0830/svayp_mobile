import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/features/profile/data/models/profile_models.dart';
import 'package:swipe/features/profile/data/services/profile_service.dart';
import 'package:swipe/shared/widgets/widgets.dart';

/// Edit Profile Screen - Allows user to update their profile information
class EditProfileScreen extends StatefulWidget {
  final UserProfileResponse profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  // Date of birth — DD.MM.YYYY fields
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _dayFocus = FocusNode();
  final _monthFocus = FocusNode();
  final _yearFocus = FocusNode();
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;

  // Body type
  String? _selectedBodyType;

  // Sizes
  String? _selectedTopSize;
  String? _selectedBottomSize;
  String? _selectedDressSize;
  String? _selectedJeanWaist;
  String? _selectedShoeSize;
  String? _selectedBraBand;
  String? _selectedBraCup;

  // Style preferences
  String? _selectedHijabPreference;
  List<String> _selectedFitPreference = [];
  List<String> _selectedStylePreference = [];
  List<String> _selectedStyleCategories = [];

  // Budget
  String? _selectedBudgetType;

  bool _isLoading = false;

  // Size options (display values)
  final List<String> _topSizes = [
    'XXS',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    '4XL',
  ];
  final List<String> _bottomSizes = [
    '24',
    '25',
    '26',
    '27',
    '28',
    '29',
    '30',
    '31',
    '32',
    '33',
    '34',
    '36',
    '38',
    '40',
    '42',
    '44',
    '46',
    '48',
  ];
  final List<String> _dressSizes = [
    'XXS',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    '4XL',
  ];
  final List<String> _jeanWaists = [
    '24',
    '25',
    '26',
    '27',
    '28',
    '29',
    '30',
    '31',
    '32',
    '33',
    '34',
    '36',
    '38',
    '40',
  ];
  final List<String> _shoeSizes = [
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
  ];
  final List<String> _braBands = [
    '60',
    '65',
    '70',
    '75',
    '80',
    '85',
    '90',
    '95',
    '100',
    '105',
    '110',
    '115',
    '120',
  ];
  final List<String> _braCups = [
    'A',
    'B',
    'C',
    'D',
    'DD',
    'DDD',
    'E',
    'F',
    'G',
    'H',
  ];

  final List<String> _bodyTypes = [
    'HOURGLASS',
    'TRIANGLE',
    'RECTANGLE',
    'OVAL',
    'HEART',
  ];
  final List<String> _hijabOptions = ['COVERED', 'UNCOVERED'];
  final List<String> _fitOptions = [
    'LOOSE',
    'REGULAR',
    'SLIM',
    'OVERSIZED',
    'SUPER_SLIM',
  ];
  final List<String> _stylePreferenceOptions = ['REVEALING', 'COVERED'];
  final List<String> _styleCategoryOptions = [
    'CASUAL',
    'FORMAL',
    'BUSINESS',
    'SPORTY',
    'ELEGANT',
    'BOHEMIAN',
    'VINTAGE',
    'MODERN',
    'MINIMALIST',
    'CLASSIC',
    'TRENDY',
    'MODEST',
    'STREETWEAR',
    'ROMANTIC',
    'CHIC',
  ];
  final List<String> _budgetTypes = ['BUDGET', 'PREMIUM', 'LUXURY', 'FLEXIBLE'];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.profile.fullName ?? '',
    );
    _heightController = TextEditingController(
      text: widget.profile.heightCm?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.profile.weightKg?.toStringAsFixed(1) ?? '',
    );

    // Parse date of birth into DD.MM.YYYY fields
    if (widget.profile.dateOfBirth != null) {
      try {
        final dob = DateTime.parse(widget.profile.dateOfBirth!);
        _selectedDay = dob.day;
        _selectedMonth = dob.month;
        _selectedYear = dob.year;
        _dayController.text = dob.day.toString().padLeft(2, '0');
        _monthController.text = dob.month.toString().padLeft(2, '0');
        _yearController.text = dob.year.toString();
      } catch (_) {}
    }

    _selectedBodyType = widget.profile.bodyType?.toUpperCase();
    _selectedHijabPreference = widget.profile.hijabPreference.toUpperCase();
    _selectedFitPreference =
        widget.profile.fitPreference?.map((e) => e.toUpperCase()).toList() ??
        [];
    _selectedStylePreference =
        widget.profile.stylePreference?.map((e) => e.toUpperCase()).toList() ??
        [];
    _selectedStyleCategories =
        widget.profile.styleCategories?.map((e) => e.toUpperCase()).toList() ??
        [];
    _selectedBudgetType = widget.profile.budgetType?.toUpperCase();

    // Parse sizes to display values
    _selectedTopSize = _parseTopSize(widget.profile.topSize);
    _selectedBottomSize = _parseNumericSize(widget.profile.bottomSize);
    _selectedDressSize = _parseTopSize(widget.profile.dressSize);
    _selectedJeanWaist = _parseNumericSize(widget.profile.jeanWaistSize);
    _selectedShoeSize = _parseNumericSize(widget.profile.shoeSize);
    _selectedBraBand = _parseNumericSize(widget.profile.braBandSize);
    _selectedBraCup = widget.profile.braCupSize?.toUpperCase();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _dayFocus.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  void _parseDateFields() {
    final day = int.tryParse(_dayController.text);
    final month = int.tryParse(_monthController.text);
    final year = int.tryParse(_yearController.text);
    setState(() {
      _selectedDay = (day != null && day >= 1 && day <= 31) ? day : null;
      _selectedMonth = (month != null && month >= 1 && month <= 12)
          ? month
          : null;
      _selectedYear = (year != null && year >= 1900 && year <= 2026)
          ? year
          : null;
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

  /// Parse "SIZE_24" or "EU_24" -> "24", plain values -> as-is
  String? _parseNumericSize(String? size) {
    if (size == null) return null;
    final match = RegExp(r'\d+').firstMatch(size);
    return match?.group(0) ?? size.toUpperCase();
  }

  /// Parse plain string size: "M", "XS" etc.
  String? _parseTopSize(String? size) {
    if (size == null) return null;
    return size.toUpperCase();
  }

  /// Format display value back to API enum: "24" -> "SIZE_24"
  String? _formatPantsSize(String? size) {
    if (size == null) return null;
    if (size.startsWith('SIZE_')) return size.replaceFirst('SIZE_', '');
    return size;
  }

  /// Format display value back to API enum: "37" -> "EU_37"
  String? _formatEuSize(String? size) {
    if (size == null) return null;
    if (size.startsWith('EU_')) return size.toUpperCase();
    return 'EU_$size';
  }

  String _translateBodyType(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'HOURGLASS':
        return l10n.enumHourglass;
      case 'TRIANGLE':
        return l10n.enumTriangle;
      case 'RECTANGLE':
        return l10n.enumRectangle;
      case 'OVAL':
        return l10n.enumOval;
      case 'HEART':
        return l10n.enumHeart;
      case 'PREFER_NOT_TO_SAY':
        return l10n.enumPreferNotToSay;
      default:
        return value;
    }
  }

  String _translateHijabOption(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'COVERED':
        return l10n.enumCovered;
      case 'UNCOVERED':
        return l10n.enumUncovered;
      case 'NOT_APPLICABLE':
        return l10n.enumNotApplicable;
      default:
        return value;
    }
  }

  String _translateFitOption(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'LOOSE':
        return l10n.enumLoose;
      case 'REGULAR':
        return l10n.enumRegular;
      case 'SLIM':
        return l10n.enumSlim;
      case 'OVERSIZED':
        return l10n.enumOversized;
      case 'SUPER_SLIM':
        return l10n.enumSuperSlim;
      case 'FITTED':
        return l10n.enumFitted;
      default:
        return value;
    }
  }

  String _translateStylePreference(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'MODERATE':
        return l10n.enumModerate;
      case 'REVEALING':
        return l10n.enumRevealing;
      case 'COVERED':
        return l10n.enumCovered;
      default:
        return value;
    }
  }

  String _translateStyleCategory(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'CASUAL':
        return l10n.enumCasual;
      case 'FORMAL':
        return l10n.enumFormal;
      case 'BUSINESS':
        return l10n.enumBusiness;
      case 'SPORTY':
        return l10n.enumSporty;
      case 'ELEGANT':
        return l10n.enumElegant;
      case 'BOHEMIAN':
        return l10n.enumBohemian;
      case 'VINTAGE':
        return l10n.enumVintage;
      case 'MODERN':
        return l10n.enumModern;
      case 'MINIMALIST':
        return l10n.enumMinimalist;
      case 'CLASSIC':
        return l10n.enumClassic;
      case 'TRENDY':
        return l10n.enumTrendy;
      case 'MODEST':
        return l10n.enumModest;
      case 'STREETWEAR':
        return l10n.enumStreetwear;
      case 'ROMANTIC':
        return l10n.enumRomantic;
      case 'CHIC':
        return l10n.enumChic;
      default:
        return value;
    }
  }

  String _translateBudgetType(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'BUDGET':
        return l10n.enumBudget;
      case 'PREMIUM':
        return l10n.enumPremium;
      case 'LUXURY':
        return l10n.enumLuxury;
      case 'FLEXIBLE':
        return l10n.enumFlexible;
      default:
        return value;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final l10n = AppLocalizations.of(context)!;
      final data = <String, dynamic>{};

      final fullName = _fullNameController.text.trim();
      if (fullName.isNotEmpty) data['fullName'] = fullName;

      final dob = _selectedDate;
      if (dob != null) {
        data['dateOfBirth'] =
            '${dob.year.toString().padLeft(4, '0')}-'
            '${dob.month.toString().padLeft(2, '0')}-'
            '${dob.day.toString().padLeft(2, '0')}';
      }

      final heightText = _heightController.text.trim();
      if (heightText.isNotEmpty) {
        final h = int.tryParse(heightText);
        if (h != null) data['heightCm'] = h;
      }

      final weightText = _weightController.text.trim();
      if (weightText.isNotEmpty) {
        final w = double.tryParse(weightText);
        if (w != null) data['weightKg'] = w;
      }

      if (_selectedBodyType != null) data['bodyType'] = _selectedBodyType;

      if (_selectedTopSize != null) data['topSize'] = _selectedTopSize;
      if (_selectedBottomSize != null) {
        data['bottomSize'] = _formatPantsSize(_selectedBottomSize);
      }
      if (_selectedDressSize != null) data['dressSize'] = _selectedDressSize;
      if (_selectedJeanWaist != null) {
        data['jeanWaistSize'] = _formatPantsSize(_selectedJeanWaist);
      }
      if (_selectedShoeSize != null) {
        data['shoeSize'] = _formatEuSize(_selectedShoeSize);
      }
      if (_selectedBraBand != null) {
        data['braBandSize'] = _formatEuSize(_selectedBraBand);
      }
      if (_selectedBraCup != null) data['braCupSize'] = _selectedBraCup;

      if (_selectedHijabPreference != null) {
        data['hijabPreference'] = _selectedHijabPreference;
      }
      if (_selectedFitPreference.isNotEmpty) {
        data['fitPreference'] = _selectedFitPreference;
      }
      if (_selectedStylePreference.isNotEmpty) {
        data['stylePreference'] = _selectedStylePreference;
      }
      if (_selectedStyleCategories.isNotEmpty) {
        data['styleCategories'] = _selectedStyleCategories;
      }
      if (_selectedBudgetType != null) data['budgetType'] = _selectedBudgetType;

      // DEBUG: print exact request body
      debugPrint('UPDATE PROFILE REQUEST BODY: ${jsonEncode(data)}');

      await getIt<ProfileService>().updateProfile(data);

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, l10n.profileUpdatedSuccess);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(context, l10n.saveInfoError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.editProfile,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                  )
                : Text(
                    l10n.save,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Personal Information Section
              _buildSection(
                context: context,
                title: l10n.personal,
                children: [
                  _buildTextField(
                    context: context,
                    label: l10n.fullName,
                    controller: _fullNameController,
                    hintText: l10n.enterYourName,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
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
                            if (v.length == 2) {
                              FocusScope.of(context).requestFocus(_monthFocus);
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
                            if (v.length == 2) {
                              FocusScope.of(context).requestFocus(_yearFocus);
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

              const SizedBox(height: 16),

              // Body Information Section
              _buildSection(
                context: context,
                title: l10n.bodyInformation,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          context: context,
                          label: '${l10n.height} (cm)',
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final n = int.tryParse(v);
                            if (n == null || n < 100 || n > 250) {
                              return '100–250';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          context: context,
                          label: '${l10n.weight} (kg)',
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                            ),
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final n = double.tryParse(v);
                            if (n == null || n < 30 || n > 300) {
                              return '30–300';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context, l10n.bodyType),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _bodyTypes,
                    selected: _selectedBodyType != null
                        ? [_selectedBodyType!]
                        : [],
                    multiSelect: false,
                    labelBuilder: (v) => _translateBodyType(context, v),
                    onToggle: (v) => setState(() => _selectedBodyType = v),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Clothing Sizes Section
              _buildSection(
                context: context,
                title: l10n.clothingSizes,
                children: [
                  _buildLabel(context, l10n.topSize),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _topSizes,
                    selected: _selectedTopSize != null
                        ? [_selectedTopSize!]
                        : [],
                    multiSelect: false,
                    labelBuilder: (v) => v,
                    onToggle: (v) => setState(() => _selectedTopSize = v),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context, l10n.bottomSize),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _bottomSizes,
                    selected: _selectedBottomSize != null
                        ? [_selectedBottomSize!]
                        : [],
                    multiSelect: false,
                    labelBuilder: (v) => v,
                    onToggle: (v) => setState(() => _selectedBottomSize = v),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context, l10n.dressSize),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _dressSizes,
                    selected: _selectedDressSize != null
                        ? [_selectedDressSize!]
                        : [],
                    multiSelect: false,
                    labelBuilder: (v) => v,
                    onToggle: (v) => setState(() => _selectedDressSize = v),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context, l10n.jeanWaistSize),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _jeanWaists,
                    selected: _selectedJeanWaist != null
                        ? [_selectedJeanWaist!]
                        : [],
                    multiSelect: false,
                    labelBuilder: (v) => v,
                    onToggle: (v) => setState(() => _selectedJeanWaist = v),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context, l10n.shoeSize),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _shoeSizes,
                    selected: _selectedShoeSize != null
                        ? [_selectedShoeSize!]
                        : [],
                    multiSelect: false,
                    labelBuilder: (v) => v,
                    onToggle: (v) => setState(() => _selectedShoeSize = v),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bra Sizes Section
              _buildSection(
                context: context,
                title: l10n.braSizes,
                children: [
                  _buildLabel(context, l10n.braBandSize),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _braBands,
                    selected: _selectedBraBand != null
                        ? [_selectedBraBand!]
                        : [],
                    multiSelect: false,
                    labelBuilder: (v) => v,
                    onToggle: (v) => setState(() => _selectedBraBand = v),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context, l10n.braCupSize),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _braCups,
                    selected: _selectedBraCup != null ? [_selectedBraCup!] : [],
                    multiSelect: false,
                    labelBuilder: (v) => v,
                    onToggle: (v) => setState(() => _selectedBraCup = v),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Style Preferences Section
              _buildSection(
                context: context,
                title: l10n.stylePreferences,
                children: [
                  _buildLabel(context, l10n.hijabPreference),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _hijabOptions,
                    selected: _selectedHijabPreference != null
                        ? [_selectedHijabPreference!]
                        : [],
                    multiSelect: false,
                    labelBuilder: (v) => _translateHijabOption(context, v),
                    onToggle: (v) =>
                        setState(() => _selectedHijabPreference = v),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context, l10n.fitPreference),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _fitOptions,
                    selected: _selectedFitPreference,
                    multiSelect: true,
                    labelBuilder: (v) => _translateFitOption(context, v),
                    onToggle: (v) {
                      setState(() {
                        if (_selectedFitPreference.contains(v)) {
                          _selectedFitPreference.remove(v);
                        } else {
                          _selectedFitPreference.add(v);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context, l10n.stylePreferenceLabel),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _stylePreferenceOptions,
                    selected: _selectedStylePreference,
                    multiSelect: true,
                    labelBuilder: (v) => _translateStylePreference(context, v),
                    onToggle: (v) {
                      setState(() {
                        if (_selectedStylePreference.contains(v)) {
                          _selectedStylePreference.remove(v);
                        } else {
                          _selectedStylePreference.add(v);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context, l10n.styleCategories),
                  const SizedBox(height: 8),
                  _buildOptionChips(
                    context: context,
                    options: _styleCategoryOptions,
                    selected: _selectedStyleCategories,
                    multiSelect: true,
                    labelBuilder: (v) => _translateStyleCategory(context, v),
                    onToggle: (v) {
                      setState(() {
                        if (_selectedStyleCategories.contains(v)) {
                          _selectedStyleCategories.remove(v);
                        } else {
                          _selectedStyleCategories.add(v);
                        }
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Budget Section
              _buildSection(
                context: context,
                title: l10n.budgetType,
                children: [
                  _buildOptionChips(
                    context: context,
                    options: _budgetTypes,
                    selected: _selectedBudgetType != null
                        ? [_selectedBudgetType!]
                        : [],
                    multiSelect: false,
                    labelBuilder: (v) => _translateBudgetType(context, v),
                    onToggle: (v) => setState(() => _selectedBudgetType = v),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkCardBackground : AppColors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      text,
      style: AppTypography.body2.copyWith(
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkPrimaryText : AppColors.black,
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          validator: validator,
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.body1.copyWith(
              color: isDark
                  ? AppColors.darkPlaceholderText
                  : AppColors.placeholderText,
            ),
            filled: true,
            fillColor: isDark ? AppColors.gray800 : AppColors.gray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppColors.white : AppColors.black,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionChips({
    required BuildContext context,
    required List<String> options,
    required List<String> selected,
    required bool multiSelect,
    required String Function(String) labelBuilder,
    required void Function(String) onToggle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () {
            if (!multiSelect && isSelected)
              return; // don't deselect in single mode
            onToggle(option);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.white : AppColors.black)
                  : (isDark ? AppColors.gray800 : AppColors.white),
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.white : AppColors.black)
                    : (isDark
                          ? AppColors.darkStandardBorder
                          : AppColors.gray300),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              labelBuilder(option),
              style: AppTypography.body2.copyWith(
                color: isSelected
                    ? (isDark ? AppColors.black : AppColors.white)
                    : (isDark ? AppColors.darkPrimaryText : AppColors.black),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RangeInputFormatter extends TextInputFormatter {
  _RangeInputFormatter({
    required this.min,
    required this.max,
    required this.fullLength,
  });

  final int min;
  final int max;
  final int fullLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null) return oldValue;
    if (newValue.text.length == fullLength && (n < min || n > max)) {
      return oldValue;
    }
    return newValue;
  }
}
