import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/constants/app_constants.dart';

/// Local Storage Helper - Manages app data in SharedPreferences
class LocalStorageHelper {
  LocalStorageHelper._();

  static LocalStorageHelper? _instance;
  static SharedPreferences? _preferences;

  /// Get singleton instance
  static Future<LocalStorageHelper> getInstance() async {
    _instance ??= LocalStorageHelper._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // ============== Onboarding ==============

  /// Check if user has completed onboarding
  Future<bool> isOnboarded() async {
    return _preferences?.getBool(AppConstants.isOnboardedKey) ?? false;
  }

  /// Mark onboarding as completed
  Future<bool> setOnboarded(bool value) async {
    return await _preferences?.setBool(AppConstants.isOnboardedKey, value) ??
        false;
  }

  /// Clear onboarding status (for testing/logout)
  Future<bool> clearOnboarding() async {
    return await _preferences?.remove(AppConstants.isOnboardedKey) ?? false;
  }

  // ============== User Authentication ==============

  /// Save user token
  Future<bool> saveUserToken(String token) async {
    return await _preferences?.setString(AppConstants.userTokenKey, token) ??
        false;
  }

  /// Get user token
  String? getUserToken() {
    return _preferences?.getString(AppConstants.userTokenKey);
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    final token = getUserToken();
    return token != null && token.isNotEmpty;
  }

  /// Save user ID
  Future<bool> saveUserId(String userId) async {
    return await _preferences?.setString(AppConstants.userIdKey, userId) ??
        false;
  }

  /// Get user ID
  String? getUserId() {
    return _preferences?.getString(AppConstants.userIdKey);
  }

  /// Clear auth data (logout)
  Future<bool> clearAuthData() async {
    final tokenCleared =
        await _preferences?.remove(AppConstants.userTokenKey) ?? false;
    final userIdCleared =
        await _preferences?.remove(AppConstants.userIdKey) ?? false;
    return tokenCleared && userIdCleared;
  }

  // ============== User Profile Data ==============

  /// Save user profile as JSON string
  Future<bool> saveUserProfile(String profileJson) async {
    return await _preferences?.setString(
          AppConstants.userProfileKey,
          profileJson,
        ) ??
        false;
  }

  /// Get user profile JSON
  String? getUserProfile() {
    return _preferences?.getString(AppConstants.userProfileKey);
  }

  // ============== Theme ==============

  /// Save theme mode ('light', 'dark', 'system')
  Future<bool> saveThemeMode(String themeMode) async {
    return await _preferences?.setString(AppConstants.themeKey, themeMode) ??
        false;
  }

  /// Get theme mode
  String getThemeMode() {
    return _preferences?.getString(AppConstants.themeKey) ?? 'light';
  }

  // ============== App Settings ==============

  /// Save any string value
  Future<bool> setString(String key, String value) async {
    return await _preferences?.setString(key, value) ?? false;
  }

  /// Get string value
  String? getString(String key) {
    return _preferences?.getString(key);
  }

  /// Save any boolean value
  Future<bool> setBool(String key, bool value) async {
    return await _preferences?.setBool(key, value) ?? false;
  }

  /// Get boolean value
  bool getBool(String key, {bool defaultValue = false}) {
    return _preferences?.getBool(key) ?? defaultValue;
  }

  /// Save any integer value
  Future<bool> setInt(String key, int value) async {
    return await _preferences?.setInt(key, value) ?? false;
  }

  /// Get integer value
  int getInt(String key, {int defaultValue = 0}) {
    return _preferences?.getInt(key) ?? defaultValue;
  }

  /// Save any double value
  Future<bool> setDouble(String key, double value) async {
    return await _preferences?.setDouble(key, value) ?? false;
  }

  /// Get double value
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _preferences?.getDouble(key) ?? defaultValue;
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    return await _preferences?.remove(key) ?? false;
  }

  /// Clear all data (full app reset)
  Future<bool> clearAll() async {
    return await _preferences?.clear() ?? false;
  }

  /// Check if key exists
  bool containsKey(String key) {
    return _preferences?.containsKey(key) ?? false;
  }

  // ============== Tutorial/First Time Flags ==============

  /// Mark tutorial as completed
  Future<bool> setTutorialCompleted(bool value) async {
    return await setBool('tutorial_completed', value);
  }

  /// Check if tutorial was completed
  bool isTutorialCompleted() {
    return getBool('tutorial_completed');
  }

  // ============== Quick Access Methods ==============

  /// Get full user state (for debugging)
  Map<String, dynamic> getUserState() {
    return {
      'isOnboarded': isOnboarded(),
      'isLoggedIn': isLoggedIn(),
      'userId': getUserId(),
      'hasProfile': getUserProfile() != null,
      'themeMode': getThemeMode(),
    };
  }
}
