import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/constants/countries.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Searchable modal bottom sheet for choosing a phone [Country].
///
/// Usage:
/// ```dart
/// final country = await CountryCodePicker.show(context, selected: current);
/// if (country != null) setState(() => _selectedCountry = country);
/// ```
class CountryCodePicker extends StatefulWidget {
  final Country? selected;

  const CountryCodePicker({super.key, this.selected});

  /// Opens the picker and resolves to the chosen [Country], or null if
  /// dismissed.
  static Future<Country?> show(BuildContext context, {Country? selected}) {
    return showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CountryCodePicker(selected: selected),
    );
  }

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  final _searchController = TextEditingController();
  List<Country> _results = Countries.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _results = Countries.search(query));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCardBackground : AppColors.white;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.black;
    final secondaryText =
        isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final border =
        isDark ? AppColors.darkStandardBorder : AppColors.standardBorder;

    // Leave room for the keyboard when the search field is focused.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Grab handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.selectCountry,
                    style: AppTypography.heading3.copyWith(color: primaryText),
                  ),
                ),
                const SizedBox(height: 12),
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    onChanged: _onSearchChanged,
                    style: AppTypography.body1.copyWith(color: primaryText),
                    decoration: InputDecoration(
                      hintText: l10n.searchCountry,
                      hintStyle: AppTypography.body1.copyWith(
                        color: isDark
                            ? AppColors.darkPlaceholderText
                            : AppColors.placeholderText,
                      ),
                      prefixIcon: Icon(Icons.search, color: secondaryText),
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkMainBackground
                          : AppColors.gray100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryText, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: border),
                // Results
                Expanded(
                  child: _results.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noResultsFound,
                            style: AppTypography.body1.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final country = _results[index];
                            final isSelected =
                                country == widget.selected;
                            return InkWell(
                              onTap: () =>
                                  Navigator.of(context).pop(country),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.darkMainBackground
                                        : AppColors.gray100)
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    Text(
                                      country.flag,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        country.name,
                                        style: AppTypography.body1.copyWith(
                                          color: primaryText,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      country.dialCode,
                                      style: AppTypography.body1.copyWith(
                                        color: secondaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 10),
                                      Icon(
                                        Icons.check,
                                        size: 20,
                                        color: primaryText,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
