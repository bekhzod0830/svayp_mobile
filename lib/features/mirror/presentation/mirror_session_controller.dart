import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analytics/analytics_service.dart';
import '../brand/mirror_brands.dart';
import '../data/kiosk_api.dart';
import '../data/kiosk_demo.dart';
import '../data/kiosk_image_cache.dart';
import '../data/kiosk_models.dart';
import '../data/kiosk_taxonomy.dart';

/// Экраны киоска. Пол и фигура — два отдельных экрана (решение владельца),
/// но делят один сегмент прогресса. «Как это работает» живёт на постере,
/// поэтому ветка «создать» начинается сразу с камеры.
enum MirrorScreen {
  idle,
  camera,
  gender,
  shape,
  style,

  /// «Где вы любите покупать?» — бренды или «все» (только ветка «создать»).
  brand,

  /// «Какие цвета не показывать?» — цвета, которых не должно быть в образе
  /// (только ветка «создать», сразу после брендов).
  colors,
  catalog,
  generating,
  result,

  /// «Что изменить?» — уточнения перед «Пересобрать» в ветке «создать».
  refine,
  buy,
}

enum MirrorPath { create, catalog }

/// Отправка события аналитики. Подменяется в тестах: настоящий сервис при
/// создании обращается к Firebase.
typedef KioskEventLogger = Future<void> Function(String name,
    {Map<String, String>? parameters});

/// Состояние киоск-сессии: машина экранов, ответы, фото, генерация, таймеры
/// бездействия. ChangeNotifier — по конвенции приложения (bloc не используется).
///
/// Ключевое бизнес-требование (ТЗ, раздел 1): каждая сессия заканчивается
/// либо QR-переходом, либо кодом продавца. Сброс — полная зачистка: следующий
/// человек не должен увидеть ничего от предыдущего.
class MirrorSessionController extends ChangeNotifier {
  MirrorSessionController({
    required KioskApi api,
    required KioskDemoService demo,
    required SharedPreferences prefs,
    MirrorBrand brand = kMirrorBrand,
    void Function(String event, Map<String, String> params)? analytics,
    KioskEventLogger? logEvent,
  })  : _api = api,
        _demo = demo,
        _prefs = prefs,
        _sink = analytics,
        _logEvent = logEvent,
        _brand = brand {
    _storeLabel = _prefs.getString(_storeLabelKey);
    shopperLang = _langFor(brand, _prefs.getString(_langKey));
  }

  /// Последний выбранный язык киоска — переживает сброс сессии и перезапуск.
  static const _langKey = 'kiosk_shopper_lang';

  /// [saved], если бренд его поддерживает, иначе язык бренда по умолчанию.
  static String _langFor(MirrorBrand brand, String? saved) =>
      saved != null && brand.languages.contains(saved) ? saved : brand.defaultLang;

  static const _storeLabelKey = 'kiosk_store_label';
  /// Окно «Вы ещё здесь?» — после 60 с без касаний (было 20 с: человек не
  /// успевал отсканировать QR или прочитать состав образа).
  static const idleTimeout = Duration(seconds: 60);
  static const idleGraceSeconds = 10;
  static const maxRegenerations = 3;

  /// Сколько образов просим за раз в ветке «создать»: человек листает их на
  /// результате. Каждый образ — отдельная генерация на бэкенде.
  static const lookVariants = 3;
  // Киоск генерирует через FASHN по шагам: замер на проде ≈105 c на 3 вещи
  // (gpt-image — ~30 c). Бюджет ML — 200 c, наш порог выше, чтобы первым
  // приходил честный отказ сервера.
  static const int reassureAfterSec = 100;
  static const int failAfterSec = 210;

  /// Как часто освежается каталог зала, пока киоск стоит на постере.
  static const coverRefreshInterval = Duration(minutes: 15);

  final KioskApi _api;
  final KioskDemoService _demo;
  final SharedPreferences _prefs;

  /// Куда уходят события киоска. null — общая аналитика приложения (лениво:
  /// Firebase не трогаем при создании); в тестах подставляется заглушка.
  final void Function(String event, Map<String, String> params)? _sink;

  /// Оформление киоска: язык по умолчанию, подписи справочников. Продавец
  /// меняет его на экране выбора ([setBrand]).
  MirrorBrand get brand => _brand;
  MirrorBrand _brand;

  /// Логгер в форме `AnalyticsService.logEvent` — второй способ подменить
  /// аналитику (им пользуются тесты контроллера). [_sink] главнее.
  final KioskEventLogger? _logEvent;

  // ── Состояние ──────────────────────────────────────────────────────────────
  MirrorScreen screen = MirrorScreen.idle;
  MirrorPath path = MirrorPath.create;

  /// Язык покупателя — локален для киоска, не трогает язык приложения продавца.
  late String shopperLang;

  String? sessionId;
  String? _storeLabel;

  /// Показывать ли кнопку «Мужчина»: мужская одежда в зале есть не всегда.
  bool menswearAvailable = true;
  bool demoActive = false;

  String? gender;
  String? bodyShape;
  final List<String> styles = [];

  /// Бренды с шага «Где вы любите покупать?»: коды ([kioskShopBrands]) в
  /// порядке выбора; `{kioskAnyBrand}` — все бренды, пусто — ещё не выбраны.
  final Set<String> shopBrands = {};

  /// Цвета с шага «Какие цвета не показывать?». Живут всю сессию и уходят в
  /// каждую генерацию — вместе с цветами уточнения «Другой цвет».
  final List<String> avoidColors = [];

  /// «Понравилось ли вам лицо?» на экране уточнений; null — не отвечал.
  bool? faceLiked;

  /// Уточнения последней пересборки ([kioskRefineOrder]: CHEAPER | PRICIER |
  /// COLOR | BRAND | STYLE, можно несколько) и цвета, которых не должно быть.
  /// Живут до следующей пересборки: повтор после ошибки шлёт тот же запрос.
  final List<String> refineKinds = [];

  /// Порядок уточнений: цена главнее — она и уходит в `refine` (бэкенд
  /// понимает одно), полный список — в `refines`.
  static const kioskRefineOrder = ['CHEAPER', 'PRICIER', 'COLOR', 'BRAND', 'STYLE'];

  String? get refineKind => refineKinds.firstOrNull;
  final List<String> excludeColors = [];
  final List<String> pickedProductIds = [];

  List<KioskCatalogItem> catalog = [];
  bool catalogLoading = false;
  String? category;
  int _catalogRequestToken = 0;

  /// Полный каталог зала, закэшированный на время работы приложения.
  /// Товары не персональные, поэтому кэш переживает hardReset — следующий
  /// покупатель видит витрину мгновенно; свежесть обеспечивает фоновое
  /// обновление на постере и при каждом входе в каталог.
  List<KioskCatalogItem> _catalogAllCache = [];
  bool _catalogFetchInFlight = false;

