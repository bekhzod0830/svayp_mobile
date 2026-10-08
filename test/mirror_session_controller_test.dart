import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/features/mirror/data/kiosk_api.dart';
import 'package:swipe/features/mirror/data/kiosk_demo.dart';
import 'package:swipe/features/mirror/data/kiosk_models.dart';
import 'package:swipe/features/mirror/presentation/mirror_session_controller.dart';

/// Бэкенд под контролем теста: каждый ответ приходит тогда, когда тест решит.
class _FakeApi extends KioskApi {
  _FakeApi(super.prefs);

  final createLookCalls = <Completer<KioskLook>>[];
  final createLookArgs = <Map<String, Object?>>[];
  final finishCalls = <Completer<KioskFinish>>[];
  void Function(KioskLook)? onDone;

  @override
  Future<KioskSession> startSession(String lang, String path) async =>
      const KioskSession(sessionId: 's1', storeLabel: 'Test', catalogSize: 10);

  @override
  Future<KioskLook> createLook({
    required String sessionId,
    required String gender,
    required String bodyShape,
    List<String>? styles,
    List<String>? productIds,
    String? brand,
    List<String>? brands,
    String? refine,
    List<String>? refines,
    List<String>? excludeColors,
    bool? faceLiked,
  }) {
    createLookArgs.add({
      'gender': gender,
      'bodyShape': bodyShape,
      'styles': styles,
      'productIds': productIds,
      'brand': brand,
      'brands': brands,
      'refine': refine,
      'refines': refines,
      'excludeColors': excludeColors,
      'faceLiked': faceLiked,
    });
    final c = Completer<KioskLook>();
    createLookCalls.add(c);
    return c.future;
  }

  @override
  KioskLookWatch watchLook(
    String lookId, {
    void Function(KioskLook look)? onProgress,
    required void Function(KioskLook look) onDone,
  }) {
    this.onDone = onDone;
    return super.watchLook('never-polled', onDone: (_) {})..close();
  }

  @override
  Future<KioskFinish> finishSession(String sessionId) {
    final c = Completer<KioskFinish>();
    finishCalls.add(c);
    return c.future;
  }

  @override
  Future<void> resetSession(String sessionId) async {}
}

