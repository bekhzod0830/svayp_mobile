import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/app/app.dart';

/// Language Selector Widget
/// Shows a dropdown to select language
class LanguageSelector extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final bool showLabel;

  const LanguageSelector({
    super.key,
    this.onLanguageChanged,
    this.showLabel = true,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final LanguageService _languageService = LanguageService();
  String _selectedLanguage = 'en';

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
      });
    }
  }

  Future<void> _changeLanguage(String? languageCode) async {
    if (languageCode == null) return;

    setState(() {
      _selectedLanguage = languageCode;
    });

    // Save language
    await _languageService.saveLanguage(languageCode);

    // Update app locale
    final locale = Locale(languageCode);
    final appState = context.findAncestorStateOfType<SwipeAppState>();
    appState?.setLocale(locale);

    // Callback
    widget.onLanguageChanged?.call(locale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          Text(
            l10n.selectLanguage,
            style: AppTypography.body2.copyWith(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
              style: AppTypography.body1.copyWith(
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
              dropdownColor: isDark
                  ? AppColors.darkCardBackground
                  : AppColors.white,
              items: LanguageService.availableLanguages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang['code'],
                  child: Row(
                    children: [
                      Text(
                        _getFlag(lang['code']!),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(lang['nativeName']!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _changeLanguage,
            ),
          ),
        ),
      ],
    );
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
}