  /// Сброс или вход в каталог пришёл, пока каталог грузился: перезагрузить,
  /// когда текущая загрузка кончится.
  bool _catalogReloadPending = false;

  /// Откуда кэш: из киоск-API зала или из демо (`/products/all` — весь
  /// маркетплейс). Постер бренда не должен показывать чужие вещи, поэтому
  /// при смене источника кэш сбрасывается.
  bool _catalogCacheIsDemo = false;
  DateTime? _catalogWarmedAt;
  Timer? _coverRefreshTimer;

  File? capturedPhoto;
  String? photoBlobKey;
  KioskPhotoValidation? validation;

  /// Образ на экране: до результата — первый образ пачки (сцена генерации
  /// листает его вещи), на результате — выбранный человеком.
  KioskLook? look;
  KioskLook? _completedLook;

  /// Состав образа текущей генерации. Бэкенд собирает его до картинки и
  /// отдаёт уже в ответе на создание образа (PENDING), — экран генерации
  /// показывает вещи с первых секунд, пока картинка рисуется.
  List<KioskLookItem> generatingItems = const [];

  /// Сколько обычно идёт генерация на этой станции, секунд: скользящее
  /// среднее по прошлым образам (живёт в prefs). По нему экран генерации
  /// растягивает прогресс — к готовности он подходит к ~90%, а не прыгает
  /// с середины на 100%.
  double get expectedGenSec =>
      (_prefs.getDouble(_genAvgKey) ?? defaultGenSec).clamp(20.0, 180.0);
  static const _genAvgKey = 'kiosk_gen_avg_sec';
  /// До первого образа на станции. На планшете зала генерация шла ~40–50 с;
  /// дальше станция подстраивается под своё время сама.
  static const double defaultGenSec = 60;

  /// Образы текущей пачки в порядке бэкенда, по id: последнее известное
  /// состояние каждого (готов, генерируется, упал).
  final Map<String, KioskLook> _pack = {};

  /// Образ, от которого считается уточнение («Дешевле» и т.п.): тот, что был
  /// на экране в момент «Пересобрать».
  String? _baseLookId;

  /// В каком порядке образы пачки дорисовались. Лента на результате идёт в
  /// этом порядке: образ, готовый первым, — первый, и результат открывается на
  /// нём (в порядке бэкенда первым готовым мог оказаться третий, и лента
  /// открывалась с конца).
  final List<String> _readyOrder = [];

  /// Образы пачки для ленты на результате: готовые — в порядке готовности,
  /// за ними те, что ещё генерируются (в порядке бэкенда); упавшие не
  /// показываем.
  List<KioskLook> get packLooks => List.unmodifiable([
        for (final id in _readyOrder)
          if (_pack[id]?.isCompleted ?? false) _pack[id]!,
        for (final l in _pack.values)
          if (!l.isCompleted && l.status != KioskLookStatus.failed) l,
      ]);

  bool resultReady = false;
  int elapsedSec = 0;
  bool genFailed = false;
  String? genReason;
  int attempt = 0;

  /// «Пересобрать» в пути «из каталога»: человек вернулся к выбору вещей. Снимок и
  /// ответы уже есть — после выбора сразу генерация, без камеры и вопросов.
  bool rebuildingFromCatalog = false;

  String? sellerCode;
  String? shareUrl;

  bool offline = false;
  bool idleWarning = false;
  int idleLeft = idleGraceSeconds;

  bool _active = false;
  bool _disposed = false;

  /// Номер текущей генерации: отмена, сброс и новая генерация его меняют, и
  /// запоздавший ответ прошлой генерации не открывает чужой результат.
  int _genId = 0;

  /// Для какого образа уже взяты код и QR: после «Пересобрать» их нужно обновить.
  String? _sharedLookId;
  bool _shareInFlight = false;
  int _shareRetries = 0;

  /// Все картинки результатов сессии: после сброса вычищаем из кэша каждую, а не
  /// только последнюю — на прошлых пересборках тоже лицо покупателя.
  final Set<String> _resultUrls = {};

  /// Опрос каждого образа пачки. Первый готовый открывает результат,
  /// остальные дорисовываются уже на нём.
  final List<KioskLookWatch> _watches = [];
  Timer? _idleTimer;
  Timer? _graceTicker;
  Timer? _elapsedTicker;
  Timer? _demoGenTimer;
  Timer? _shareRetryTimer;

  /// Оформление магазина без принятого ключа станции: киоск закрыт экраном
  /// настройки, а не работает молча по каталогу всех магазинов.
  bool stationBlocked = false;

  /// Причина блокировки: ключ введён, но бэкенд его не принял (true) или
  /// ключа нет вовсе (false).
  bool stationKeyRejected = false;

  bool get _needsStationKey => _brand.requiresStationKey && !_demo.forced;

  String? get storeLabel => _storeLabel;
  KioskApi get api => _api;
  KioskDemoService get demoService => _demo;

  /// Размеры модели из каталога зала (по id товара) — для карточки вещи:
  /// в составе образа бэкенд отдаёт только рекомендованный размер.
  List<String> sizesFor(String productId) {
    for (final item in _catalogAllCache) {
      if (item.id == productId) return item.sizes;
    }
    return const [];
  }

  List<KioskCatalogItem> get catalogPreview =>
      List.unmodifiable(_catalogAllCache);

  int get regenerationsLeft =>
      (maxRegenerations - attempt).clamp(0, maxRegenerations);

  bool get canRegenerate =>
      attempt < maxRegenerations && (look?.canRegenerate ?? true);

  /// Индекс сегмента прогресса (всегда 4 сегмента, независимо от ветки).
  int get stepIndex {
    if (path == MirrorPath.create) {
      switch (screen) {
        case MirrorScreen.idle:
        case MirrorScreen.camera:
        case MirrorScreen.catalog:
          return 0;
        case MirrorScreen.gender:
        case MirrorScreen.shape:
          return 1;
        case MirrorScreen.style:
        case MirrorScreen.brand:
        case MirrorScreen.colors:
          return 2;
        case MirrorScreen.generating:
        case MirrorScreen.result:
        case MirrorScreen.refine:
        case MirrorScreen.buy:
          return 3;
      }
    }
    // «Из каталога»: пол и вещи → камера → фигура → образ.
    switch (screen) {
      case MirrorScreen.idle:
      case MirrorScreen.gender:
      case MirrorScreen.catalog:
        return 0;
      case MirrorScreen.camera:
        return 1;
      case MirrorScreen.shape:
      case MirrorScreen.style:
      case MirrorScreen.brand:
      case MirrorScreen.colors:
        return 2;
      case MirrorScreen.generating:
      case MirrorScreen.result:
      case MirrorScreen.refine:
      case MirrorScreen.buy:
        return 3;
    }
  }