KioskLook _look(String id, KioskLookStatus status, {String? reason}) =>
    KioskLook(lookId: id, status: status, failureReason: reason);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeApi api;
  late MirrorSessionController c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    api = _FakeApi(prefs);
    c = MirrorSessionController(
      api: api,
      demo: KioskDemoService(api, prefs),
      prefs: prefs,
      logEvent: (name, {parameters}) async {},
    );
    await c.begin(MirrorPath.create);
    c.gender = 'FEMALE';
    c.bodyShape = 'HOURGLASS';
  });

  tearDown(() => c.dispose());

  test('сбой генерации на сервере — честная ошибка, а не демо с фото вместо образа', () async {
    unawaited(c.startGeneration());
    api.createLookCalls.single.complete(_look('l1', KioskLookStatus.pending));
    await Future<void>.delayed(Duration.zero);

    // ML прислал таймаут текстом — раньше это уводило в демо.
    api.onDone!(_look('l1', KioskLookStatus.failed, reason: 'TIMEOUT'));

    expect(c.demoActive, isFalse);
    expect(c.genFailed, isTrue);
    expect(c.genReason, 'TIMEOUT');
    expect(api.createLookCalls, hasLength(1)); // никакой повторной «демо-генерации»
  });

  test('ответ отменённой генерации не подменяет новую', () async {
    // Отмена → сразу новая генерация (другие стили), а ответ первой приходит позже.
    unawaited(c.startGeneration());
    c.cancelGeneration();
    unawaited(c.startGeneration());
    expect(c.screen, MirrorScreen.generating);

    api.createLookCalls[0].complete(_look('old', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);

    // Раньше экран был «generating» — и показывался образ со старыми стилями.
    expect(c.resultReady, isFalse);
    expect(c.look?.lookId, isNot('old'));

    api.createLookCalls[1].complete(_look('new', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);
    expect(c.look?.lookId, 'new');
  });

  test('после сброса код и QR прошлого покупателя не достаются следующему', () async {
    unawaited(c.startGeneration());
    api.createLookCalls.single.complete(_look('l1', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);
    c.revealResult();
    expect(api.finishCalls, hasLength(1));

    await c.hardReset('timeout');
    api.finishCalls.single.complete(const KioskFinish(code: 'LB-1234', shareUrl: 'https://x/k/LB-1234'));
    await Future<void>.delayed(Duration.zero);

    expect(c.sellerCode, isNull);
    expect(c.shareUrl, isNull);
  });

  test('после «Пересобрать» код и QR запрашиваются для нового образа', () async {
    unawaited(c.startGeneration());
    api.createLookCalls[0].complete(_look('l1', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);
    c.revealResult();
    api.finishCalls[0].complete(const KioskFinish(code: 'LB-1111', shareUrl: 'https://x/k/LB-1111'));
    await Future<void>.delayed(Duration.zero);

    c.regenerate(); // ветка «создать» — сначала «Что изменить?»
    expect(c.screen, MirrorScreen.refine);
    c.rebuild();
    api.createLookCalls[1].complete(_look('l2', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);
    c.revealResult();

    // Раньше ensureShare видел старый shareUrl и выходил — QR вёл на первый образ.
    expect(api.finishCalls, hasLength(2));
  });

  group('«Пересобрать» из каталога', () {
    Future<void> catalogResult() async {
      await c.hardReset('manual');
      await c.begin(MirrorPath.catalog);
      c.toggleProduct('p1');
      c.gender = 'MALE';
      c.bodyShape = 'RECTANGLE';
      unawaited(c.startGeneration());
      api.createLookCalls.last.complete(_look('l1', KioskLookStatus.completed));
      await Future<void>.delayed(Duration.zero);
      c.revealResult();
    }

    test('возвращает к выбору вещей, а не собирает тот же образ', () async {
      await catalogResult();
      final calls = api.createLookCalls.length;

      c.regenerate();

      expect(c.screen, MirrorScreen.catalog);
      expect(api.createLookCalls, hasLength(calls)); // генерации нет
      expect(c.attempt, 0); // попытка — только когда выберет новые вещи
      expect(c.pickedProductIds, ['p1']); // прежний выбор виден, можно поменять
    });

    test('после нового выбора — сразу генерация, без камеры и вопросов', () async {
      await catalogResult();
      final calls = api.createLookCalls.length;
      c.regenerate();
      c.toggleProduct('p1');
      c.toggleProduct('p2');

      c.confirmCatalogSelection();

      expect(c.screen, MirrorScreen.generating);
      expect(api.createLookCalls, hasLength(calls + 1));
      expect(c.attempt, 1);
      expect(c.rebuildingFromCatalog, isFalse);
    });

    test('«Назад» из каталога при пересборке — к готовому образу, сессия жива', () async {
      await catalogResult();
      c.regenerate();

      c.goBack();

      expect(c.screen, MirrorScreen.result);
      expect(c.sessionId, isNotNull);
      expect(c.rebuildingFromCatalog, isFalse);
    });

    test('в пути «создать» «Пересобрать» спрашивает «Что изменить?», потом генерирует', () async {
      unawaited(c.startGeneration());
      api.createLookCalls.single.complete(_look('l1', KioskLookStatus.completed));
      await Future<void>.delayed(Duration.zero);
      c.revealResult();

      c.regenerate();
      expect(c.screen, MirrorScreen.refine);
      c.rebuild();

      expect(c.screen, MirrorScreen.generating);
      expect(api.createLookCalls, hasLength(2));
      expect(c.attempt, 1);
    });
  });

  test('окно «Вы ещё здесь?» — через 20 секунд без касаний', () {
    expect(MirrorSessionController.idleTimeout, const Duration(seconds: 20));
  });

  group('станция LIBAS: шаги, бренд и уточнения', () {
    Future<void> result() async {
      unawaited(c.startGeneration());
      api.createLookCalls.last.complete(_look('l${api.createLookCalls.length}', KioskLookStatus.completed));
      await Future<void>.delayed(Duration.zero);
      c.revealResult();
    }

    test('касание карточки пола сразу ведёт к фигуре', () {
      c.confirmPhoto();
      expect(c.screen, MirrorScreen.gender);
      c.setGender('MALE');
      expect(c.gender, 'MALE');
      expect(c.screen, MirrorScreen.shape);
    });

    test('«Не знаю свой тип фигуры» — шлём UNKNOWN и идём к стилям', () {
      c.confirmPhoto();
      c.setGender('FEMALE');
      c.skipShape();
      expect(c.bodyShape, 'UNKNOWN');
      expect(c.screen, MirrorScreen.style);
    });

    test('после стилей — бренд, затем цвета; бренд уходит в запрос', () async {
      c.toggleStyle('CASUAL');
      c.confirmStyles();
      expect(c.screen, MirrorScreen.brand);

      c.confirmShopBrand(); // бренд не выбран — дальше нельзя
      expect(c.screen, MirrorScreen.brand);

      c.toggleShopBrand('VERO_MODA');
      c.confirmShopBrand();
      expect(c.screen, MirrorScreen.colors);

      c.goBack();
      expect(c.screen, MirrorScreen.brand);
      c.confirmShopBrand();

      c.confirmColors();
      expect(c.screen, MirrorScreen.generating);
      expect(api.createLookArgs.last['brand'], 'VERO_MODA');
      expect(api.createLookArgs.last['brands'], ['VERO_MODA']);
      expect(api.createLookArgs.last['refine'], isNull);
    });

    test('несколько брендов: brand = ANY, список — в brands; «Все бренды» снимает отдельные', () {
      c.toggleShopBrand('ONLY');
      c.toggleShopBrand('MEXX');
      expect(c.shopBrands, {'ONLY', 'MEXX'});
      c.toggleShopBrand('ONLY');
      expect(c.shopBrands, {'MEXX'});
      c.toggleShopBrand('ONLY');

      unawaited(c.startGeneration());
      expect(api.createLookArgs.last['brand'], 'ANY');
      expect(api.createLookArgs.last['brands'], ['MEXX', 'ONLY']);

      c.toggleShopBrand('ANY');
      expect(c.shopBrands, {'ANY'});
      unawaited(c.startGeneration());
      expect(api.createLookArgs.last['brand'], 'ANY');
      expect(api.createLookArgs.last['brands'], isNull);

      c.toggleShopBrand('YAS');
      expect(c.shopBrands, {'YAS'});
    });

    test('исключённые цвета уходят в каждую генерацию, «Пропустить» их снимает', () async {
      c.toggleShopBrand('ANY');
      c.toggleAvoidColor('red');
      c.toggleAvoidColor('black');
      c.toggleAvoidColor('red');
      expect(c.avoidColors, ['black']);

      c.confirmColors();
      expect(api.createLookArgs.last['excludeColors'], ['black']);

      api.createLookCalls.last.complete(_look('l1', KioskLookStatus.completed));
      await Future<void>.delayed(Duration.zero);
      c.revealResult();
      c.rebuild(reasons: {'COLOR'}, colors: ['red']);
      expect(api.createLookArgs.last['excludeColors'], ['black', 'red']);

      c.toggleAvoidColor('pink');
      c.confirmColors(skip: true);
      expect(c.avoidColors, isEmpty);
    });

    test('«Завершить» с любого шага возвращает на постер', () async {
      c.toggleStyle('CASUAL');
      c.confirmStyles();
      await c.hardReset('finish');
      expect(c.screen, MirrorScreen.idle);
      expect(c.styles, isEmpty);
    });

    test('«Пересобрать» в ветке «создать» спрашивает, что изменить', () async {
      await result();
      c.regenerate();
      expect(c.screen, MirrorScreen.refine);
      expect(api.createLookCalls, hasLength(1));

      c.goBack();
      expect(c.screen, MirrorScreen.result);
    });

    test('«Дешевле» и ответ про лицо уходят в запрос', () async {
      await result();
      c.regenerate();
      c.setFaceLiked(false);
      c.rebuild(reasons: {'CHEAPER'});

      expect(c.screen, MirrorScreen.generating);
      expect(c.attempt, 1);
      expect(api.createLookArgs.last['refine'], 'CHEAPER');
      expect(api.createLookArgs.last['refines'], isNull);
      expect(api.createLookArgs.last['faceLiked'], false);
    });

    test('несколько причин сразу: главная — в refine, все — в refines', () async {
      c.toggleStyle('CASUAL');
      c.toggleShopBrand('ONLY');
      await result();
      c.regenerate();
      c.rebuild(
        reasons: {'STYLE', 'COLOR', 'PRICIER', 'BRAND'},
        colors: ['red'],
        brands: {'MEXX', 'YAS'},
        styles: ['BUSINESS', 'MINIMAL'],
      );

      final args = api.createLookArgs.last;
      expect(args['refine'], 'PRICIER');
      expect(args['refines'], ['PRICIER', 'COLOR', 'BRAND', 'STYLE']);
      expect(args['excludeColors'], ['red']);
      expect(args['brand'], 'ANY');
      expect(args['brands'], ['MEXX', 'YAS']);
      expect(args['styles'], ['BUSINESS', 'MINIMAL']);
    });

    test('«Другой цвет» шлёт цвета, «Другой бренд» и «Поменять стиль» меняют выбор', () async {
      c.toggleStyle('CASUAL');
      c.toggleShopBrand('ONLY');
      await result();

      c.rebuild(reasons: {'COLOR'}, colors: ['black', 'red']);
      expect(api.createLookArgs.last['excludeColors'], ['black', 'red']);

      c.rebuild(reasons: {'BRAND'}, brands: {'MEXX'});
      expect(c.shopBrands, {'MEXX'});
      expect(api.createLookArgs.last['brand'], 'MEXX');
      expect(api.createLookArgs.last['excludeColors'], isEmpty); // цвета — только для «Другой цвет»

      c.rebuild(reasons: {'STYLE'}, styles: ['BUSINESS']);
      expect(c.styles, ['BUSINESS']);
      expect(api.createLookArgs.last['styles'], ['BUSINESS']);
    });

    test('сброс сессии очищает бренд, ответ про лицо и уточнения', () async {
      c.toggleShopBrand('ONLY');
      c.toggleAvoidColor('red');
      c.setFaceLiked(false);
      c.rebuild(reasons: {'COLOR', 'CHEAPER'}, colors: ['black']);
      await c.hardReset('timeout');

      expect(c.shopBrands, isEmpty);
      expect(c.avoidColors, isEmpty);
      expect(c.faceLiked, isNull);
      expect(c.refineKind, isNull);
      expect(c.refineKinds, isEmpty);
      expect(c.excludeColors, isEmpty);
    });
  });
}
