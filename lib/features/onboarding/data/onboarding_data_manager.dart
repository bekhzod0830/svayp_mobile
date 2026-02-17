import 'package:flutter/foundation.dart';
import 'package:swipe/features/profile/data/models/profile_models.dart';

/// Onboarding Data Manager
/// Collects user data throughout the onboarding flow
/// Data is submitted to backend after all screens are completed
class OnboardingDataManager extends ChangeNotifier {
  // Basic Info
  String? _fullName;
  String? _email;
  String? _gender;
  DateTime? _dateOfBirth;

  // Body Measurements
  int? _heightCm;
  double? _weightKg;
  String? _bodyType;

  // Clothing Sizes
  String? _topSize;
  String? _bottomSize;
  String? _dressSize;
  String? _jeanWaistSize;
  String? _shoeSize;

  // Bra Sizes
  String? _braType;
  String? _braBandSize;
  String? _braCupSize;
  String? _braSupportLevel;

  // Muslim Fashion Preferences
  String? _hijabPreference;
  List<String> _fitPreference = []; // Changed to list for multiple selections
  List<String> _stylePreference = []; // Added: revealing, covered, or both

  // Style Preferences
  String? _primaryObjective;
  List<String> _styleCategories = [];
  List<String> _occasionPreference = []; // Added: occasions user dresses for
  List<String> _brandPreference = []; // Added: preferred brands
  List<String> _preferredColors = [];
  List<String> _avoidedColors = [];
  List<String> _avoidedPatterns = [];
  List<String> _avoidedItems = [];

  // Budget
  String? _budgetType;

  // Style Quiz Results
  List<Map<String, dynamic>> _quizResults = [];

  // Getters
  String? get fullName => _fullName;
  String? get email => _email;
  String? get gender => _gender;
  DateTime? get dateOfBirth => _dateOfBirth;
  int? get heightCm => _heightCm;
  double? get weightKg => _weightKg;
  String? get bodyType => _bodyType;
  String? get topSize => _topSize;
  String? get bottomSize => _bottomSize;
  String? get dressSize => _dressSize;
  String? get jeanWaistSize => _jeanWaistSize;
  String? get shoeSize => _shoeSize;
  String? get braType => _braType;
  String? get braBandSize => _braBandSize;
  String? get braCupSize => _braCupSize;
  String? get braSupportLevel => _braSupportLevel;
  String? get hijabPreference => _hijabPreference;
  List<String> get fitPreference => _fitPreference;
  List<String> get stylePreference => _stylePreference;
  String? get primaryObjective => _primaryObjective;
  List<String> get styleCategories => _styleCategories;
  List<String> get occasionPreference => _occasionPreference;
  List<String> get brandPreference => _brandPreference;
  List<String> get preferredColors => _preferredColors;
  List<String> get avoidedColors => _avoidedColors;
  List<String> get avoidedPatterns => _avoidedPatterns;
  List<String> get avoidedItems => _avoidedItems;
  String? get budgetType => _budgetType;
  List<Map<String, dynamic>> get quizResults => _quizResults;

  // Setters
  void setBasicInfo({
    String? fullName,
    String? email,
    required String gender,
    required DateTime dateOfBirth,
  }) {
    _fullName = fullName;
    _email = email;
    _gender = gender;
    _dateOfBirth = dateOfBirth;
    notifyListeners();
  }

  void setBodyMeasurements({
    required int heightCm,
    required double weightKg,
    required String bodyType,
  }) {
    _heightCm = heightCm;
    _weightKg = weightKg;
    _bodyType = bodyType;
    notifyListeners();
  }

  void setClothingSizes({
    String? topSize,
    String? bottomSize,
    String? dressSize,
    String? jeanWaistSize,
    String? shoeSize,
    String? braType,
    String? braBandSize,
    String? braCupSize,
    String? braSupportLevel,
  }) {
    _topSize = topSize;
    // Handle both String and potential int values for migration
    _bottomSize = bottomSize;
    _dressSize = dressSize;
    _jeanWaistSize = jeanWaistSize;
    _shoeSize = shoeSize;
    _braType = braType;
    _braBandSize = braBandSize;
    _braCupSize = braCupSize;
    _braSupportLevel = braSupportLevel;
    notifyListeners();
  }

  void setHijabPreference(String preference) {
    _hijabPreference = preference;
    notifyListeners();
  }

  void setFitPreference(List<String> preferences) {
    _fitPreference = preferences;
    notifyListeners();
  }

  void setStylePreference(List<String> preferences) {
    _stylePreference = preferences;
    notifyListeners();
  }

  void setPrimaryObjective(String objective) {
    _primaryObjective = objective;
    notifyListeners();
  }

  void setStyleCategories(List<String> categories) {
    _styleCategories = categories;
    notifyListeners();
  }

  void setOccasionPreference(List<String> occasions) {
    _occasionPreference = occasions;
    notifyListeners();
  }

  void setBrandPreference(List<String> brands) {
    _brandPreference = brands;
    notifyListeners();
  }

  void setPreferredColors(List<String> colors) {
    _preferredColors = colors;
    notifyListeners();
  }

  void setAvoidedColors(List<String> colors) {
    _avoidedColors = colors;
    notifyListeners();
  }

  void setAvoidedPatterns(List<String> patterns) {
    _avoidedPatterns = patterns;
    notifyListeners();
  }

  void setAvoidedItems(List<String> items) {
    _avoidedItems = items;
    notifyListeners();
  }

  void setBudgetType(String? budgetType) {
    _budgetType = budgetType;
    notifyListeners();
  }

