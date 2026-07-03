import 'dart:io';
import 'package:flutter/material.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/features/closet/data/models/closet_item_model.dart';
import 'package:swipe/features/closet/data/services/closet_service.dart';
import 'package:swipe/l10n/app_localizations.dart';

class AddClosetItemScreen extends StatefulWidget {
  final File imageFile;
  final ClosetCategory? initialCategory;
  final List<ClosetCategory>? allowedCategories;

  const AddClosetItemScreen({
    super.key,
    required this.imageFile,
    this.initialCategory,
    this.allowedCategories,
  });

  @override
  State<AddClosetItemScreen> createState() => _AddClosetItemScreenState();
}

class _AddClosetItemScreenState extends State<AddClosetItemScreen> {
  ClosetCategory? _selectedCategory;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  Future<void> _save() async {
    if (_selectedCategory == null) return;
    setState(() => _saving = true);
    try {
      await getIt<ClosetService>().addItem(
        imageFile: widget.imageFile,
        category: _selectedCategory!,
      );
      AnalyticsService.instance.logEvent(
        AnalyticsEvents.closetItemAdded,
        parameters: {AnalyticsEvents.paramCategory: _selectedCategory!.name},
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final canSave = _selectedCategory != null && !_saving;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkPageBackground
          : AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Simple header — no cart/liked icons
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      l10n.newItem,
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category label
                    Text(
                      '${l10n.selectCategory} *',
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category chips
                    _CategoryPicker(
                      selected: _selectedCategory,
                      allowedCategories: widget.allowedCategories,
                      isDark: isDark,
                      l10n: l10n,
                      onSelect: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ],
                ),
              ),
            ),

            // Save button
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewPadding.bottom + 16,
              ),
              child: GestureDetector(
                onTap: canSave ? _save : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: canSave
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.white24 : AppColors.gray200),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _saving
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          l10n.save,
                          textAlign: TextAlign.center,
                          style: AppTypography.body1.copyWith(
                            fontWeight: FontWeight.w700,
                            color: canSave
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark
                                    ? Colors.white38
                                    : AppColors.gray500),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Picker ──────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final ClosetCategory? selected;
  final List<ClosetCategory>? allowedCategories;
  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<ClosetCategory> onSelect;

  const _CategoryPicker({
    required this.selected,
    this.allowedCategories,
    required this.isDark,
    required this.l10n,
    required this.onSelect,
  });

  String _label(ClosetCategory cat) => switch (cat) {
        ClosetCategory.tops => l10n.categoryTops,
        ClosetCategory.dresses => l10n.categoryDresses,
        ClosetCategory.jackets => l10n.categoryJackets,
        ClosetCategory.blouses => l10n.categoryBlouses,
        ClosetCategory.jumpsuits => l10n.categoryJumpsuits,
        ClosetCategory.tshirts => l10n.categoryTshirts,
        ClosetCategory.skirts => l10n.categorySkirts,
        ClosetCategory.jeans => l10n.categoryJeans,
        ClosetCategory.pants => l10n.categoryPants,
        ClosetCategory.shorts => l10n.categoryShorts,
        ClosetCategory.shoes => l10n.categoryShoes,
        ClosetCategory.accessories => l10n.categoryAccessories,
        ClosetCategory.bags => l10n.categoryBags,
        ClosetCategory.shawl => l10n.categoryShawl,
        ClosetCategory.jewelry => l10n.categoryJewelry,
        ClosetCategory.underwear => l10n.categoryUnderwear,
      };

  @override
  Widget build(BuildContext context) {
    final cats = allowedCategories ?? ClosetCategory.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cats.map((cat) {
        final isSelected = cat == selected;
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.20)
                        : Colors.black.withValues(alpha: 0.12)),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat.icon,
                  size: 16,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white60 : AppColors.gray600),
                ),
                const SizedBox(width: 6),
                Text(
                  _label(cat),
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}


