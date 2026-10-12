import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_image_cache.dart';
import '../../data/kiosk_models.dart';
import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';

/// Сколько карточек в ряд: на планшете три (раньше две — фото выходили
/// огромными), на телефоне две.
int _catalogColumns(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 560 ? 3 : 2;

/// Высота карточки при ширине [w]: фото 4:5, название в две строки и цена.
double _cardExtent(double w, double s) => w * 1.25 + 76 * s;

/// Экран каталога зала (ветка «из каталога», после выбора пола): вещи только
/// этого гардероба. Вкладки категорий идут в порядке сборки образа (верх, низ,
/// платья и комплекты, верхняя одежда, обувь, аксессуары; «Все» нет), у каждой —
/// сколько в ней уже выбрано: видно, чего в образе не хватает. Сетка — три
/// карточки в ряд на планшете, мультивыбор квадратным чеком, счётчик на CTA.
/// Смена категории выбор не сбрасывает.
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
    final tabs = c.catalogTabs;
    // Снимок списка: сетка строит карточки лениво, уже после build, а
    // контроллер подменяет `catalog` целиком (сброс сессии — на пустой).
    // Уходящий экран, читая живое поле, падал с RangeError посреди fade-out.
    final items = c.catalog;

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
            itemCount: tabs.length,
            separatorBuilder: (_, __) => SizedBox(width: 22 * s),
            itemBuilder: (context, i) {
              final cat = tabs[i];
              final count = c.pickedIn(cat.code);
              return _CategoryTab(
                label: count > 0
                    ? '${brand.categoryLabel(cat, lang)} · $count'
                    : brand.categoryLabel(cat, lang),
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
          child: items.isEmpty
              ? (c.catalogLoading
                  ? _ShimmerGrid(s: s)
                  : Center(
                      child: Text(
                        l10n.mirrorCatalogEmpty,
                        style: t.subtitle(16 * s),
                      ),
                    ))
              : LayoutBuilder(
                  builder: (context, box) {
                    final cols = _catalogColumns(context);
                    final gap = 12 * s;
                    final w = (box.maxWidth - 56 * s - gap * (cols - 1)) / cols;
                    return GridView.builder(
                      // Новая вкладка — с начала списка.
                      key: PageStorageKey('catalog-${c.category}'),
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(28 * s, 0, 28 * s, 16 * s),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: gap,
                        crossAxisSpacing: gap,
                        mainAxisExtent: _cardExtent(w, s),
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return _CatalogCard(
                          item: item,
                          lang: lang,
                          selected: c.pickedProductIds.contains(item.id),
                          onTap: () => c.toggleProduct(item.id),
                        );
                      },
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
                              cacheManager: KioskImageCache.instance,
                              // Декодируем под размер плитки, а не исходник.
                              memCacheWidth: 420,
                              fadeInDuration: const Duration(milliseconds: 120),
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
                    child: MirrorCheck(selected: selected, size: 22 * s),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(4 * s, 7 * s, 4 * s, 2 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Категорию называет вкладка — на карточке только вещь.
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t
                        .label(12.5 * s, weight: FontWeight.w600)
                        .copyWith(height: 1.2),
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
    final cols = _catalogColumns(context);
    final gap = 12 * s;
    final w = (MediaQuery.sizeOf(context).width - 56 * s - gap * (cols - 1)) / cols;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28 * s, 0, 28 * s, 16 * s),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        mainAxisExtent: _cardExtent(w, s),
      ),
      itemCount: cols * 3,
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