  /// Бэкенд отдаёт коды с префиксом (`KIOSK_LOOK_UNAVAILABLE`), старые места
  /// сравнивали без него — и отказ «нет образа» уходил в демо с фото вместо
  /// образа.
  static bool isLookUnavailable(String? reason) =>
      reason == 'KIOSK_LOOK_UNAVAILABLE' || reason == 'LOOK_UNAVAILABLE';

  /// Осмысленный отказ бэкенда (наличие, лимиты), а не сбой пайплайна.
  static bool isBusinessRefusal(String? reason) =>
      isLookUnavailable(reason) || (reason?.startsWith('KIOSK_') ?? false);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _track(String event, [Map<String, String>? params]) {
    final payload = <String, String>{
      if (sessionId != null) 'kiosk_session_id': sessionId!,
      'demo': demoActive.toString(),
      ...?params,
    };
    final sink = _sink;
    if (sink != null) {
      sink(event, payload);
      return;
    }
    // Аналитика не должна валить киоск: Firebase может быть не поднят.
    try {
      final log = _logEvent ?? AnalyticsService.instance.logEvent;
      log(event, parameters: payload).catchError((Object _) {});
    } catch (_) {}
  }

  // ── Станция ────────────────────────────────────────────────────────────────

  /// Принят ли ключ станции. Зовётся на постере (до сессии) и после шита
  /// настройки. Сеть моргнула или бэкенд старый — при введённом ключе не
  /// блокируем: закрыть рабочий киоск из-за сбоя хуже.
  Future<void> checkStation() async {
    if (!_needsStationKey) {
      _setStationBlocked(false);
      return;
    }
    final key = _api.deviceKey;
    if (key == null || key.isEmpty) {
      _setStationBlocked(true, rejected: false);
      return;
    }
    try {
      final station = await _api.fetchStation();
      if (_disposed || !_needsStationKey) return;
      _setStationBlocked(!station.storeScoped, rejected: true);
    } on KioskApiException {
      // Оставляем как было.
    }
  }

  void _setStationBlocked(bool blocked, {bool rejected = false}) {
    final keyRejected = blocked && rejected;
    if (stationBlocked == blocked && stationKeyRejected == keyRejected) return;
    stationBlocked = blocked;
    stationKeyRejected = keyRejected;
    if (blocked) {
      // Каталог мог успеть прийти общий — под вывеской магазина его не держим.
      _setCatalogCache(const [], demo: false);
      _catalogWarmedAt = null;
      catalog = [];
    }
    _notify();
  }

  /// Шит настройки закрыт: ключ мог смениться — перепроверяем станцию и
  /// перечитываем каталог (он у другого ключа другой).
  Future<void> onSetupClosed() async {
    await checkStation();
    if (!stationBlocked) await warmCatalog(force: true);
  }

  // ── Старт сессии ───────────────────────────────────────────────────────────

  bool _beginning = false;

  /// Вход с постера. При недоступном бэкенде — демо-режим, а не ошибка:
  /// показ партнёру важнее (паритет с веб-киоском). Но если сети нет совсем,
  /// оффлайн-оверлей выигрывает (его ставит MirrorTab).
  Future<void> begin(MirrorPath p) async {
    // Двойное касание CTA не должно открыть две сессии.
    if (_beginning || screen != MirrorScreen.idle || stationBlocked) return;
    _beginning = true;
    try {
      await _begin(p);
    } finally {
      // Любая неожиданная ошибка (не KioskApiException) раньше оставляла флаг
      // поднятым — и кнопки постера не работали до перезапуска приложения.
      _beginning = false;
    }
  }

  Future<void> _begin(MirrorPath p) async {
    path = p;
    _coverRefreshTimer?.cancel();
    _coverRefreshTimer = null;
    touch();

    if (_demo.forced) {
      _startDemoSession();
    } else {
      try {
        final session = await _api.startSession(
          apiLang,
          p == MirrorPath.create ? 'create' : 'catalog',
        );
        if (_needsStationKey && !session.storeScoped) {
          // Ключ отозвали уже после проверки на постере: сессию открыл общий
          // каталог. Закрываем её и показываем экран настройки.
          _api.resetSession(session.sessionId).catchError((_) {});
          _setStationBlocked(true, rejected: true);
          return;
        }
        _demo.disableAuto();
        demoActive = false;
        sessionId = session.sessionId;
        menswearAvailable = session.menswearAvailable;
        if (session.storeLabel.isNotEmpty) {
          _storeLabel = session.storeLabel;
          _prefs.setString(_storeLabelKey, session.storeLabel);
        }
      } on KioskApiException {
        _demo.enableAuto();
        _startDemoSession();
      }
    }

    _track('kiosk_session_start', {'store_label': _storeLabel ?? ''});
    _track('kiosk_path_selected', {
      'path': p == MirrorPath.create ? 'create' : 'catalog',
    });

    if (p == MirrorPath.create) {
      _go(MirrorScreen.camera);
    } else {
      // Сначала пол: вещи в каталоге — только этого гардероба. Каталог
      // докачивается, пока человек выбирает.
      _go(MirrorScreen.gender);
      unawaited(loadCatalog());
    }
  }

  void _startDemoSession() {
    demoActive = true;
    final session = _demo.session();
    sessionId = session.sessionId;
    _storeLabel = session.storeLabel;
  }

  // ── Каталог ────────────────────────────────────────────────────────────────

  /// Вещи гардероба выбранного пола (без учёта вкладки).
  List<KioskCatalogItem> get _genderCatalog => [
        for (final i in _catalogAllCache)
          if (kioskFitsGender(i.gender, gender)) i,
      ];

  List<KioskCatalogItem> _applyCategory(List<KioskCatalogItem> all) => [
        for (final i in all)
          if (kioskFitsGender(i.gender, gender) &&
              (category == null || i.category == category))
            i,
      ];

  /// Вкладки каталога для пола — в порядке сборки образа; пустые (в зале
  /// таких вещей нет) прячем, пока каталог не пуст.
  List<KioskLabeled> get catalogTabs {
    final tabs = kioskCatalogTabs(gender);
    final pool = _genderCatalog;
    if (pool.isEmpty) return tabs;
    final present = {for (final i in pool) i.category};
    final nonEmpty = [for (final t in tabs) if (present.contains(t.code)) t];
    return nonEmpty.isEmpty ? tabs : nonEmpty;
  }

  /// Сколько вещей выбрано во вкладке [code] — подсказка, чего в образе нет.
  int pickedIn(String? code) {
    var n = 0;
    for (final i in _catalogAllCache) {
      if (i.category == code && pickedProductIds.contains(i.id)) n++;
    }
    return n;
  }

  /// Человек сам выбрал вкладку каталога. Пока нет — открыта первая по
  /// порядку сборки образа, даже если она появилась позже остальных (каталог
  /// докачивается страницами, и «Верх» мог прийти после «Низа»).
  bool _categoryPicked = false;

