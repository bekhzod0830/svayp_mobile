import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:swipe/core/localization/models/language_model.dart';

/// Language Service - Manages app language selection and persistence
class LanguageService {
  static const String _boxName = 'language';
  static const String _languageKey = 'selected_language';

  Box<LanguageModel>? _box;

  /// Available languages
  static const List<Map<String, String>> availableLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский'},
    {'code': 'uz', 'name': 'Uzbek', 'nativeName': 'O\'zbekcha'},
  ];

  /// Initialize Hive box
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<LanguageModel>(_boxName);
    }
  }

  /// Get current language
  Future<Locale> getCurrentLanguage() async {
    await init();

    final languageModel = _box?.get(_languageKey);
    if (languageModel != null) {
      return Locale(languageModel.languageCode);
    }

    // Default to Russian
    return const Locale('ru');
  }

  /// Get current language code
  Future<String> getCurrentLanguageCode() async {
    await init();

    final languageModel = _box?.get(_languageKey);
    return languageModel?.languageCode ?? 'ru';
  }

  /// Save selected language
  Future<void> saveLanguage(String languageCode) async {
    await init();

    final languageName = availableLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => availableLanguages[0],
    )['nativeName']!;

    final languageModel = LanguageModel(
      languageCode: languageCode,
      languageName: languageName,
    );

    await _box?.put(_languageKey, languageModel);
  }

  /// Check if language is selected
  Future<bool> isLanguageSelected() async {
    await init();
    return _box?.get(_languageKey) != null;
  }

  /// Clear language selection
  Future<void> clearLanguage() async {
    await init();
    await _box?.delete(_languageKey);
  }

  /// Get locale from language code
  Locale getLocaleFromCode(String code) {
    return Locale(code);
  }

  /// Get language name from code
  String getLanguageName(String code) {
    return availableLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => availableLanguages[0],
    )['nativeName']!;
  }
}