  void addQuizResult({required String productId, required String action}) {
    _quizResults.add({'productId': productId, 'action': action});
    notifyListeners();
  }

  void setQuizResults(List<Map<String, dynamic>> results) {
    _quizResults = results;
    notifyListeners();
  }

  /// Convert collected data to ProfileCreateRequest format
  ProfileCreateRequest toProfileRequest() {
    // Ensure stylePreference is never empty (API requires at least 1 item)
    final stylePrefs = _stylePreference.isNotEmpty
        ? _stylePreference.map((e) => e.toUpperCase()).toList()
        : _getDefaultStylePreference();

    return ProfileCreateRequest(
      // Required fields - convert enums to UPPERCASE
      gender: _gender!.toUpperCase(),
      dateOfBirth: _dateOfBirth!.toIso8601String().split('T')[0],
      heightCm: _heightCm!,
      weightKg: _weightKg!,
      bodyType: _bodyType!.toUpperCase(),

      // Optional personal info
      fullName: _fullName,
      email: _email,

      // Optional sizes - convert to UPPERCASE
      topSize: _topSize?.toUpperCase(),
      bottomSize: _formatPantsSize(_bottomSize),
      dressSize: _dressSize?.toUpperCase(),
      jeanWaistSize: _formatPantsSize(_jeanWaistSize),
      shoeSize: _formatShoeSize(_shoeSize),

      // Bra sizes - convert to UPPERCASE
      braType: _braType?.toUpperCase(),
      braBandSize: _formatBraBandSize(_braBandSize),
      braCupSize: _braCupSize?.toUpperCase(),
      braSupportLevel: _braSupportLevel?.toUpperCase(),

      // Muslim fashion preferences - convert to UPPERCASE
      hijabPreference: _hijabPreference!.toUpperCase(),
      fitPreference: _fitPreference.isNotEmpty
          ? _fitPreference.map((e) => e.toUpperCase()).toList()
          : [],
      stylePreference: stylePrefs, // Use computed stylePrefs with fallback
      // Style preferences - convert to UPPERCASE
      primaryObjective: _primaryObjective?.toUpperCase(),
      styleCategories: _styleCategories.isNotEmpty
          ? _styleCategories.map((e) => e.toUpperCase()).toList()
          : null,
      occasionPreference: _occasionPreference.isNotEmpty
          ? _occasionPreference.map((e) => e.toUpperCase()).toList()
          : null,
      brandPreference: _brandPreference.isNotEmpty ? _brandPreference : null,
      preferredColors: _preferredColors.isNotEmpty ? _preferredColors : null,
      avoidedColors: _avoidedColors.isNotEmpty ? _avoidedColors : null,
      avoidedPatterns: _avoidedPatterns.isNotEmpty
          ? _avoidedPatterns.map((e) => e.toUpperCase()).toList()
          : null,
      avoidedItems: _avoidedItems.isNotEmpty
          ? _avoidedItems.map((e) => e.toUpperCase()).toList()
          : null,

      // Budget - convert to UPPERCASE
      budgetType: _budgetType?.toUpperCase(),
    );
  }

  /// Check if required fields are filled
  bool get hasRequiredFields {
    return _gender != null &&
        _dateOfBirth != null &&
        _heightCm != null &&
        _weightKg != null &&
        _bodyType != null;
  }

  /// Reset all data
  void reset() {
    _fullName = null;
    _email = null;
    _gender = null;
    _dateOfBirth = null;
    _heightCm = null;
    _weightKg = null;
    _bodyType = null;
    _topSize = null;
    _bottomSize = null;
    _dressSize = null;
    _jeanWaistSize = null;
    _shoeSize = null;
    _braType = null;
    _braBandSize = null;
    _braCupSize = null;
    _braSupportLevel = null;
    _hijabPreference = null;
    _fitPreference = [];
    _stylePreference = [];
    _occasionPreference = [];
    _brandPreference = [];
    _primaryObjective = null;
    _styleCategories = [];
    _preferredColors = [];
    _avoidedColors = [];
    _avoidedPatterns = [];
    _avoidedItems = [];
    _budgetType = null;
    _quizResults = [];
    notifyListeners();
  }

  /// Format pants size: "24" -> "SIZE_24"
  String? _formatPantsSize(String? size) {
    if (size == null) return null;
    // If already formatted, return as-is
    if (size.startsWith('SIZE_')) return size.toUpperCase();
    // Format numeric size
    return 'SIZE_$size';
  }

  /// Format shoe size: "37" -> "EU_37"
  String? _formatShoeSize(String? size) {
    if (size == null) return null;
    // If already formatted, return as-is
    if (size.startsWith('EU_')) return size.toUpperCase();
    // Format numeric size
    return 'EU_$size';
  }

  /// Format bra band size: "70" -> "EU_70"
  String? _formatBraBandSize(String? size) {
    if (size == null) return null;
    // If already formatted, return as-is
    if (size.startsWith('EU_')) return size.toUpperCase();
    // Format numeric size
    return 'EU_$size';
  }

  /// Get default style preference based on hijab preference
  List<String> _getDefaultStylePreference() {
    final hijabPref = _hijabPreference?.toLowerCase();

    if (hijabPref == 'covered') {
      return ['COVERED'];
    } else if (hijabPref == 'uncovered') {
      return ['MODERATE']; // or ['REVEALING'] depending on your app's default
    } else if (hijabPref == 'not_applicable') {
      return ['MODERATE'];
    }

    // Fallback if hijabPreference is somehow null or unexpected
    return ['COVERED'];
  }
}