  /// Вкладка каталога всегда конкретная: выбранная человеком, пока она есть
  /// среди доступных, иначе первая по порядку сборки образа.
  void _ensureCategory() {
    final tabs = catalogTabs;
    if (tabs.isEmpty) return;
    if (!_categoryPicked || !tabs.any((t) => t.code == category)) {
      category = tabs.first.code;
    }
  }

  void _setCatalogCache(List<KioskCatalogItem> items, {required bool demo}) {
    _catalogAllCache = List.of(items);
    _catalogCacheIsDemo = demo;
  }

  /// Смена категории — мгновенный локальный фильтр по кэшу, без сети.
  void selectCategory(String? code) {
    category = code;
    _categoryPicked = true;
    _ensureCategory();
    catalog = _applyCategory(_catalogAllCache);
    touch();
    _notify();
  }

  /// Общая докачка полного каталога: каждая страница сразу попадает в кэш
  /// (и в витрину, если она открыта). Ошибки сети глотаются — живём на том,
  /// что успело прийти.
  Future<void> _refreshCatalogCache({
    required bool demo,
    required bool Function() cancelled,
  }) async {
    if (_catalogFetchInFlight) return;
    _catalogFetchInFlight = true;

    void apply(List<KioskCatalogItem> items) {
      _setCatalogCache(items, demo: demo);
      if (screen == MirrorScreen.catalog) {
        _ensureCategory();
        catalog = _applyCategory(_catalogAllCache);
      }
      _notify();
    }

    // Освежение идёт страницами, и каждая приносит «всё, что скачано к этому
    // моменту». Полный каталог того же источника этим обрубком не подменяем:
    // иначе на время докачки пропадали целые вкладки (нет «Верха» — каталог
    // открывался с «Низа»). Свежий список встаёт, когда догнал старый или
    // докачался.
    final hadFull = _catalogAllCache.isNotEmpty && _catalogCacheIsDemo == demo;
    List<KioskCatalogItem>? latest;
    void onPage(List<KioskCatalogItem> items) {
      if (_disposed || cancelled()) return;
      latest = items;
      if (hadFull && items.length < _catalogAllCache.length) return;
      latest = null;
      apply(items);
    }

    try {
      if (demo) {
        await _demo.catalog(onPage: onPage, cancelled: cancelled);
      } else {
        await _api.fetchWholeCatalog(onPage, cancelled: cancelled);
      }
      if (!cancelled()) {
        // Докачался и оказался короче прежнего (вещи ушли из зала) — теперь
        // можно: это уже весь каталог, а не его начало.
        final rest = latest;
        if (rest != null && !_disposed) apply(rest);
        _catalogWarmedAt = DateTime.now();
      }
    } catch (_) {
      // Сеть моргнула — показываем кэш/то, что успело прийти; пустое
      // состояние экран отрисует сам.
    } finally {
      _catalogFetchInFlight = false;
      if (_catalogReloadPending && !_disposed) {
        _catalogReloadPending = false;
        if (screen == MirrorScreen.catalog) unawaited(loadCatalog());
      }
    }
  }

  /// Загрузка/освежение ПОЛНОГО каталога зала для витрины. Кэш показывается
  /// сразу, сеть докатывает свежие страницы в фоне (остатки меняются часто).
  Future<void> loadCatalog() async {
    touch();
    final token = ++_catalogRequestToken;
    bool cancelled() => _disposed || token != _catalogRequestToken;

    if (_catalogAllCache.isNotEmpty) {
      _ensureCategory();
      catalog = _applyCategory(_catalogAllCache);
      catalogLoading = false;
    } else {
      catalogLoading = true;
      catalog = [];
    }
    _notify();

    // Прошлая загрузка ещё идёт, но её мог отменить сброс сессии (токен
    // сменился) — тогда перезапустим, когда она закончится, иначе новый
    // покупатель увидит пустой каталог.
    if (_catalogFetchInFlight) {
      _catalogReloadPending = true;
      return;
    }
    await _refreshCatalogCache(demo: demoActive, cancelled: cancelled);
    if (!_disposed) {
      catalogLoading = false;
      _notify();
    }
  }

  /// Прогрев каталога, пока киоск стоит на постере, — без сессии:
  /// `/kiosk/catalog` нужен только ключ устройства. Так витрина каталога
  /// открывается мгновенно, а сцена генерации листает реальные вещи зала.
  /// Демо-каталог (весь маркетплейс) берём лишь когда демо включено
  /// принудительно (показ партнёру): молча подменять каталог бренда чужими
  /// вещами нельзя.
  Future<void> warmCatalog({bool force = false}) async {
    if (_disposed || screen != MirrorScreen.idle || !_active || offline) return;

    await checkStation();
    if (_disposed || stationBlocked || screen != MirrorScreen.idle) return;

    final wantDemo = _demo.forced;
    if (_catalogCacheIsDemo != wantDemo && _catalogAllCache.isNotEmpty) {
      _setCatalogCache(const [], demo: wantDemo);
      _catalogWarmedAt = null;
      _notify();
    }

    final warmedAt = _catalogWarmedAt;
    final fresh = warmedAt != null &&
        DateTime.now().difference(warmedAt) < coverRefreshInterval &&
        _catalogAllCache.isNotEmpty;
    if (!force && fresh) return;

    await _refreshCatalogCache(demo: wantDemo, cancelled: () => _disposed);
    // Пока станция на постере — докачиваем фото каталога на диск, чтобы в
    // каталоге они открывались сразу. Ушли с постера — прогрев уступает сеть.
    unawaited(
      KioskImageCache.prefetch(
        _catalogAllCache.map((i) => i.imageUrl).whereType<String>(),
        cancelled: () => _disposed || screen != MirrorScreen.idle,
      ),
    );
  }

  void _armCoverRefresh() {
    _coverRefreshTimer?.cancel();
    _coverRefreshTimer = null;
    if (_disposed || screen != MirrorScreen.idle || !_active) return;
    _coverRefreshTimer = Timer.periodic(
      coverRefreshInterval,
      (_) => warmCatalog(),
    );
  }

  /// Подсадить каталог в тестах, минуя сеть.
  @visibleForTesting
  void seedCatalogForTest(List<KioskCatalogItem> items, {bool demo = false}) {
    _setCatalogCache(items, demo: demo);
    _catalogWarmedAt = DateTime.now();
    // Как при приходе страницы: открытая витрина пересчитывается.
    if (screen == MirrorScreen.catalog) {
      _ensureCategory();
      catalog = _applyCategory(_catalogAllCache);
    }
    _notify();
  }

  /// Подсадить пачку образов в тестах экрана результата, минуя генерацию.
  @visibleForTesting
  void seedPackForTest(List<KioskLook> looks, {required String current}) {
    _pack
      ..clear()
      ..addEntries(looks.map((l) => MapEntry(l.lookId, l)));
    // Готовые — в порядке списка, как будто дорисовались по очереди; уже
    // известный порядок сохраняем (повторная подсадка в том же тесте).
    _readyOrder.removeWhere((id) => !(_pack[id]?.isCompleted ?? false));
    for (final l in looks) {
      if (l.isCompleted && !_readyOrder.contains(l.lookId)) {
        _readyOrder.add(l.lookId);
      }
    }
    look = _pack[current];
    _completedLook = look;
    _notify();
  }

