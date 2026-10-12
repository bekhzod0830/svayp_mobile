import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/features/mirror/brand/storexx_brand.dart';
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
  final finishLookIds = <String?>[];
  void Function(KioskLook)? onDone;

  /// Опрос каждого образа пачки — по его id.
  final doneById = <String, void Function(KioskLook)>{};

  /// Ответ `/kiosk/station`; null — эндпоинта нет (старый бэкенд).
  KioskStation? station;
  int startSessionCalls = 0;
  bool sessionScoped = true;

  @override
  Future<KioskStation> fetchStation() async =>
      station ??
      (throw const KioskApiException(message: 'no endpoint', statusCode: 404));

  @override
  Future<KioskSession> startSession(String lang, String path) async {
    startSessionCalls++;
    return KioskSession(
      sessionId: 's1',
      storeLabel: 'Test',
      catalogSize: 10,
      storeScoped: sessionScoped,
    );
  }

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
    int? variants,
    String? baseLookId,
  }) {
    createLookArgs.add({
      'variants': variants,
      'baseLookId': baseLookId,
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
    doneById[lookId] = onDone;
    return super.watchLook('never-polled', onDone: (_) {})..close();
  }

  @override
  Future<KioskFinish> finishSession(String sessionId, {String? lookId}) {
    finishLookIds.add(lookId);
    final c = Completer<KioskFinish>();
    finishCalls.add(c);
    return c.future;
  }

  @override
  Future<void> resetSession(String sessionId) async {}
}

KioskLook _look(
  String id,
  KioskLookStatus status, {
  String? reason,
  List<String> variants = const [],
}) =>
    KioskLook(
      lookId: id,
      status: status,
      failureReason: reason,
      variantIds: variants,
    );

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

  group('ветка «из каталога»: пол → вещи → камера → фигура', () {
    const catalog = [
      KioskCatalogItem(id: 'w-top', title: 'Блузка', category: 'TOPWEAR', gender: 'FEMALE'),
      KioskCatalogItem(id: 'w-dress', title: 'Платье', category: 'DRESSES', gender: 'FEMALE'),
      KioskCatalogItem(id: 'm-top', title: 'Рубашка', category: 'TOPWEAR', gender: 'MALE'),
      KioskCatalogItem(id: 'm-shoes', title: 'Кеды', category: 'FOOTWEAR', gender: 'MALE'),
      KioskCatalogItem(id: 'u-bag', title: 'Сумка', category: 'ACCESSORIES', gender: 'UNISEX'),
      KioskCatalogItem(id: 'x-pants', title: 'Брюки', category: 'BOTTOMWEAR'),
    ];

    Future<void> start() async {
      await c.hardReset('manual');
      c.seedCatalogForTest(catalog);
      await c.begin(MirrorPath.catalog);
    }

    test('начинается с пола, затем вещи этого гардероба с первой вкладки', () async {
      await start();
      expect(c.screen, MirrorScreen.gender);
      expect(c.stepIndex, 0);

      c.setGender('MALE');
      expect(c.screen, MirrorScreen.catalog);
      expect(c.category, 'TOPWEAR');
      expect(c.catalog.map((i) => i.id), ['m-top']);

      // Вкладки — в порядке сборки образа, только непустые, без «Все» и платьев.
      expect(c.catalogTabs.map((t) => t.code), ['TOPWEAR', 'BOTTOMWEAR', 'FOOTWEAR', 'ACCESSORIES']);

      c.selectCategory('ACCESSORIES');
      expect(c.catalog.map((i) => i.id), ['u-bag']); // унисекс виден обоим
      c.selectCategory('BOTTOMWEAR');
      expect(c.catalog.map((i) => i.id), ['x-pants']); // без пола — тоже
    });

    test('женский гардероб: платья есть, мужских вещей нет', () async {
      await start();
      c.setGender('FEMALE');
      expect(c.catalogTabs.map((t) => t.code), ['TOPWEAR', 'BOTTOMWEAR', 'DRESSES', 'ACCESSORIES']);
      expect(c.catalog.map((i) => i.id), ['w-top']);
    });

    test('счётчик выбранного по вкладке, смена пола снимает выбор', () async {
      await start();
      c.setGender('MALE');
      c.toggleProduct('m-top');
      c.toggleProduct('m-shoes');
      expect(c.pickedIn('TOPWEAR'), 1);
      expect(c.pickedIn('FOOTWEAR'), 1);
      expect(c.pickedIn('BOTTOMWEAR'), 0);

      c.goBack();
      expect(c.screen, MirrorScreen.gender);
      c.setGender('MALE'); // тот же пол — выбор цел
      expect(c.pickedProductIds, ['m-top', 'm-shoes']);
      c.goBack();
      c.setGender('FEMALE');
      expect(c.pickedProductIds, isEmpty);
    });

    test('после фото пол не спрашиваем: сразу фигура; назад — по шагам', () async {
      await start();
      c.setGender('FEMALE');
      c.toggleProduct('w-top');
      c.confirmCatalogSelection();
      expect(c.screen, MirrorScreen.camera);

      c.confirmPhoto();
      expect(c.screen, MirrorScreen.shape);

      c.goBack();
      expect(c.screen, MirrorScreen.camera);
      c.goBack();
      expect(c.screen, MirrorScreen.catalog);
      c.goBack();
      expect(c.screen, MirrorScreen.gender);
      c.goBack();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.screen, MirrorScreen.idle);
    });
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

  test('окно «Вы ещё здесь?» — через 60 секунд без касаний', () {
    expect(MirrorSessionController.idleTimeout, const Duration(seconds: 60));
  });

  test('вещи образа видны с ответа на создание, до картинки', () async {
    unawaited(c.startGeneration());
    expect(c.generatingItems, isEmpty);
    api.createLookCalls.last.complete(const KioskLook(
      lookId: 'l1',
      status: KioskLookStatus.pending,
      items: [KioskLookItem(productId: 'p1', title: 'Рубашка', price: 300000)],
    ));
    await Future<void>.delayed(Duration.zero);
    expect(c.screen, MirrorScreen.generating);
    expect(c.generatingItems.map((i) => i.productId), ['p1']);

    // Новая генерация не показывает вещи прошлой.
    unawaited(c.startGeneration());
    expect(c.generatingItems, isEmpty);
  });

  test('станция выучивает обычное время генерации', () async {
    expect(c.expectedGenSec, MirrorSessionController.defaultGenSec);
    unawaited(c.startGeneration());
    c.elapsedSec = 50;
    api.createLookCalls.last.complete(_look('l1', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);
    expect(c.resultReady, isTrue);
    expect(c.expectedGenSec, 50);

    unawaited(c.startGeneration());
    c.elapsedSec = 60;
    api.createLookCalls.last.complete(_look('l2', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);
    expect(c.expectedGenSec, closeTo(54, 0.01)); // 50·0,6 + 60·0,4
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

  group('пачка из трёх образов', () {
    Future<void> startPack() async {
      unawaited(c.startGeneration());
      api.createLookCalls.last.complete(
        _look('l1', KioskLookStatus.pending, variants: ['l2', 'l3']),
      );
      await Future<void>.delayed(Duration.zero);
    }

    test('ветка «создать» просит 3 образа, из каталога — один', () async {
      await startPack();
      expect(api.createLookArgs.last['variants'], 3);

      await c.hardReset('manual');
      await c.begin(MirrorPath.catalog);
      c.toggleProduct('p1');
      c.gender = 'FEMALE';
      c.bodyShape = 'HOURGLASS';
      unawaited(c.startGeneration());
      expect(api.createLookArgs.last['variants'], isNull);
    });

    test('первый готовый образ открывает результат, остальные дорисовываются на нём', () async {
      await startPack();
      expect(api.doneById.keys, containsAll(['l1', 'l2', 'l3']));

      // Второй образ пришёл раньше первого — показываем его, не ждём.
      api.doneById['l2']!(_look('l2', KioskLookStatus.completed));
      expect(c.resultReady, isTrue);
      expect(c.look?.lookId, 'l2');
      c.revealResult();
      expect(c.screen, MirrorScreen.result);
      expect(c.packLooks.map((l) => l.isCompleted), [false, true, false]);

      api.doneById['l1']!(_look('l1', KioskLookStatus.completed));
      expect(c.look?.lookId, 'l2'); // образ на экране сам не меняется
      expect(c.packLooks.where((l) => l.isCompleted).map((l) => l.lookId), ['l1', 'l2']);
    });

    test('один образ упал — не ошибка; упали все — честная ошибка', () async {
      await startPack();
      api.doneById['l1']!(_look('l1', KioskLookStatus.failed, reason: 'TIMEOUT'));
      api.doneById['l2']!(_look('l2', KioskLookStatus.failed, reason: 'FAILED'));
      expect(c.genFailed, isFalse);
      // Упавшие в переключатель не попадают.
      expect(c.packLooks.map((l) => l.lookId), ['l3']);

      api.doneById['l3']!(_look('l3', KioskLookStatus.failed, reason: 'FAILED'));
      expect(c.genFailed, isTrue);
      expect(c.genReason, 'TIMEOUT'); // причина первого образа пачки
    });

    test('выбор образа: код и QR запрашиваются для выбранного', () async {
      await startPack();
      api.doneById['l1']!(_look('l1', KioskLookStatus.completed));
      c.revealResult();
      api.finishCalls[0].complete(const KioskFinish(code: 'LB-1111', shareUrl: 'https://x/k/LB-1111'));
      await Future<void>.delayed(Duration.zero);
      expect(api.finishLookIds, ['l1']);
      expect(c.sellerCode, 'LB-1111');

      api.doneById['l3']!(_look('l3', KioskLookStatus.completed));
      c.selectLook('l3');

      expect(c.look?.lookId, 'l3');
      expect(c.sellerCode, isNull); // код прошлого образа снят сразу
      expect(api.finishLookIds, ['l1', 'l3']);

      // Не готовый образ выбрать нельзя.
      c.selectLook('l2');
      expect(c.look?.lookId, 'l3');
    });

    test('выбор сменился, пока ждали код — код прошлого образа не показываем', () async {
      await startPack();
      api.doneById['l1']!(_look('l1', KioskLookStatus.completed));
      api.doneById['l2']!(_look('l2', KioskLookStatus.completed));
      c.revealResult(); // finish для l1 ушёл и ещё не ответил
      c.selectLook('l2');
      expect(api.finishCalls, hasLength(1));

      api.finishCalls[0].complete(const KioskFinish(code: 'LB-OLD', shareUrl: 'https://x/k/LB-OLD'));
      await Future<void>.delayed(Duration.zero);

      expect(c.sellerCode, isNull);
      expect(api.finishLookIds, ['l1', 'l2']); // сразу запросили для выбранного
    });

    test('уточнение считается от образа на экране', () async {
      await startPack();
      api.doneById['l1']!(_look('l1', KioskLookStatus.completed));
      api.doneById['l2']!(_look('l2', KioskLookStatus.completed));
      c.revealResult();
      c.selectLook('l2');

      c.rebuild(reasons: {'CHEAPER'});

      expect(api.createLookArgs.last['baseLookId'], 'l2');
      expect(api.createLookArgs.last['refine'], 'CHEAPER');
    });

    test('ответ образа прошлой пачки не попадает в новую', () async {
      await startPack();
      final stale = api.doneById['l2']!;
      api.doneById['l1']!(_look('l1', KioskLookStatus.completed));
      c.revealResult();
      c.rebuild();
      api.createLookCalls.last.complete(
        _look('n1', KioskLookStatus.pending, variants: ['n2']),
      );
      await Future<void>.delayed(Duration.zero);

      stale(_look('l2', KioskLookStatus.completed));

      expect(c.resultReady, isFalse);
      expect(c.packLooks.map((l) => l.lookId), ['n1', 'n2']);
    });
  });

  group('станция магазина без ключа', () {
    late SharedPreferences prefs;
    late MirrorSessionController store;

    setUp(() async {
      prefs = await SharedPreferences.getInstance();
      api.startSessionCalls = 0;
      store = MirrorSessionController(
        api: api,
        demo: KioskDemoService(api, prefs),
        prefs: prefs,
        brand: storexxBrand,
        logEvent: (name, {parameters}) async {},
      );
    });

    tearDown(() => store.dispose());

    test('ключа нет — киоск закрыт экраном настройки, сессия не начинается', () async {
      await store.checkStation();

      expect(store.stationBlocked, isTrue);
      expect(store.stationKeyRejected, isFalse);

      await store.begin(MirrorPath.create);
      expect(store.screen, MirrorScreen.idle);
      expect(api.startSessionCalls, 0);
    });

    test('ключ введён, но бэкенд его не принял — блокировка с этой причиной', () async {
      await api.setDeviceKey('stale-key');
      api.station = const KioskStation(storeLabel: 'LIBAS', storeScoped: false);

      await store.checkStation();

      expect(store.stationBlocked, isTrue);
      expect(store.stationKeyRejected, isTrue);
    });

    test('ключ принят — киоск работает; ключ ввели заново — блокировка снимается', () async {
      await store.checkStation();
      expect(store.stationBlocked, isTrue);

      await api.setDeviceKey('good-key');
      api.station = const KioskStation(storeLabel: 'Storexx', storeScoped: true);
      await store.onSetupClosed();

      expect(store.stationBlocked, isFalse);
      await store.begin(MirrorPath.create);
      expect(store.screen, MirrorScreen.camera);
    });

    test('сеть моргнула или бэкенд старый — рабочий киоск с ключом не закрываем', () async {
      await api.setDeviceKey('good-key');
      api.station = null; // fetchStation бросает

      await store.checkStation();

      expect(store.stationBlocked, isFalse);
    });

    test('ключ отозвали после проверки — сессия открылась по общему каталогу и закрыта', () async {
      await api.setDeviceKey('revoked-key');
      api.station = const KioskStation(storeLabel: 'Storexx', storeScoped: true);
      await store.checkStation();
      api.sessionScoped = false;

      await store.begin(MirrorPath.create);

      expect(store.stationBlocked, isTrue);
      expect(store.sessionId, isNull);
      expect(store.screen, MirrorScreen.idle);
    });

    test('общее оформление LIBAS ключа не требует', () async {
      await c.checkStation();
      expect(c.stationBlocked, isFalse);
    });
  });
}
