import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'kiosk_api.dart';
import 'kiosk_models.dart';

/// Демо-режим киоска — порт `swipe-web/lib/kiosk-demo.ts`.
///
/// Нужен, чтобы показывать сценарий партнёрам без ключа устройства, без
/// развёрнутого киоск-бэкенда и без расходов на генерацию.
///
/// Что настоящее: каталог тянется из публичного API магазина — живые товары,
/// фото и цены. Что имитировано: сборка образа и его отрисовка. Экран об этом
/// прямо говорит (бейдж «Демо-режим»), выдавать имитацию за работающую
/// примерку нельзя.
class KioskDemoService {
  KioskDemoService(this._api, this._prefs);

  /// Принудительный демо-режим из настроечного шита (аналог `?demo=1`).
  static const _forcedKey = 'kiosk_demo_forced';

  final KioskApi _api;
  final SharedPreferences _prefs;
  final _uuid = const Uuid();
  final _random = Random();

  /// Авто-демо после падения startSession. В памяти, как sessionStorage у веба:
  /// перезапуск приложения = чистый лист, один сбой сети не запирает планшет
  /// в имитации навсегда.
  bool _auto = false;

  List<KioskCatalogItem> _catalogCache = [];
  KioskLook? _lastLook;

  static const Duration generationDuration = Duration(seconds: 6);

  bool get forced => _prefs.getBool(_forcedKey) ?? false;

  Future<void> setForced(bool value) async {
    await _prefs.setBool(_forcedKey, value);
  }

  bool get enabled => forced || _auto;

  /// Включить демо — когда бэкенд киоска недоступен.
  void enableAuto() => _auto = true;

  /// Выключить демо, как только бэкенд ответил.
  void disableAuto() => _auto = false;

  KioskSession session() => KioskSession(
        sessionId: _uuid.v4(),
        storeLabel: 'Демо-магазин · Ташкент',
        catalogSize: 0,
      );