  void toggleProduct(String id) {
    touch();
    if (pickedProductIds.contains(id)) {
      pickedProductIds.remove(id);
    } else {
      pickedProductIds.add(id);
    }
    _notify();
  }

  void confirmCatalogSelection() {
    _track('kiosk_catalog_items_selected', {
      'count': pickedProductIds.length.toString(),
      'ids': pickedProductIds.join(','),
    });
    if (rebuildingFromCatalog) {
      rebuildingFromCatalog = false;
      attempt += 1;
      _track('kiosk_regenerate', {'attempt': attempt.toString(), 'path': 'catalog'});
      _clearShare();
      startGeneration();
      return;
    }
    _go(MirrorScreen.camera);
  }

  // ── Камера ─────────────────────────────────────────────────────────────────

  void onCameraOpened() => _track('kiosk_camera_opened');

  void onPhotoTaken() => _track('kiosk_photo_taken');

  void onPhotoRetaken() => _track('kiosk_photo_retaken');

  /// Загрузка + серверная валидация снятого кадра. В демо кадр никуда не
  /// уходит: он остаётся на устройстве и служит превью результата.
  Future<KioskPhotoValidation> uploadAndConfirmPhoto(File photo) async {
    await _replacePhoto(photo);
    if (demoActive) {
      const ok = KioskPhotoValidation(
        faceFound: true,
        faceCount: 1,
        faceRatio: 0.3,
      );
      validation = ok;
      return ok;
    }
    final blobKey = await _api.uploadPhoto(sessionId!, photo);
    photoBlobKey = blobKey;
    final result = await _api.confirmPhoto(sessionId!, blobKey);
    validation = result;
    return result;
  }

  Future<void> _replacePhoto(File photo) async {
    final old = capturedPhoto;
    if (old != null && old.path != photo.path) {
      await _deletePhotoFile(old);
    }
    capturedPhoto = photo;
    photoBlobKey = null;
    validation = null;
  }

  void confirmPhoto() {
    _track('kiosk_photo_confirmed', {
      'face_ratio': (validation?.faceRatio ?? 0).toStringAsFixed(2),
      'too_dark': (validation?.tooDark ?? false).toString(),
    });
    // В ветке «из каталога» пол уже выбран перед вещами.
    _go(path == MirrorPath.catalog && gender != null
        ? MirrorScreen.shape
        : MirrorScreen.gender);
  }

  // ── Пол и фигура ───────────────────────────────────────────────────────────

  /// Выбор гардероба — один вопрос с одним ответом, поэтому касание карточки
  /// сразу ведёт к фигуре, без «Продолжить».
  void setGender(String g) {
    if (gender != g) {
      gender = g;
      // Списки фигур и стилей зависят от пола — прежний выбор не имеет смысла.
      bodyShape = null;
      styles.clear();
      // Вещи другого гардероба — тоже.
      pickedProductIds.clear();
    }
    if (path == MirrorPath.catalog) {
      // «Из каталога»: после пола — вещи этого гардероба, с первой вкладки.
      category = null;
      _categoryPicked = false;
      _ensureCategory();
      catalog = _applyCategory(_catalogAllCache);
      _go(MirrorScreen.catalog);
      return;
    }
    _go(MirrorScreen.shape);
  }

  /// Тип фигуры — один ответ, как и пол: касание карточки сразу ведёт дальше
  /// (к стилям, а в ветке «из каталога» — к генерации), без «Продолжить».
  void setShape(String shape) {
    bodyShape = shape;
    confirmProfile();
  }

  /// «Не знаю свой тип фигуры»: фигуру не угадываем — шлём «не знаю» и идём дальше.
  void skipShape() {
    touch();
    bodyShape = kioskShapeUnknown;
    confirmProfile();
  }

  void confirmProfile() {
    _track('kiosk_profile_completed', {
      'gender': gender ?? '',
      'body_shape': bodyShape ?? '',
    });
    if (path == MirrorPath.create) {
      _go(MirrorScreen.style);
    } else {
      startGeneration();
    }
  }

  // ── Стили ──────────────────────────────────────────────────────────────────

  void toggleStyle(String code) {
    touch();
    if (styles.contains(code)) {
      styles.remove(code);
    } else {
      styles.add(code);
    }
    _notify();
  }

  void confirmStyles() {
    _track('kiosk_style_selected', {'styles': styles.join(',')});
    _go(MirrorScreen.brand);
  }

  // ── Бренд ──────────────────────────────────────────────────────────────────

  /// Мультивыбор брендов. «Все бренды» ([kioskAnyBrand]) исключает остальные:
  /// касание по нему снимает отдельные бренды, касание по бренду — снимает «все».
  void toggleShopBrand(String code) {
    touch();
    if (code == kioskAnyBrand) {
      final wasAll = shopBrands.contains(kioskAnyBrand);
      shopBrands.clear();
      if (!wasAll) shopBrands.add(kioskAnyBrand);
    } else {
      shopBrands.remove(kioskAnyBrand);
      if (!shopBrands.remove(code)) shopBrands.add(code);
    }
    _notify();
  }

  void confirmShopBrand() {
    if (shopBrands.isEmpty) return;
    _track('kiosk_brand_selected', {'brand': shopBrands.join(',')});
    _go(MirrorScreen.colors);
  }

  /// `brand` для бэкенда: один бренд — его код, несколько или все —
  /// [kioskAnyBrand] (контракт с одним брендом). Сам список — в [_apiBrands].
  String? get _apiBrand => switch (shopBrands.length) {
        0 => null,
        1 => shopBrands.first,
        _ => kioskAnyBrand,
      };

  List<String>? get _apiBrands =>
      shopBrands.isEmpty || shopBrands.contains(kioskAnyBrand)
          ? null
          : List.of(shopBrands);

  // ── Цвета, которых не должно быть ──────────────────────────────────────────

  void toggleAvoidColor(String code) {
    touch();
    if (!avoidColors.remove(code)) avoidColors.add(code);
    _notify();
  }

  /// [skip] — «Пропустить»: отмеченное не учитываем, показываем все цвета.
  void confirmColors({bool skip = false}) {
    if (skip) avoidColors.clear();
    _track('kiosk_colors_excluded', {'colors': avoidColors.join(',')});
    startGeneration();
  }

  // ── «Пересобрать» с уточнениями ─────────────────────────────────────────────

  void setFaceLiked(bool liked) {
    touch();
    faceLiked = liked;
    _notify();
  }

