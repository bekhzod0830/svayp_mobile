import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_models.dart';
import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';

/// Экран 5 — каталог зала (вход ветки «каталог»): чипы категорий,
/// прогрессивная сетка, мультивыбор с розовой рамкой, счётчик на CTA.
/// Смена категории выбор не сбрасывает (веб-паритет).
class MirrorCatalogScreen extends StatelessWidget {
  const MirrorCatalogScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = MirrorTheme.scale(context);
    final c = controller;
    final lang = c.shopperLang;
    final picked = c.pickedProductIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(28 * s, 20 * s, 28 * s, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.mirrorCatalogTitle, style: MirrorTheme.headline(36 * s)),
              SizedBox(height: 6 * s),
              Text(
                l10n.mirrorCatalogSubtitle,
                style: MirrorTheme.subtitle(15 * s),
              ),
            ],
          ),
        ),
        SizedBox(height: 16 * s),
        SizedBox(
          height: 44 * s,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 28 * s),
            itemCount: kioskCategories.length,
            separatorBuilder: (_, __) => SizedBox(width: 8 * s),
            itemBuilder: (context, i) {
              final cat = kioskCategories[i];
              final selected = c.category == cat.code;
              return GestureDetector(
                onTap: () => c.selectCategory(cat.code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.symmetric(horizontal: 18 * s),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? MirrorTheme.ink : MirrorTheme.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    cat.label(lang),
                    style: MirrorTheme.label(
                      13.5 * s,
                      weight: FontWeight.w700,
                      color: selected ? Colors.white : MirrorTheme.ink,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 14 * s),
        Expanded(
          child: c.catalog.isEmpty
              ? (c.catalogLoading
                  ? _ShimmerGrid(s: s)
                  : Center(
                      child: Text(
                        l10n.mirrorCatalogEmpty,
                        style: MirrorTheme.subtitle(16 * s),
                      ),
                    ))
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(28 * s, 0, 28 * s, 16 * s),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MirrorTheme.gridColumns(context),
                    mainAxisSpacing: 14 * s,
                    crossAxisSpacing: 14 * s,
                    mainAxisExtent: 240 * s,
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
    final s = MirrorTheme.scale(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18 * s),
          border: Border.all(
            color: selected ? MirrorTheme.pink : Colors.transparent,
            width: 3,
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
                    borderRadius: BorderRadius.circular(15 * s),
                    child: item.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: MirrorTheme.surface),
                            errorWidget: (_, __, ___) =>
                                Container(color: MirrorTheme.surface),
                          )
                        : Container(color: MirrorTheme.surface),
                  ),
                  Positioned(
                    top: 8 * s,
                    right: 8 * s,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 26 * s,
                      height: 26 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? MirrorTheme.pink : Colors.white,
                        border: Border.all(
                          color: selected
                              ? MirrorTheme.pink
                              : MirrorTheme.hairline,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? Icon(Icons.check_rounded,
                              size: 17 * s, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(6 * s, 8 * s, 6 * s, 4 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MirrorTheme.label(13.5 * s, weight: FontWeight.w700),
                  ),
                  SizedBox(height: 3 * s),
                  Text(
                    item.price != null ? kioskMoney(item.price!, lang) : '',
                    style: MirrorTheme.subtitle(12.5 * s),
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
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28 * s, 0, 28 * s, 16 * s),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MirrorTheme.gridColumns(context),
        mainAxisSpacing: 14 * s,
        crossAxisSpacing: 14 * s,
        mainAxisExtent: 240 * s,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: MirrorTheme.surface,
        highlightColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: MirrorTheme.surface,
            borderRadius: BorderRadius.circular(18 * s),
          ),
        ),
      ),
    );
  }
}