  /// Каталог из публичного `/products/all` — открыт без авторизации, так что
  /// демо показывает реальные вещи. Тянем все страницы: обрезанный каталог
  /// выглядит как пустой зал. Первая страница отдаётся сразу через [onPage].
  Future<List<KioskCatalogItem>> catalog({
    void Function(List<KioskCatalogItem> items)? onPage,
    String? category,
    bool Function()? cancelled,
  }) async {
    List<KioskCatalogItem> filtered(List<KioskCatalogItem> list) =>
        category == null
            ? list
            : list.where((i) => i.category == category).toList();

    if (_catalogCache.isNotEmpty) {
      final result = filtered(_catalogCache);
      onPage?.call(result);
      return result;
    }

    const pageSize = 100;
    final collected = <KioskCatalogItem>[];
    var page = 0;
    var total = -1;

    while (total < 0 || collected.length < total) {
      final res = await _api.dio.get<dynamic>(
        '/products/all',
        queryParameters: {'page': page, 'size': pageSize},
      );
      if (cancelled?.call() ?? false) return filtered(collected);

      final payload = res.data is Map ? (res.data as Map)['data'] : null;
      final products =
          payload is Map ? (payload['data'] as List? ?? const []) : const [];
      final pagination = payload is Map ? payload['pagination'] : null;
      total = pagination is Map
          ? (pagination['total'] as num?)?.toInt() ?? products.length
          : products.length;

      if (products.isEmpty) break;

      collected.addAll(
        products.whereType<Map>().where((p) {
          final images = p['images'];
          return images is List && images.isNotEmpty;
        }).map(
          (p) => KioskCatalogItem(
            id: (p['id'] ?? '').toString(),
            title: (p['title'] ?? '').toString(),
            category: p['category']?.toString(),
            price: (p['price'] as num?)?.toInt(),
            currency: p['currency']?.toString() ?? 'UZS',
            imageUrl: ((p['images'] as List).first).toString(),
            sizes: (p['sizes'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
          ),
        ),
      );

      _catalogCache = List.of(collected);
      onPage?.call(filtered(List.of(collected)));
      page += 1;
    }

    return filtered(_catalogCache);
  }

  /// Слот товара — та же логика, что на бэкенде, огрублённая до категорий.
  static String _slotOf(KioskCatalogItem item) {
    switch (item.category) {
      case 'TOPWEAR':
        return 'TOP';
      case 'BOTTOMWEAR':
        return 'BOTTOM';
      case 'DRESSES':
      case 'ONE_PIECE':
      case 'TWO_PIECE_SET':
        return 'FULL';
      case 'FOOTWEAR':
        return 'SHOES';
      default:
        return 'OTHER';
    }
  }

  /// Собирает образ по тем же правилам, что бэкенд: цельная вещь ИЛИ верх+низ,
  /// плюс обувь, не больше 4 вещей. «Результат» — снятый кадр [photoPath]:
  /// настоящей генерации в демо нет, и подменять её чужой картинкой — обман.
  ///
  /// [baseCatalog] — каталог зала, если он уже загружен (фолбэк после падения
  /// настоящего пайплайна): собираем из вещей ЭТОГО магазина, а не из общего
  /// маркетплейса.
  Future<KioskLook> look({
    required List<String> pickedIds,
    required int attempt,
    String? photoPath,
    List<KioskCatalogItem>? baseCatalog,
  }) async {
    final items = (baseCatalog != null && baseCatalog.isNotEmpty)
        ? baseCatalog
        : await catalog();
    final chosen = items.where((i) => pickedIds.contains(i.id)).toList();

    KioskCatalogItem? pick(String slot) {
      final pool = items
          .where((i) => _slotOf(i) == slot && !pickedIds.contains(i.id))
          .toList();
      return pool.isEmpty ? null : pool[attempt % pool.length];
    }

    final look = [...chosen];
    final hasFull = look.any((i) => _slotOf(i) == 'FULL');

    if (!hasFull) {
      if (!look.any((i) => _slotOf(i) == 'TOP')) {
        final top = pick('TOP');
        if (top != null) look.add(top);
      }
      if (!look.any((i) => _slotOf(i) == 'BOTTOM')) {
        final bottom = pick('BOTTOM');
        if (bottom != null) look.add(bottom);
      }
    }
    if (!look.any((i) => _slotOf(i) == 'SHOES')) {
      final shoes = pick('SHOES');
      if (shoes != null) look.add(shoes);
    }

    final lookItems = look.take(4).map(
      (i) {
        return KioskLookItem(
          productId: i.id,
          title: i.title,
          category: i.category,
          size: i.sizes.isNotEmpty ? _sizeRange(i.sizes) : '—',
          price: i.price,
          currency: i.currency,
          imageUrl: i.imageUrl,
        );
      },
    ).toList();

    _lastLook = KioskLook(
      lookId: _uuid.v4(),
      status: KioskLookStatus.completed,
      resultImageUrl: photoPath == null ? null : 'file://$photoPath',
      items: lookItems,
      totalPrice: lookItems.fold(0, (sum, i) => sum + (i.price ?? 0)),
      currency: lookItems.isNotEmpty ? lookItems.first.currency : 'UZS',
      regenerateCount: attempt,
      canRegenerate: attempt < 3,
    );
    return _lastLook!;
  }

  KioskLook? get lastLook => _lastLook;

  /// Диапазон размеров — как KioskSizeAdvisor на бэкенде.
  static String _sizeRange(List<String> sizes) {
    if (sizes.length == 1) return sizes.first;
    final mid = (sizes.length - 1) ~/ 2;
    final from = sizes[mid];
    final to = sizes[min(mid + 1, sizes.length - 1)];
    return from == to ? from : '$from–$to';
  }

  KioskFinish finish() {
    final code = 'LB-${1000 + _random.nextInt(9000)}';
    return KioskFinish(
      code: code,
      shareUrl: 'https://web.svaypai.com/k/$code',
      shareExpiresAt:
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    );
  }

  /// Сброс демо-состояния сессии (кадр держит контроллер, тут только образ).
  void resetLook() => _lastLook = null;
}
