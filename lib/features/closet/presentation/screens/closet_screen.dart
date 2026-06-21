import 'dart:io';
import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/features/closet/data/models/closet_item_model.dart';
import 'package:swipe/features/closet/data/services/closet_service.dart';
import 'package:swipe/features/closet/presentation/screens/add_closet_item_screen.dart';
import 'package:swipe/features/closet/presentation/widgets/closet_image_picker_sheet.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/shared/widgets/main_top_bar.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────

const _kWarmBg = Colors.white;
const _kCardBg = Color(0xFFF3F3F3);
const _kPinkAccent = Color(0xFFFF6B9D);
const _kPurpleAccent = Color(0xFFB57BFF);
const _kChipSelected = Color(0xFFEEEEEE);
const _kChipBorder = Color(0xFFE0E0E0);
const _kOutfitCardBg = Color(0xFFF5F5F5);

// ─── Category Groups ──────────────────────────────────────────────────────────
const _upperCats = [
  ClosetCategory.tops,
  ClosetCategory.dresses,
  ClosetCategory.jackets,
  ClosetCategory.blouses,
  ClosetCategory.jumpsuits,
  ClosetCategory.tshirts,
];
const _lowerCats = [
  ClosetCategory.skirts,
  ClosetCategory.jeans,
  ClosetCategory.pants,
  ClosetCategory.shorts,
];
const _shoesCats = [ClosetCategory.shoes];
const _accCats = [
  ClosetCategory.accessories,
  ClosetCategory.bags,
  ClosetCategory.shawl,
  ClosetCategory.jewelry,
  ClosetCategory.underwear,
];

