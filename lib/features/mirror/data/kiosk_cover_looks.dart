import 'dart:math';

import 'kiosk_models.dart';
import 'kiosk_taxonomy.dart';

/// «Образ момента» для постера: цельная вещь или верх+низ, плюс обувь, если
/// есть. Собирается на устройстве из кэша каталога зала — без сессии и без
/// генерации, чтобы покупатель ещё до старта видел, из чего будет образ.
class KioskCoverLook {
  const KioskCoverLook({this.top, this.bottom, this.full, this.shoes});

  final KioskCatalogItem? top;
  final KioskCatalogItem? bottom;
  final KioskCatalogItem? full;
  final KioskCatalogItem? shoes;

  /// Главная вещь карточки: цельная либо верх.
  KioskCatalogItem? get hero => full ?? top;

  /// Вещи в порядке показа: главная, низ (если образ не цельный), обувь.
  List<KioskCatalogItem> get items => [
        full ?? top,
        if (full == null) bottom,
        shoes,
      ].whereType<KioskCatalogItem>().toList();

  int get totalPrice => items.fold(0, (sum, i) => sum + (i.price ?? 0));
}

/// Собирает до [count] образов из [catalog].
///
/// Правила те же, что у бэкенда и демо: цельная вещь ИЛИ верх+низ, обувь
/// опциональна. Берутся только вещи с фото; вещь не повторяется между
/// образами (корзина слота исчерпалась — образов такого типа больше нет).
/// Порядок детерминирован [seed]: тесты стабильны, а постер меняет ротацию
/// от дня к дню, не дёргаясь внутри одной смены.
List<KioskCoverLook> composeCoverLooks(
  List<KioskCatalogItem> catalog, {
  int count = 6,
  int seed = 0,
}) {
  if (count <= 0 || catalog.isEmpty) return const [];
  final random = Random(seed);

  List<KioskCatalogItem> bucket(String slot) {
    final items = catalog
        .where((i) =>
            (i.imageUrl?.isNotEmpty ?? false) &&
            kioskSlotOf(i.category) == slot)
        .toList();
    items.shuffle(random);
    return items;
  }

  final tops = bucket('TOP');
  final bottoms = bucket('BOTTOM');
  final fulls = bucket('FULL');
  final shoes = bucket('SHOES');

  final looks = <KioskCoverLook>[];
  var ti = 0, bi = 0, fi = 0, si = 0;
  // Чередуем «цельный» и «верх+низ», начиная с пары, пока хватает обоих.
  var preferFull = false;

  while (looks.length < count) {
    final canPair = ti < tops.length && bi < bottoms.length;
    final canFull = fi < fulls.length;
    if (!canPair && !canFull) break;

    final useFull = canFull && (!canPair || preferFull);
    final pairOfShoes = si < shoes.length ? shoes[si++] : null;

    if (useFull) {
      looks.add(KioskCoverLook(full: fulls[fi++], shoes: pairOfShoes));
    } else {
      looks.add(
        KioskCoverLook(top: tops[ti++], bottom: bottoms[bi++], shoes: pairOfShoes),
      );
    }
    preferFull = !useFull;
  }
  return looks;
}
