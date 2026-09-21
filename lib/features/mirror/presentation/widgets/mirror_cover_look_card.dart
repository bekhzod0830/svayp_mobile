import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/kiosk_cover_looks.dart';
import '../../data/kiosk_models.dart';
import '../../data/kiosk_taxonomy.dart';
import '../mirror_theme.dart';

/// Карточка «образа момента» на постере: главная вещь крупно слева, низ и
/// обувь стопкой справа, подпись-кикер с красной точкой «live» и сумма.
/// Фото — на белом, как на ценнике; сама карточка — на поверхности бренда.
class MirrorCoverLookCard extends StatelessWidget {
  const MirrorCoverLookCard({
    super.key,
    required this.look,
    required this.lang,
    required this.kicker,
  });

  final KioskCoverLook look;
  final String lang;
  final String kicker;

  /// Подмена загрузчика фото в тестах: сетевые картинки в виджет-тестах
  /// тянут за собой кэш-менеджер с таймерами и плагинами.
  @visibleForTesting
  static Widget Function(String url)? debugImageBuilder;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final items = look.items;
    final hero = look.hero;
    final side = items.where((i) => i != hero).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.rCard),
        border: Border.all(color: t.hairline),
      ),
      child: Padding(
        padding: EdgeInsets.all(10 * s),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: _Tile(item: hero, radius: t.rImage),
                  ),
                  if (side.isNotEmpty) ...[
                    SizedBox(width: 8 * s),
                    Expanded(
                      flex: 9,
                      child: Column(
                        children: [
                          for (var i = 0; i < side.length; i++) ...[
                            if (i > 0) SizedBox(height: 8 * s),
                            Expanded(
                              child: _Tile(item: side[i], radius: t.rImage),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 10 * s),
            Row(
              children: [
                Container(
                  width: 6 * s,
                  height: 6 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.danger,
                  ),
                ),
                SizedBox(width: 8 * s),
                Expanded(
                  child: Text(
                    t.kickerCase(kicker),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.kicker(s * 0.9),
                  ),
                ),
                SizedBox(width: 12 * s),
                Text(
                  kioskMoney(look.totalPrice, lang),
                  style: t.price(13.5 * s),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.radius});

  final KioskCatalogItem? item;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final url = item?.imageUrl;

    Widget image;
    if (url == null || url.isEmpty) {
      image = const SizedBox.expand();
    } else {
      final debugBuilder = MirrorCoverLookCard.debugImageBuilder;
      image = debugBuilder != null
          ? debugBuilder(url)
          : LayoutBuilder(
              builder: (context, constraints) {
                final dpr = MediaQuery.devicePixelRatioOf(context);
                final width = constraints.maxWidth.isFinite
                    ? (constraints.maxWidth * dpr).round()
                    : null;
                return CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: width,
                  fadeInDuration: const Duration(milliseconds: 300),
                  placeholder: (_, __) => ColoredBox(color: t.surface),
                  errorWidget: (_, __, ___) => ColoredBox(color: t.surface),
                );
              },
            );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(color: Colors.white, child: image),
    );
  }
}