  /// Пересобрать образ с уточнениями ([reasons] — любые из [kioskRefineOrder],
  /// пусто — «просто пересобрать»; «Дешевле» и «Дороже» вместе не бывают).
  /// [styles] и [brands] заменяют выбор человека, [colors] — цвета, которых не
  /// должно быть (вдобавок к исключённым на шаге цветов).
  void rebuild({
    Set<String> reasons = const {},
    List<String> colors = const [],
    List<String>? styles,
    Set<String>? brands,
  }) {
    if (!canRegenerate) return;
    assert(!(reasons.contains('CHEAPER') && reasons.contains('PRICIER')));
    refineKinds
      ..clear()
      ..addAll(kioskRefineOrder.where(reasons.contains));
    excludeColors
      ..clear()
      ..addAll(colors);
    if (styles != null && styles.isNotEmpty) {
      this.styles
        ..clear()
        ..addAll(styles);
    }
    if (brands != null && brands.isNotEmpty) {
      shopBrands
        ..clear()
        ..addAll(brands);
    }
    attempt += 1;
    _baseLookId = look?.lookId;
    _track('kiosk_regenerate', {
      'attempt': attempt.toString(),
      'refine': refineKinds.join(','),
      'face_liked': faceLiked?.toString() ?? '',
    });
    _clearShare();
    startGeneration();
  }

  // ── Генерация ──────────────────────────────────────────────────────────────