String _catLabel(ClosetCategory cat, AppLocalizations l10n) => switch (cat) {
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

// ─── Screen ───────────────────────────────────────────────────────────────────

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  List<ClosetItemModel> _allItems = [];
  ClosetCategory? _upperFilter;
  ClosetCategory? _lowerFilter;
  ClosetCategory? _accFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await getIt<ClosetService>().listItems();
      if (mounted) setState(() { _allItems = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ClosetItemModel> _itemsFor(
    List<ClosetCategory> cats,
    ClosetCategory? filter,
  ) =>
      _allItems
          .where((item) =>
              cats.contains(item.category) &&
              (filter == null || item.category == filter))
          .toList();

  Future<void> _addItem(ClosetCategory preselect) async {
    final files = await showClosetImagePickerSheet(context);
    if (files == null || files.isEmpty || !mounted) return;
    final allowed = _upperCats.contains(preselect)
        ? _upperCats
        : _lowerCats.contains(preselect)
            ? _lowerCats
            : _shoesCats.contains(preselect)
                ? _shoesCats
                : _accCats;
    bool anyAdded = false;
    for (final file in files) {
      if (!mounted) break;
      final added = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(
          builder: (_) => AddClosetItemScreen(
            imageFile: file,
            initialCategory: preselect,
            allowedCategories: allowed,
          ),
        ),
      );
      if (added == true) anyAdded = true;
    }
    if (anyAdded) _load();
  }

  Future<void> _deleteItem(String id) async {
    await getIt<ClosetService>().deleteItem(id);
    _load();
  }

  Future<void> _editItem(String id, ClosetCategory newCat) async {
    final idx = _allItems.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final updated = _allItems[idx].copyWith(category: newCat);
    await getIt<ClosetService>().updateItem(updated);
    _load();
  }

  void _showCategoryItems(
      BuildContext context, String title, List<ClosetItemModel> items) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _ItemsViewerSheet(
        title: title,
        items: items,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  void _showOutfitsForPeriod(BuildContext context, String label) {
    final now = DateTime.now();
    final List<DateTime> days;
    final String title;

    switch (label) {
      case 'Today':
        days = [now];
        title = 'Today';
      case 'Weekend':
        days = List.generate(7, (i) => now.add(Duration(days: i)));
        title = 'Next 7 Days';
      case 'Month':
        days = List.generate(30, (i) => now.add(Duration(days: i)));
        title = 'Next 30 Days';
      default:
        days = [now];
        title = label;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _OutfitDaysSheet(
        title: title,
        days: days,
        allItems: _allItems,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final bottomPad = 68.0 + MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPageBackground : _kWarmBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            MainTopBar(title: l10n.closet, showBackButton: false),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white : AppColors.gray600,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: isDark ? Colors.white : AppColors.gray700,
                      child: ListView(
                        padding: EdgeInsets.only(bottom: bottomPad + 24),
                        children: [
                          // ── Style Occasion Cards ─────────────────────────
                          _OutfitCategoryCards(
                            isDark: isDark,
                            onCategoryTap: (label) =>
                                _showOutfitsForPeriod(context, label),
                          ),

                          // ── My Outfits ───────────────────────────────────
                          _OutfitRecommendationSection(
                            allItems: _allItems,
                            isDark: isDark,
                            l10n: l10n,
                          ),

                          // ── Upper Body ───────────────────────────────────
                          _ClothingSection(
                            title: l10n.sectionUpperBody,
                            cats: _upperCats,
                            filter: _upperFilter,
                            items: _itemsFor(_upperCats, _upperFilter),
                            isDark: isDark,
                            l10n: l10n,
                            onFilterChange: (c) =>
                                setState(() => _upperFilter = c),
                            onAdd: () =>
                                _addItem(_upperFilter ?? ClosetCategory.tops),
                            onDelete: _deleteItem,
                            onEdit: _editItem,
                            onViewAll: () => _showCategoryItems(context,
                                l10n.sectionUpperBody, _itemsFor(_upperCats, null)),
                          ),

                          // ── Lower Body ───────────────────────────────────
                          _ClothingSection(
                            title: l10n.sectionLowerBody,
                            cats: _lowerCats,
                            filter: _lowerFilter,
                            items: _itemsFor(_lowerCats, _lowerFilter),
                            isDark: isDark,
                            l10n: l10n,
                            onFilterChange: (c) =>
                                setState(() => _lowerFilter = c),
                            onAdd: () =>
                                _addItem(_lowerFilter ?? ClosetCategory.jeans),
                            onDelete: _deleteItem,
                            onEdit: _editItem,
                            onViewAll: () => _showCategoryItems(context,
                                l10n.sectionLowerBody, _itemsFor(_lowerCats, null)),
                          ),

                          // ── Shoes ─────────────────────────────────────────
                          _ClothingSection(
                            title: l10n.categoryShoes,
                            cats: _shoesCats,
                            filter: null,
                            items: _itemsFor(_shoesCats, null),
                            isDark: isDark,
                            l10n: l10n,
                            onFilterChange: (_) {},
                            onAdd: () => _addItem(ClosetCategory.shoes),
                            onDelete: _deleteItem,
                            onEdit: _editItem,
                            onViewAll: () => _showCategoryItems(context,
                                l10n.categoryShoes, _itemsFor(_shoesCats, null)),
                          ),

                          // ── Accessories ───────────────────────────────────
                          _ClothingSection(
                            title: l10n.categoryAccessories,
                            cats: _accCats,
                            filter: _accFilter,
                            items: _itemsFor(_accCats, _accFilter),
                            isDark: isDark,
                            l10n: l10n,
                            onFilterChange: (c) =>
                                setState(() => _accFilter = c),
                            onAdd: () => _addItem(
                                _accFilter ?? ClosetCategory.accessories),
                            onDelete: _deleteItem,
                            onEdit: _editItem,
                            onViewAll: () => _showCategoryItems(context,
                                l10n.categoryAccessories,
                                _itemsFor(_accCats, null)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Outfit Category Cards ────────────────────────────────────────────────────

class _OutfitCategoryCards extends StatelessWidget {
  final bool isDark;
  final void Function(String label) onCategoryTap;

  const _OutfitCategoryCards({
    required this.isDark,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    const categories = [
      (
        label: 'Today',
        icon: Icons.wb_sunny_outlined,
        iconBg: Color(0xFFFFF3E0),
      ),
      (
        label: 'Weekend',
        icon: Icons.park_outlined,
        iconBg: Color(0xFFE8F5E9),
      ),
      (
        label: 'Month',
        icon: Icons.calendar_month_outlined,
        iconBg: Color(0xFFE3F2FD),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
      child: SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final cat = categories[i];
            return _OutfitCategoryCard(
              label: cat.label,
              icon: cat.icon,
              iconBg: cat.iconBg,
              isDark: isDark,
              onTap: () => onCategoryTap(cat.label),
            );
          },
        ),
      ),
    );
  }
}

class _OutfitCategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconBg;
  final bool isDark;
  final VoidCallback onTap;

  const _OutfitCategoryCard({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 116,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 19,
                color: isDark ? Colors.white70 : AppColors.gray700,
              ),
            ),
            Text(
              label,
              style: AppTypography.body2.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.gray900,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Outfit Recommendation Section ───────────────────────────────────────────

class _OutfitRecommendationSection extends StatelessWidget {
  final List<ClosetItemModel> allItems;
  final bool isDark;
  final AppLocalizations l10n;

  const _OutfitRecommendationSection({
    required this.allItems,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l10n.sectionMyOutfits,
                  style: AppTypography.heading4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.gray900,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'View all',
                  style: AppTypography.body2.copyWith(
                    color: isDark ? Colors.white38 : AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Horizontal scrolling outfit cards with peek effect
          SizedBox(
            height: 368,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: 2,
              itemBuilder: (ctx, index) => Padding(
                padding: EdgeInsets.only(right: index == 1 ? 40 : 12),
                child: SizedBox(
                  width: MediaQuery.of(ctx).size.width * 0.80,
                  child: _OutfitCard(
                    allItems: allItems,
                    isDark: isDark,
                    l10n: l10n,
                    outfitIndex: index,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final List<ClosetItemModel> allItems;
  final bool isDark;
  final AppLocalizations l10n;
  final int outfitIndex;

  const _OutfitCard({
    required this.allItems,
    required this.isDark,
    required this.l10n,
    this.outfitIndex = 0,
  });

  void _openItemsSheet(BuildContext context, List<ClosetItemModel> items) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _ItemsViewerSheet(
        title: 'Outfit Items',
        items: items,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upperAll =
        allItems.where((i) => _upperCats.contains(i.category)).toList();
    final lowerAll =
        allItems.where((i) => _lowerCats.contains(i.category)).toList();
    final shoesAll =
        allItems.where((i) => _shoesCats.contains(i.category)).toList();
    final upper =
        upperAll.isEmpty ? null : upperAll[outfitIndex % upperAll.length];
    final lower =
        lowerAll.isEmpty ? null : lowerAll[outfitIndex % lowerAll.length];
    final shoes =
        shoesAll.isEmpty ? null : shoesAll[outfitIndex % shoesAll.length];
    final outfitItems =
        [upper, lower, shoes].whereType<ClosetItemModel>().toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : _kOutfitCardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar: edit + favorite ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                _CircleActionButton(
                  icon: Icons.edit_outlined,
                  isDark: isDark,
                ),
                const Spacer(),
                _CircleActionButton(
                  icon: Icons.favorite_border_rounded,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // ── Sample look collage (tappable) ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: allItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: isDark ? Colors.white24 : AppColors.gray400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.outfitsNeedMoreItems,
                            textAlign: TextAlign.center,
                            style: AppTypography.body2.copyWith(
                              color:
                                  isDark ? Colors.white38 : AppColors.gray500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () => _openItemsSheet(context, outfitItems),
                    child: SizedBox(
                      height: 196,

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _CollageTile(
                              item: upper,
                              placeholderIcon: Icons.checkroom_outlined,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                Expanded(
                                  child: _CollageTile(
                                    item: lower,
                                    placeholderIcon: Icons.straighten_outlined,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: _CollageTile(
                                    item: shoes,
                                    placeholderIcon:
                                        Icons.directions_walk_outlined,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          const Spacer(),

          // ── Bottom action buttons ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openItemsSheet(context, outfitItems),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          'View items →',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.gray800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kPurpleAccent, _kPinkAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: Center(
                      child: Text(
                        '✨ Try it on',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const _CircleActionButton({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Icon(
        icon,
        size: 15,
        color: isDark ? Colors.white70 : AppColors.gray600,
      ),
    );
  }
}

// ─── Clothing Section ─────────────────────────────────────────────────────────

class _ClothingSection extends StatelessWidget {
  final String title;
  final List<ClosetCategory> cats;
  final ClosetCategory? filter;
  final List<ClosetItemModel> items;
  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<ClosetCategory?> onFilterChange;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final void Function(String id, ClosetCategory newCat) onEdit;
  final VoidCallback onViewAll;

  const _ClothingSection({
    required this.title,
    required this.cats,
    required this.filter,
    required this.items,
    required this.isDark,
    required this.l10n,
    required this.onFilterChange,
    required this.onAdd,
    required this.onDelete,
    required this.onEdit,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final cellCount = items.length + 1; // +1 for add card

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.heading4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.gray900,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    'View all',
                    style: AppTypography.body2.copyWith(
                      color: isDark ? Colors.white38 : AppColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Filter chips ──────────────────────────────────────────────
          if (cats.length > 1) ...[
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: cats.length + 1,
                itemBuilder: (_, i) {
                  final isAll = i == 0;
                  final cat = isAll ? null : cats[i - 1];
                  final isSelected = filter == cat;
                  return GestureDetector(
                    onTap: () => onFilterChange(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : _kChipSelected)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : _kChipBorder),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        isAll ? l10n.all : _catLabel(cat!, l10n),
                        style: AppTypography.caption.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : AppColors.gray900)
                              : (isDark ? Colors.white60 : AppColors.gray600),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Horizontal scroll row ──────────────────────────────────────
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: cellCount,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return SizedBox(
                    width: 120,
                    child: _AddItemCard(isDark: isDark, l10n: l10n, onTap: onAdd),
                  );
                }
                final item = items[i - 1];
                return SizedBox(
                  width: 120,
                  child: _ClothingItemCard(
                    item: item,
                    isDark: isDark,
                    l10n: l10n,
                    allowedCats: cats,
                    onDelete: () => onDelete(item.id),
                    onEdit: (newCat) => onEdit(item.id, newCat),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Item Card ────────────────────────────────────────────────────────────

class _AddItemCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _AddItemCard({
    required this.isDark,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _kPinkAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: _kPinkAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.newItem,
              style: AppTypography.body2.copyWith(
                color: isDark ? Colors.white60 : AppColors.gray600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Clothing Item Card ───────────────────────────────────────────────────────

class _ClothingItemCard extends StatelessWidget {
  final ClosetItemModel item;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onDelete;
  final ValueChanged<ClosetCategory> onEdit;
  final List<ClosetCategory> allowedCats;

  const _ClothingItemCard({
    required this.item,
    required this.isDark,
    required this.l10n,
    required this.onDelete,
    required this.onEdit,
    required this.allowedCats,
  });

  void _showEditSheet(BuildContext context) {
    var selected = item.category;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          final isDarkSheet =
              Theme.of(context).brightness == Brightness.dark;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isDarkSheet ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 4),
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDarkSheet
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      // Image + current category
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: item.isLocalFile
                                    ? Image.file(
                                        File(item.imagePath),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        item.imagePath,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              _catLabel(item.category, l10n),
                              style: AppTypography.body1.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDarkSheet
                                    ? Colors.white
                                    : AppColors.gray900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Category label
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          l10n.selectCategory,
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDarkSheet
                                ? Colors.white70
                                : AppColors.gray700,
                          ),
                        ),
                      ),
                      // Category chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: allowedCats.map((cat) {
                            final isSel = cat == selected;
                            return GestureDetector(
                              onTap: () => setSt(() => selected = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? (isDarkSheet
                                          ? Colors.white
                                              .withValues(alpha: 0.18)
                                          : _kChipSelected)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSel
                                        ? Colors.transparent
                                        : (isDarkSheet
                                            ? Colors.white
                                                .withValues(alpha: 0.18)
                                            : _kChipBorder),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  _catLabel(cat, l10n),
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSel
                                        ? (isDarkSheet
                                            ? Colors.white
                                            : AppColors.gray900)
                                        : (isDarkSheet
                                            ? Colors.white60
                                            : AppColors.gray600),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context,
                                          rootNavigator: true)
                                      .pop();
                                  onDelete();
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.red.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Delete',
                                      style: AppTypography.body2.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context,
                                          rootNavigator: true)
                                      .pop();
                                  if (selected != item.category) {
                                    onEdit(selected);
                                  }
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDarkSheet
                                        ? Colors.white
                                        : Colors.black,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Center(
                                    child: Text(
                                      l10n.save,
                                      style: AppTypography.body2.copyWith(
                                        color: isDarkSheet
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEditSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : _kCardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Image ───────────────────────────────────────────────────
            item.isLocalFile
                ? Image.file(
                    File(item.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _PlaceholderContent(
                      icon: item.category.icon,
                      isDark: isDark,
                    ),
                  )
                : Image.network(
                    item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _PlaceholderContent(
                      icon: item.category.icon,
                      isDark: isDark,
                    ),
                  ),

            // ── Bottom gradient + category label ─────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 32, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.60),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  _catLabel(item.category, l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _PlaceholderContent extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const _PlaceholderContent({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.gray800 : const Color(0xFFE8E3DD),
      child: Center(
        child: Icon(
          icon,
          size: 40,
          color: isDark ? AppColors.gray600 : AppColors.gray400,
        ),
      ),
    );
  }
}

// ─── Collage Tile ─────────────────────────────────────────────────────────────

class _CollageTile extends StatelessWidget {
  final ClosetItemModel? item;
  final IconData placeholderIcon;
  final bool isDark;

  const _CollageTile({
    required this.item,
    required this.placeholderIcon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: item != null ? _image() : _placeholder(),
    );
  }

  Widget _image() {
    return item!.isLocalFile
        ? Image.file(File(item!.imagePath), fit: BoxFit.cover)
        : Image.network(
            item!.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          );
  }

  Widget _placeholder() {
    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFE4DED8),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: 26,
          color: isDark ? Colors.white24 : AppColors.gray400,
        ),
      ),
    );
  }
}

// ─── Outfit Days Sheet ────────────────────────────────────────────────────────

class _OutfitDaysSheet extends StatelessWidget {
  final String title;
  final List<DateTime> days;
  final List<ClosetItemModel> allItems;
  final bool isDark;

  const _OutfitDaysSheet({
    required this.title,
    required this.days,
    required this.allItems,
    required this.isDark,
  });

  ClosetItemModel? _pickItem(List<ClosetItemModel> items, DateTime day) {
    if (items.isEmpty) return null;
    final dayIndex = day.millisecondsSinceEpoch ~/ 86400000;
    return items[dayIndex % items.length];
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.90;
    final upperItems =
        allItems.where((i) => _upperCats.contains(i.category)).toList();
    final lowerItems =
        allItems.where((i) => _lowerCats.contains(i.category)).toList();
    final shoeItems =
        allItems.where((i) => _shoesCats.contains(i.category)).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: height,
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            child: Column(
              children: [
                // ── Drag handle ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 2),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ── Header ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 8, 6),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.heading4.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.gray900,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Day list ───────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: days.length,
                    itemBuilder: (ctx, i) {
                      final day = days[i];
                      return _DayOutfitCard(
                        day: day,
                        upperItem: _pickItem(upperItems, day),
                        lowerItem: _pickItem(lowerItems, day),
                        shoeItem: _pickItem(shoeItems, day),
                        isDark: isDark,
                        isFirst: i == 0,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Day Outfit Card ──────────────────────────────────────────────────────────

class _DayOutfitCard extends StatelessWidget {
  final DateTime day;
  final ClosetItemModel? upperItem;
  final ClosetItemModel? lowerItem;
  final ClosetItemModel? shoeItem;
  final bool isDark;
  final bool isFirst;

  const _DayOutfitCard({
    required this.day,
    required this.upperItem,
    required this.lowerItem,
    required this.shoeItem,
    required this.isDark,
    required this.isFirst,
  });

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
    final dayLabel = isFirst && isToday ? 'Today' : _dayNames[day.weekday - 1];
    final dateStr = '${_monthNames[day.month - 1]} ${day.day}';
    final isEmpty = upperItem == null && lowerItem == null && shoeItem == null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : _kOutfitCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // ── Date label ──────────────────────────────────────────────
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayLabel,
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.gray900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateStr,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white38 : AppColors.gray500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Outfit collage (tappable) ───────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () {
                final outfitItems = [upperItem, lowerItem, shoeItem]
                    .whereType<ClosetItemModel>()
                    .toList();
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  builder: (_) => _ItemsViewerSheet(
                    title: dayLabel,
                    items: outfitItems,
                    isDark: isDark,
                  ),
                );
              },
              child: SizedBox(
                height: 116,
              child: isEmpty
                  ? Center(
                      child: Text(
                        'Add items to your closet',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white38 : AppColors.gray400,
                        ),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Upper body — tall left panel
                        Expanded(
                          flex: 5,
                          child: _MiniCollageTile(
                            item: upperItem,
                            placeholderIcon: Icons.checkroom_outlined,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Lower body + Shoes stacked right
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              Expanded(
                                child: _MiniCollageTile(
                                  item: lowerItem,
                                  placeholderIcon: Icons.straighten_outlined,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: _MiniCollageTile(
                                  item: shoeItem,
                                  placeholderIcon:
                                      Icons.directions_walk_outlined,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Collage Tile ────────────────────────────────────────────────────────

class _MiniCollageTile extends StatelessWidget {
  final ClosetItemModel? item;
  final IconData placeholderIcon;
  final bool isDark;

  const _MiniCollageTile({
    required this.item,
    required this.placeholderIcon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: item != null ? _image() : _placeholder(),
    );
  }

  Widget _image() {
    return item!.isLocalFile
        ? Image.file(File(item!.imagePath), fit: BoxFit.cover)
        : Image.network(
            item!.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          );
  }

  Widget _placeholder() {
    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFE8E8E8),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: 18,
          color: isDark ? Colors.white24 : AppColors.gray400,
        ),
      ),
    );
  }
}

// ─── Items Viewer Sheet ───────────────────────────────────────────────────────

class _ItemsViewerSheet extends StatelessWidget {
  final String title;
  final List<ClosetItemModel> items;
  final bool isDark;

  const _ItemsViewerSheet({
    required this.title,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.80,
            child: Container(
              color: bg,
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 2),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 8, 8),
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: AppTypography.heading4.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.gray900,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color:
                                isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Grid or empty state
                  if (items.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No items',
                          style: AppTypography.body1.copyWith(
                            color:
                                isDark ? Colors.white38 : AppColors.gray400,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          return GestureDetector(
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              useRootNavigator: true,
                              builder: (_) => _ItemDetailSheet(
                                item: item,
                                isDark: isDark,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  item.isLocalFile
                                      ? Image.file(
                                          File(item.imagePath),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          item.imagePath,
                                          fit: BoxFit.cover,
                                        ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 24, 10, 10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black
                                                .withValues(alpha: 0.60),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        _catLabel(item.category, l10n),
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
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Item Detail Sheet ────────────────────────────────────────────────────────

class _ItemDetailSheet extends StatelessWidget {
  final ClosetItemModel item;
  final bool isDark;

  const _ItemDetailSheet({
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            color: bg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Full-size image
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 0.85,
                      child: item.isLocalFile
                          ? Image.file(
                              File(item.imagePath),
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              item.imagePath,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                // Category + close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    children: [
                      Text(
                        _catLabel(item.category, l10n),
                        style: AppTypography.heading4.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.gray900,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: AppTypography.body2.copyWith(
                              color:
                                  isDark ? Colors.white70 : AppColors.gray700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

