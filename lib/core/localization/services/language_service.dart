import 'dart:ui' show PlatformDispatcher;

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

  /// Locale codes we ship translations for.
  static const List<String> supportedCodes = ['en', 'ru', 'uz'];

  /// Fallback used on first launch when the device locale isn't supported.
  static const String defaultLanguageCode = 'uz';

  /// First-launch language: the device/phone locale when it's one we support,
  /// otherwise Uzbek. Synchronous so it can seed the initial app locale.
  ///
  /// The same resolution feeds the web view (via the `lang` query param), so
  /// both surfaces start on the same language.
  static String resolveDeviceLanguageCode() {
    final deviceCode =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return supportedCodes.contains(deviceCode)
        ? deviceCode
        : defaultLanguageCode;
  }

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

    // First launch — follow the device locale (Uzbek fallback).
    return Locale(resolveDeviceLanguageCode());
  }

  /// Get current language code
  Future<String> getCurrentLanguageCode() async {
    await init();

    final languageModel = _box?.get(_languageKey);
    return languageModel?.languageCode ?? resolveDeviceLanguageCode();
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
