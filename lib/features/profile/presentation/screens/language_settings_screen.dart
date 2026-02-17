import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/app/app.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Language Settings Screen
/// Allows user to change app language
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final LanguageService _languageService = LanguageService();
  String _selectedLanguage = 'en';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final currentLang = await _languageService.getCurrentLanguageCode();
    if (mounted) {
      setState(() {
        _selectedLanguage = currentLang;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() {
      _isLoading = true;
    });

    // Save language
    await _languageService.saveLanguage(languageCode);

    // Update app locale
    final locale = Locale(languageCode);
    final appState = context.findAncestorStateOfType<SwipeAppState>();
    appState?.setLocale(locale);

    if (mounted) {
      setState(() {
        _selectedLanguage = languageCode;
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getSuccessMessage(languageCode)),
          backgroundColor: AppColors.black,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getSuccessMessage(String code) {
    switch (code) {
      case 'en':
        return 'Language changed to English';
      case 'ru':
        return 'Язык изменен на Русский';
      case 'uz':
        return 'Til O\'zbekchaga o\'zgartirildi';
      default:
        return 'Language changed';
    }
  }

  String _getFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'ru':
        return '🇷🇺';
      case 'uz':
        return '🇺🇿';
      default:
        return '🌐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.language,
          style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.black),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Language Options
                ...LanguageService.availableLanguages.map((lang) {
                  final code = lang['code']!;
                  final name = lang['name']!;
                  final nativeName = lang['nativeName']!;
                  final isSelected = code == _selectedLanguage;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.black : AppColors.gray300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _changeLanguage(code),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Flag
                              Text(
                                _getFlag(code),
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 16),

                              // Language Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nativeName,
                                      style: AppTypography.body1.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      name,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Checkmark
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}
