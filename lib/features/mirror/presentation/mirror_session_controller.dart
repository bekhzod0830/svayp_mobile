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

  /// «Где вы любите покупать?» — бренд или «любой» (только ветка «создать»).
  brand,
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
    shopperLang = brand.defaultLang;
  }

  static const _storeLabelKey = 'kiosk_store_label';
  /// Окно «Вы ещё здесь?» — после 20 с без касаний (задачи по планшетам, 07.10.2026).
  static const idleTimeout = Duration(seconds: 20);
  static const idleGraceSeconds = 10;
  static const maxRegenerations = 3;
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

  /// Бренд с шага «Где вы любите покупать?»: код ([kioskShopBrands]),
  /// [kioskAnyBrand] — любой, null — ещё не выбран.
  String? shopBrand;

  /// «Понравилось ли вам лицо?» на экране уточнений; null — не отвечал.
  bool? faceLiked;

  /// Уточнение последней пересборки (CHEAPER | PRICIER | COLOR | BRAND | STYLE) и
  /// цвета, которых не должно быть. Живут до следующей пересборки: повтор после
  /// ошибки шлёт тот же запрос.
  String? refineKind;
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

  KioskLook? look;
  KioskLook? _completedLook;
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

  KioskLookWatch? _watch;
  Timer? _idleTimer;
  Timer? _graceTicker;
  Timer? _elapsedTicker;
  Timer? _demoGenTimer;
  Timer? _shareRetryTimer;

  String? get storeLabel => _storeLabel;
  KioskApi get api => _api;
  KioskDemoService get demoService => _demo;

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
          return 2;
        case MirrorScreen.generating:
        case MirrorScreen.result:
        case MirrorScreen.refine:
        case MirrorScreen.buy:
          return 3;
      }
    }
    switch (screen) {
      case MirrorScreen.idle:
      case MirrorScreen.catalog:
        return 0;
      case MirrorScreen.camera:
        return 1;
      case MirrorScreen.gender:
      case MirrorScreen.shape:
      case MirrorScreen.style:
      case MirrorScreen.brand:
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

  // ── Старт сессии ───────────────────────────────────────────────────────────

  bool _beginning = false;

  /// Вход с постера. При недоступном бэкенде — демо-режим, а не ошибка:
  /// показ партнёру важнее (паритет с веб-киоском). Но если сети нет совсем,
  /// оффлайн-оверлей выигрывает (его ставит MirrorTab).
  Future<void> begin(MirrorPath p) async {
    // Двойное касание CTA не должно открыть две сессии.
    if (_beginning || screen != MirrorScreen.idle) return;
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
      _go(MirrorScreen.catalog);
      loadCatalog();
    }
  }

  void _startDemoSession() {
    demoActive = true;
    final session = _demo.session();
    sessionId = session.sessionId;
    _storeLabel = session.storeLabel;
  }

  // ── Каталог ────────────────────────────────────────────────────────────────

  List<KioskCatalogItem> _applyCategory(List<KioskCatalogItem> all) =>
      category == null
          ? List.of(all)
          : all.where((i) => i.category == category).toList();

  void _setCatalogCache(List<KioskCatalogItem> items, {required bool demo}) {
    _catalogAllCache = List.of(items);
    _catalogCacheIsDemo = demo;
  }

  /// Смена категории — мгновенный локальный фильтр по кэшу, без сети.
  void selectCategory(String? code) {
    category = code;
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

    void onPage(List<KioskCatalogItem> items) {
      if (_disposed || cancelled()) return;
      _setCatalogCache(items, demo: demo);
      if (screen == MirrorScreen.catalog) {
        catalog = _applyCategory(_catalogAllCache);
      }
      _notify();
    }

    try {
      if (demo) {
        await _demo.catalog(onPage: onPage, cancelled: cancelled);
      } else {
        await _api.fetchWholeCatalog(onPage, cancelled: cancelled);
      }
      if (!cancelled()) _catalogWarmedAt = DateTime.now();
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
    _go(MirrorScreen.gender);
  }

  // ── Пол и фигура ───────────────────────────────────────────────────────────

  /// Выбор гардероба. Переход — только по «Продолжить» ([confirmGender]): случайное
  /// касание не должно уводить на следующий экран (дизайн станции).
  void setGender(String g) {
    touch();
    if (gender != g) {
      gender = g;
      // Списки фигур и стилей зависят от пола — прежний выбор не имеет смысла.
      bodyShape = null;
      styles.clear();
    }
    _notify();
  }

  void confirmGender() {
    if (gender == null) return;
    _go(MirrorScreen.shape);
  }

  void setShape(String shape) {
    touch();
    bodyShape = shape;
    _notify();
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

  void chooseShopBrand(String code) {
    touch();
    shopBrand = code;
    _notify();
  }

  void confirmShopBrand() {
    if (shopBrand == null) return;
    _track('kiosk_brand_selected', {'brand': shopBrand!});
    startGeneration();
  }

  // ── «Пересобрать» с уточнениями ─────────────────────────────────────────────

  void setFaceLiked(bool liked) {
    touch();
    faceLiked = liked;
    _notify();
  }

  /// Пересобрать образ с уточнением ([kind] — CHEAPER | PRICIER | COLOR | BRAND |
  /// STYLE; null — «просто пересобрать»). [style] и [brand] меняют выбор человека
  /// (стиль — один, из списка), [colors] — цвета, которых не должно быть.
  void rebuild(
    String? kind, {
    List<String> colors = const [],
    String? style,
    String? brand,
  }) {
    if (!canRegenerate) return;
    refineKind = kind;
    excludeColors
      ..clear()
      ..addAll(colors);
    if (style != null) {
      styles
        ..clear()
        ..add(style);
    }
    if (brand != null) shopBrand = brand;
    attempt += 1;
    _track('kiosk_regenerate', {
      'attempt': attempt.toString(),
      'refine': kind ?? '',
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
        brand: path == MirrorPath.create ? shopBrand : null,
        refine: refineKind,
        excludeColors: List.of(excludeColors),
        faceLiked: faceLiked,
      );
      if (stale() || screen != MirrorScreen.generating) return;
      if (created.isTerminal) {
        created.status == KioskLookStatus.completed
            ? _onGenerationCompleted(created)
            : _onGenerationFailed(created.failureReason ?? 'FAILED');
        return;
      }
      look = created;
      _watch = _api.watchLook(
        created.lookId,
        onProgress: (l) {
          if (stale()) return;
          look = l;
          _notify();
        },
        onDone: (l) {
          if (stale()) return;
          l.status == KioskLookStatus.completed
              ? _onGenerationCompleted(l)
              : _onGenerationFailed(l.failureReason ?? 'FAILED');
        },
      );
    } on KioskApiException catch (e) {
      if (stale()) return;
      _onGenerationFailed(e.code ?? (e.isNetwork ? 'NETWORK' : 'FAILED'));
    }
  }

  void _onGenerationCompleted(KioskLook l) {
    if (screen != MirrorScreen.generating) return;
    _stopGeneration(keepElapsed: true);
    look = l;
    _completedLook = l;
    final url = l.resultImageUrl;
    if (url != null) _resultUrls.add(url);
    resultReady = true;
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

  void _stopGeneration({bool keepElapsed = false}) {
    _watch?.close();
    _watch = null;
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
    try {
      final finish = demoActive ? _demo.finish() : await _api.finishSession(id);
      // Пока ждали ответ, сессия могла смениться (сброс по бездействию) — тогда
      // код и QR принадлежат прошлому покупателю.
      if (_disposed || sessionId != id) return;
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
      case MirrorScreen.catalog:
        hardReset('manual');
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
        _go(MirrorScreen.camera);
      case MirrorScreen.shape:
        _go(MirrorScreen.gender);
      case MirrorScreen.style:
        _go(MirrorScreen.shape);
      case MirrorScreen.brand:
        _go(MirrorScreen.style);
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

  /// Полная зачистка сессии. Обещание «фото удалится» написано на экране —
  /// исполняем буквально: файл с диска, битмапы из кэша, сессию на бэкенде.
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
    shopBrand = null;
    faceLiked = null;
    refineKind = null;
    excludeColors.clear();
    catalog = [];
    catalogLoading = false;
    category = null;
    _catalogRequestToken++;
    capturedPhoto = null;
    photoBlobKey = null;
    validation = null;
    look = null;
    _completedLook = null;
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
    // Новый покупатель не должен наследовать язык предыдущего.
    shopperLang = brand.defaultLang;

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
  }

  /// Язык для бэкенда. Киоск-API рассчитан на RU/UZ; английский экран
  /// киоска отправляет русский, чтобы сессия не упала на неизвестном языке.
  String get apiLang => shopperLang == 'uz' ? 'uz' : 'ru';

  void setShopperLang(String code) {
    shopperLang = code;
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
