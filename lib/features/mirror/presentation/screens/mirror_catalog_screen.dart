import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_models.dart';
import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';

/// Экран каталога зала (вход ветки «каталог»): текстовые вкладки категорий с
/// подчёркиванием — как навигация бренда, сетка карточек с фото на белом,
/// мультивыбор квадратным чеком, счётчик на CTA. Смена категории выбор не
/// сбрасывает (веб-паритет).
class MirrorCatalogScreen extends StatelessWidget {
  const MirrorCatalogScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final c = controller;
    final lang = c.shopperLang;
    final picked = c.pickedProductIds.length;
    final brand = t.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(28 * s, 20 * s, 28 * s, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.mirrorCatalogTitle, style: t.headline(34 * s)),
              SizedBox(height: 6 * s),
              Text(
                l10n.mirrorCatalogSubtitle,
                style: t.subtitle(15 * s),
              ),
            ],
          ),
        ),
        SizedBox(height: 18 * s),
        SizedBox(
          height: 38 * s,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 28 * s),
            itemCount: kioskCategories.length,
            separatorBuilder: (_, __) => SizedBox(width: 22 * s),
            itemBuilder: (context, i) {
              final cat = kioskCategories[i];
              return _CategoryTab(
                label: brand.categoryLabel(cat, lang),
                selected: c.category == cat.code,
                onTap: () => c.selectCategory(cat.code),
              );
            },
          ),
        ),
        Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: 28 * s),
          color: t.hairline,
        ),
        SizedBox(height: 14 * s),
        Expanded(
          child: c.catalog.isEmpty
              ? (c.catalogLoading
                  ? _ShimmerGrid(s: s)
                  : Center(
                      child: Text(
                        l10n.mirrorCatalogEmpty,
                        style: t.subtitle(16 * s),
                      ),
                    ))
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(28 * s, 0, 28 * s, 16 * s),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MirrorTheme.gridColumns(context),
                    mainAxisSpacing: 14 * s,
                    crossAxisSpacing: 14 * s,
                    mainAxisExtent: 256 * s,
                  ),
                  itemCount: c.catalog.length,
                  itemBuilder: (context, i) {
                    final item = c.catalog[i];
                    return _CatalogCard(
                      item: item,
                      lang: lang,
                      selected: c.pickedProductIds.contains(item.id),
                      onTap: () => c.toggleProduct(item.id),
                    );
                  },
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(28 * s, 8 * s, 28 * s, 24 * s),
          child: MirrorPrimaryButton(
            label: picked > 0
                ? '${l10n.mirrorCatalogNext} · ${l10n.mirrorPicked} $picked'
                : l10n.mirrorCatalogNext,
            height: 64 * s,
            enabled: picked > 0,
            onTap: c.confirmCatalogSelection,
          ),
        ),
      ],
    );
  }
}

/// Вкладка категории: текст + подчёркивание цветом бренда у активной.
class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: IntrinsicWidth(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              style: t.label(
                14 * s,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? t.ink : t.muted,
              ),
              child: Text(label, maxLines: 1),
            ),
            SizedBox(height: 8 * s),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 2,
              color: selected ? t.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.item,
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final KioskCatalogItem item;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final brand = t.brand;
    final category = kioskCategories
        .where((c) => c.code != null && c.code == item.category)
        .toList();
    final categoryLabel =
        category.isEmpty ? null : brand.categoryLabel(category.first, lang);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.all(6 * s),
        decoration: BoxDecoration(
          color: selected ? t.selectedBg : t.surface,
          borderRadius: BorderRadius.circular(t.rCard),
          border: Border.all(
            color: selected ? t.primary : t.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(t.rImage),
                    child: ColoredBox(
                      color: Colors.white,
                      child: item.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  ColoredBox(color: t.surface),
                              errorWidget: (_, __, ___) =>
                                  ColoredBox(color: t.surface),
                            )
                          : const SizedBox.expand(),
                    ),
                  ),
                  Positioned(
                    top: 8 * s,
                    right: 8 * s,
                    child: MirrorCheck(selected: selected, size: 24 * s),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(6 * s, 8 * s, 6 * s, 4 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categoryLabel != null) ...[
                    Text(
                      t.kickerCase(categoryLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.kicker(s * 0.75, color: t.muted),
                    ),
                    SizedBox(height: 4 * s),
                  ],
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.label(13.5 * s, weight: FontWeight.w600),
                  ),
                  SizedBox(height: 3 * s),
                  Text(
                    item.price != null ? kioskMoney(item.price!, lang) : '',
                    style: t.price(12.5 * s),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid({required this.s});

  final double s;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28 * s, 0, 28 * s, 16 * s),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MirrorTheme.gridColumns(context),
        mainAxisSpacing: 14 * s,
        crossAxisSpacing: 14 * s,
        mainAxisExtent: 256 * s,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: t.hairline,
        highlightColor: t.surface,
        child: Container(
          decoration: BoxDecoration(
            color: t.hairline,
            borderRadius: BorderRadius.circular(t.rCard),
          ),
        ),
      ),
    );
  }
}