  Future<void> startGeneration() async {
    final genId = ++_genId;
    bool stale() => _disposed || genId != _genId;
    _stopGeneration();
    genFailed = false;
    genReason = null;
    resultReady = false;
    _completedLook = null;
    generatingItems = const [];
    _pack.clear();
    _readyOrder.clear();
    elapsedSec = 0;
    _go(MirrorScreen.generating);

    _track('kiosk_generation_started', {
      'path': path == MirrorPath.create ? 'create' : 'catalog',
      'attempt': attempt.toString(),
    });

    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSec += 1;
      if (elapsedSec >= failAfterSec && !genFailed && !resultReady) {
        _onGenerationFailed('TIMEOUT');
        return;
      }
      _notify();
    });

    if (demoActive) {
      _demoGenTimer = Timer(KioskDemoService.generationDuration, () async {
        try {
          final demoLook = await _demo.look(
            pickedIds: pickedProductIds,
            attempt: attempt,
            photoPath: capturedPhoto?.path,
            baseCatalog: _catalogAllCache,
          );
          if (stale()) return;
          _onGenerationCompleted(demoLook);
        } catch (_) {
          if (!stale()) _onGenerationFailed('DEMO_FAILED');
        }
      });
      return;
    }

    try {
      final created = await _api.createLook(
        sessionId: sessionId!,
        gender: gender!,
        bodyShape: bodyShape!,
        styles: path == MirrorPath.create ? List.of(styles) : null,
        productIds:
            path == MirrorPath.catalog ? List.of(pickedProductIds) : null,
        brand: path == MirrorPath.create ? _apiBrand : null,
        brands: path == MirrorPath.create ? _apiBrands : null,
        refine: refineKind,
        refines: refineKinds.length > 1 ? List.of(refineKinds) : null,
        excludeColors: {...avoidColors, ...excludeColors}.toList(),
        faceLiked: faceLiked,
        // Пачка — только в ветке «создать»: из каталога человек сам выбрал
        // вещи, и варианты отличались бы от них лишь досыпанным.
        variants: path == MirrorPath.create ? lookVariants : null,
        baseLookId: _baseLookId,
      );
      if (stale() || screen != MirrorScreen.generating) return;
      // Вещи образа известны уже по ответу на создание — экран генерации
      // показывает их, пока картинка рисуется.
      if (created.items.isNotEmpty) {
        generatingItems = created.items;
        _notify();
      }
      look = created;
      // Порядок пачки — как у бэкенда: первый образ, затем варианты. До
      // первого опроса вариант известен только по id.
      _pack[created.lookId] = created;
      for (final id in created.variantIds) {
        _pack[id] = KioskLook(lookId: id, status: KioskLookStatus.pending);
      }
      if (created.isTerminal) _onPackLook(created);
      for (final id in _pack.keys.toList()) {
        if (_pack[id]!.isTerminal) continue;
        _watches.add(
          _api.watchLook(
            id,
            onProgress: (l) {
              if (stale()) return;
              _pack[id] = l;
              // Сцена генерации листает вещи первого образа.
              if (id == created.lookId && _completedLook == null) {
                look = l;
                if (l.items.isNotEmpty) generatingItems = l.items;
              }
              _notify();
            },
            onDone: (l) {
              if (stale()) return;
              _onPackLook(l);
            },
          ),
        );
      }
    } on KioskApiException catch (e) {
      if (stale()) return;
      _onGenerationFailed(e.code ?? (e.isNetwork ? 'NETWORK' : 'FAILED'));
    }
  }

  /// Образ пачки дошёл до конца. Первый готовый открывает результат; следующие
  /// появляются в переключателе уже на нём. Ошибка — только когда упали все.
  void _onPackLook(KioskLook l) {
    _pack[l.lookId] = l;
    if (l.isCompleted) {
      if (!_readyOrder.contains(l.lookId)) _readyOrder.add(l.lookId);
      final url = l.resultImageUrl;
      if (url != null) _resultUrls.add(url);
      if (_completedLook == null) {
        _onGenerationCompleted(l);
      } else {
        _track('kiosk_variant_ready', {'look_id': l.lookId});
        _notify();
      }
      return;
    }
    if (_completedLook == null && _pack.values.every((v) => v.isTerminal)) {
      // Причина — первого образа пачки: она и есть ответ на запрос человека.
      final first = _pack.values.first;
      _onGenerationFailed(first.failureReason ?? l.failureReason ?? 'FAILED');
      return;
    }
    _notify();
  }

  /// Показать другой готовый образ пачки. Код и QR — для выбранного: продавец
  /// должен получить ровно тот образ, что человек видит.
  void selectLook(String lookId) {
    final next = _pack[lookId];
    if (next == null || !next.isCompleted || next.lookId == look?.lookId) return;
    look = next;
    _completedLook = next;
    touch();
    _track('kiosk_variant_selected', {'look_id': lookId});
    _clearShare();
    ensureShare();
    _notify();
  }

  void _onGenerationCompleted(KioskLook l) {
    if (screen != MirrorScreen.generating) return;
    // Остальные образы пачки продолжают генерироваться — их опрос оставляем.
    _stopGeneration(keepElapsed: true, keepWatches: true);
    look = l;
    _completedLook = l;
    // Вещи на экране генерации уже показаны (первого образа пачки) — на
    // последней секунде их не подменяем, даже если первым дорисовался вариант.
    if (generatingItems.isEmpty && l.items.isNotEmpty) generatingItems = l.items;
    _pack.putIfAbsent(l.lookId, () => l);
    if (!_readyOrder.contains(l.lookId)) _readyOrder.add(l.lookId);
    final url = l.resultImageUrl;
    if (url != null) _resultUrls.add(url);
    resultReady = true;
    // Демо отвечает по таймеру — время станции учим только по настоящим.
    if (!demoActive && elapsedSec > 0) {
      final avg = _prefs.getDouble(_genAvgKey);
      final next = avg == null ? elapsedSec.toDouble() : avg * 0.6 + elapsedSec * 0.4;
      _prefs.setDouble(_genAvgKey, next.clamp(20.0, 180.0));
    }
    _track('kiosk_generation_completed', {
      'look_id': l.lookId,
      'elapsed': elapsedSec.toString(),
    });
    _notify();
  }

  void _onGenerationFailed(String reason) {
    if (screen != MirrorScreen.generating) return;
    _stopGeneration(keepElapsed: true);
    _track('kiosk_generation_failed', {'reason': reason});

    // Демо-фолбэка в настоящей сессии нет: демо выдаёт снятое фото за «образ» и
    // придумывает код продавца, которого нет на сервере. Человеку у стенда —
    // честный экран ошибки с повтором.

    genFailed = true;
    genReason = reason;
    _armIdleTimer();
    // Даже провал должен вести в приложение: пробуем получить QR (мягко —
    // не получится, экран покажет текстовую подсказку).
    ensureShare();
    _notify();
  }

  /// Экран генерации зовёт после precache картинки — чтобы результат
  /// проявлялся из размытия, а не грузился на глазах.
  void revealResult() {
    if (_completedLook == null) return;
    resultReady = false;
    _go(MirrorScreen.result);
    _track('kiosk_result_viewed');
    ensureShare();
  }

  void cancelGeneration() {
    _genId++; // запоздавший ответ отменённой генерации не откроет результат
    _track('kiosk_generation_cancelled', {'elapsed': elapsedSec.toString()});
    _stopGeneration();
    if (path == MirrorPath.create) {
      _go(MirrorScreen.style);
    } else {
      _go(MirrorScreen.catalog);
    }
  }

  void retryGeneration() {
    // Повтор после ошибки — не пересборка: attempt не растёт.
    startGeneration();
  }

  void regenerate() {
    if (!canRegenerate) return;
    if (path == MirrorPath.catalog) {
      // Из каталога «Пересобрать» — это выбрать другие вещи, а не тот же образ
      // заново. Попытка засчитается, когда человек подтвердит новый выбор.
      rebuildingFromCatalog = true;
      _go(MirrorScreen.catalog);
      return;
    }
    // Ветка «создать»: сначала спрашиваем, что изменить (дешевле, цвет, бренд…).
    _go(MirrorScreen.refine);
  }

  /// Код и QR выданы для прошлого образа — снимаем их сразу, чтобы новый
  /// результат не показался со старым QR. ensureShare на новом результате
  /// запросит свежие (до этого — шиммер, «Отложить» ждёт код).
  void _clearShare() {
    _shareRetryTimer?.cancel();
    _shareRetryTimer = null;
    _shareRetries = 0;
    sellerCode = null;
    shareUrl = null;
    _sharedLookId = null;
  }

  void _stopGeneration({bool keepElapsed = false, bool keepWatches = false}) {
    if (!keepWatches) {
      for (final watch in _watches) {
        watch.close();
      }
      _watches.clear();
    }
    _elapsedTicker?.cancel();
    _elapsedTicker = null;
    _demoGenTimer?.cancel();
    _demoGenTimer = null;
    if (!keepElapsed) elapsedSec = 0;
  }

  // ── Результат / примерка ───────────────────────────────────────────────────

  /// Код и QR — обязательный финал сессии. Если finish упал, тихо пробуем
  /// снова каждые 5 секунд, пока человек на результате.
  Future<void> ensureShare() async {
    final id = sessionId;
    // Код и QR уже выданы именно для показанного образа — делать нечего. После
    // «Пересобрать» образ другой: finish нужно вызвать заново, иначе QR вёл бы на первый.
    final lookId = _completedLook?.lookId;
    if (id == null || _disposed || _shareInFlight) return;
    if (shareUrl != null && _sharedLookId == lookId) return;
    _shareInFlight = true;
    var lookChanged = false;
    try {
      final finish = demoActive
          ? _demo.finish()
          : await _api.finishSession(id, lookId: lookId);
      // Пока ждали ответ, сессия могла смениться (сброс по бездействию) — тогда
      // код и QR принадлежат прошлому покупателю.
      if (_disposed || sessionId != id) return;
      // Человек успел выбрать другой образ пачки: этот ответ — про прошлый.
      if (_completedLook?.lookId != lookId) {
        lookChanged = true;
        return;
      }
      sellerCode = finish.code;
      shareUrl = finish.shareUrl;
      _sharedLookId = lookId;
      _shareRetries = 0;
      _shareRetryTimer?.cancel();
      _shareRetryTimer = null;
      _notify();
    } catch (_) {
      if (_disposed || sessionId != id) return;
      // Не бесконечно: на экране ошибки без готового образа сервер всегда отвечает 422.
      if (_shareRetries++ < 3) {
        _shareRetryTimer?.cancel();
        _shareRetryTimer = Timer(const Duration(seconds: 5), ensureShare);
      }
    } finally {
      _shareInFlight = false;
      if (lookChanged) unawaited(ensureShare());
    }
  }

  void openBuy() {
    _track('kiosk_buy_opened', {'code': sellerCode ?? ''});
    ensureShare();
    _go(MirrorScreen.buy);
  }

  // ── Навигация ──────────────────────────────────────────────────────────────

  void _go(MirrorScreen next) {
    screen = next;
    touch();
    _notify();
  }

  void goBack() {
    switch (screen) {
      case MirrorScreen.catalog when rebuildingFromCatalog && look != null:
        // Передумал пересобирать — обратно к готовому образу, сессия жива.
        rebuildingFromCatalog = false;
        _go(MirrorScreen.result);
      case MirrorScreen.idle:
        hardReset('manual');
      case MirrorScreen.catalog:
        // «Из каталога» начинается с пола: назад — к нему.
        _go(MirrorScreen.gender);
      case MirrorScreen.generating:
        cancelGeneration();
      case MirrorScreen.camera:
        // Ветка «создать» начинается с камеры: назад — это на постер.
        if (path == MirrorPath.create) {
          hardReset('manual');
        } else {
          _go(MirrorScreen.catalog);
        }
      case MirrorScreen.gender:
        // «Из каталога» с пола начинается — назад на постер.
        if (path == MirrorPath.catalog) {
          hardReset('manual');
        } else {
          _go(MirrorScreen.camera);
        }
      case MirrorScreen.shape:
        _go(path == MirrorPath.catalog ? MirrorScreen.camera : MirrorScreen.gender);
      case MirrorScreen.style:
        _go(MirrorScreen.shape);
      case MirrorScreen.brand:
        _go(MirrorScreen.style);
      case MirrorScreen.colors:
        _go(MirrorScreen.brand);
      case MirrorScreen.refine:
        _go(MirrorScreen.result);
      case MirrorScreen.result:
        _go(
          path == MirrorPath.create ? MirrorScreen.style : MirrorScreen.catalog,
        );
      case MirrorScreen.buy:
        _go(MirrorScreen.result);
    }
  }

  // ── Бездействие ────────────────────────────────────────────────────────────

  /// Любое касание экрана перезаряжает таймер бездействия.
  void touch() {
    if (idleWarning) {
      idleWarning = false;
      _graceTicker?.cancel();
      _graceTicker = null;
      _notify();
    }
    _armIdleTimer();
  }

  void _armIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (screen == MirrorScreen.idle || !_active) return;
    // Генерация идёт около минуты, и человек экран не трогает: без паузы «вы ещё
    // здесь?» всплывало посреди ожидания и сбрасывало сессию. На ошибке таймер нужен.
    if (screen == MirrorScreen.generating && !genFailed) return;
    _idleTimer = Timer(idleTimeout, _onIdleTimeout);
  }

  void _onIdleTimeout() {
    if (screen == MirrorScreen.idle) return;
    idleWarning = true;
    idleLeft = idleGraceSeconds;
    _notify();
    _graceTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      idleLeft -= 1;
      if (idleLeft <= 0) {
        hardReset('timeout');
      } else {
        _notify();
      }
    });
  }

  /// Пауза киоска (продавец ушёл на другой таб / приложение свернулось).
  /// Сессию не сбрасываем — покупатель может стоять у планшета.
  void setActive(bool active) {
    _active = active;
    if (active) {
      _armIdleTimer();
      _armCoverRefresh();
      warmCatalog();
    } else {
      _idleTimer?.cancel();
      _idleTimer = null;
      _coverRefreshTimer?.cancel();
      _coverRefreshTimer = null;
    }
  }

  // ── Полный сброс ───────────────────────────────────────────────────────────

  /// Полная зачистка сессии: файл фото с диска, битмапы из кэша, сессию на
  /// бэкенде. Её же вызывает «Завершить» в шапке любого экрана.
  Future<void> hardReset(String reason) async {
    final hadSession = sessionId != null;
    if (hadSession) {
      _track(
        reason == 'timeout' ? 'kiosk_session_timeout' : 'kiosk_session_reset',
        {'screen': screen.name},
      );
      final id = sessionId!;
      if (!demoActive) {
        // fire-and-forget: бэкенд удаляет фото немедленно
        _api.resetSession(id).catchError((_) {});
      }
    }

    _stopGeneration();
    _idleTimer?.cancel();
    _idleTimer = null;
    _graceTicker?.cancel();
    _graceTicker = null;
    _shareRetryTimer?.cancel();
    _shareRetryTimer = null;

    final photo = capturedPhoto;
    if (photo != null) await _deletePhotoFile(photo);
    await _evictResultImages();
    _demo.resetLook();

    sessionId = null;
    menswearAvailable = true;
    // Загрузка каталога идёт — дотянем после неё; следующий покупатель
    // увидит полную витрину.
    if (_catalogFetchInFlight) _catalogReloadPending = true;
    demoActive = false;
    gender = null;
    bodyShape = null;
    styles.clear();
    pickedProductIds.clear();
    shopBrands.clear();
    avoidColors.clear();
    faceLiked = null;
    refineKinds.clear();
    excludeColors.clear();
    catalog = [];
    catalogLoading = false;
    category = null;
    _categoryPicked = false;
    _catalogRequestToken++;
    capturedPhoto = null;
    photoBlobKey = null;
    validation = null;
    look = null;
    _completedLook = null;
    generatingItems = const [];
    _pack.clear();
    _readyOrder.clear();
    _baseLookId = null;
    resultReady = false;
    elapsedSec = 0;
    genFailed = false;
    genReason = null;
    attempt = 0;
    rebuildingFromCatalog = false;
    sellerCode = null;
    shareUrl = null;
    _sharedLookId = null;
    _shareRetries = 0;
    _genId++;
    idleWarning = false;
    idleLeft = idleGraceSeconds;
    // Язык не сбрасываем: «Назад» с камеры, «Завершить» и тайм-аут оставляют
    // выбранный. Меняется он только выбором или сменой бренда без такого языка.
    shopperLang = _langFor(brand, shopperLang);

    screen = MirrorScreen.idle;
    _notify();

    // Киоск снова на постере: освежаем каталог зала к следующей сессии.
    _armCoverRefresh();
    warmCatalog();
  }

  Future<void> _deletePhotoFile(File photo) async {
    try {
      await FileImage(photo).evict();
    } catch (_) {}
    try {
      if (await photo.exists()) await photo.delete();
    } catch (_) {}
  }

  Future<void> _evictResultImages() async {
    final urls = {
      ..._resultUrls,
      if (look?.resultImageUrl != null) look!.resultImageUrl!,
      if (_completedLook?.resultImageUrl != null)
        _completedLook!.resultImageUrl!,
    };
    _resultUrls.clear();
    for (final url in urls) {
      if (!url.startsWith('http')) continue;
      try {
        await CachedNetworkImageProvider(url).evict();
      } catch (_) {}
      try {
        await DefaultCacheManager().removeFile(url);
      } catch (_) {}
    }
  }

  /// Оффлайн-флаг ставит MirrorTab по стриму connectivity_plus.
  void setOffline(bool value) {
    if (offline == value) return;
    offline = value;
    _notify();
    if (!value) {
      _armCoverRefresh();
      warmCatalog();
    }
  }

  /// Сменить оформление. Сессия покупателя, если была, закрывается: вещи,
  /// подписи и язык по умолчанию у брендов разные.
  Future<void> setBrand(MirrorBrand next) async {
    if (next.id == _brand.id) return;
    _track('kiosk_brand_selected', {'brand': next.id});
    _brand = next;
    await hardReset('brand');
    // hardReset прогревает каталог только на активном табе; блокировку
    // оформления без ключа ставим (и снимаем) в любом случае.
    await checkStation();
  }

  /// Язык для бэкенда. Киоск-API рассчитан на RU/UZ; английский экран
  /// киоска отправляет русский, чтобы сессия не упала на неизвестном языке.
  String get apiLang => shopperLang == 'uz' ? 'uz' : 'ru';

  void setShopperLang(String code) {
    shopperLang = code;
    _prefs.setString(_langKey, code);
    touch();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopGeneration();
    _idleTimer?.cancel();
    _graceTicker?.cancel();
    _shareRetryTimer?.cancel();
    _coverRefreshTimer?.cancel();
    final photo = capturedPhoto;
    if (photo != null) {
      // ignore: discarded_futures
      _deletePhotoFile(photo);
    }
    super.dispose();
  }
}
