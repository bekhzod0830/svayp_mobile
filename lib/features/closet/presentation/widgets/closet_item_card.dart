import 'dart:io';
import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/closet/data/models/closet_item_model.dart';
import 'package:swipe/l10n/app_localizations.dart';

String _localizeCategory(ClosetCategory cat, AppLocalizations l10n) =>
    switch (cat) {
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

class ClosetItemCard extends StatelessWidget {
  final ClosetItemModel item;
  final VoidCallback? onDelete;

  const ClosetItemCard({super.key, required this.item, this.onDelete});

  void _showActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    title: Text(
                      l10n.deleteItemConfirm,
                      style: AppTypography.body1.copyWith(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete?.call();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : AppColors.gray600,
                    ),
                    title: Text(l10n.cancel, style: AppTypography.body1),
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            item.isLocalFile
                ? Image.file(File(item.imagePath), fit: BoxFit.cover)
                : Image.network(
                    item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color:
                          isDark ? AppColors.gray800 : AppColors.gray100,
                      child: Center(
                        child: Icon(
                          item.category.icon,
                          size: 32,
                          color: isDark
                              ? AppColors.gray600
                              : AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
            // Category badge
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _localizeCategory(item.category, l10n),
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
