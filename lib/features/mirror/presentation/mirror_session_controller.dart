import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analytics/analytics_service.dart';
import '../data/kiosk_api.dart';
import '../data/kiosk_demo.dart';
import '../data/kiosk_models.dart';

/// Экраны киоска. Пол и фигура — два отдельных экрана (решение владельца),
/// но делят один сегмент прогресса.
enum MirrorScreen {
  idle,
  intro,
  camera,
  gender,
  shape,
  style,
  catalog,
  generating,
  result,
  buy,
}

enum MirrorPath { create, catalog }

/// Отправка события аналитики. Подменяется в тестах: настоящий сервис при
/// создании обращается к Firebase.
typedef KioskEventLogger = Future<void> Function(
  String name, {
  Map<String, String>? parameters,
});

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
    KioskEventLogger? logEvent,
  })  : _api = api,
        _demo = demo,
        _prefs = prefs,
        _logEvent = logEvent {
    _storeLabel = _prefs.getString(_storeLabelKey);
  }

  static const _storeLabelKey = 'kiosk_store_label';
  static const idleTimeout = Duration(seconds: 45);
  static const idleGraceSeconds = 10;
  static const maxRegenerations = 3;
  // Киоск генерирует на quality=low: замер 20–35 c. Бюджет ML — 75 c (плюс очередь),
  // наш порог выше, чтобы обычно первым приходил честный отказ сервера.
  static const int reassureAfterSec = 35;
  static const int failAfterSec = 90;

  final KioskApi _api;
  final KioskDemoService _demo;
  final SharedPreferences _prefs;
  final KioskEventLogger? _logEvent;

  // ── Состояние ──────────────────────────────────────────────────────────────
  MirrorScreen screen = MirrorScreen.idle;
  MirrorPath path = MirrorPath.create;

  /// Язык покупателя — локален для киоска, не трогает язык приложения продавца.
  String shopperLang = 'ru';

  String? sessionId;
  String? _storeLabel;

  /// Показывать ли кнопку «Мужчина»: мужская одежда в зале есть не всегда.
  bool menswearAvailable = true;
  bool demoActive = false;

  String? gender;
  String? bodyShape;
  final List<String> styles = [];
  final List<String> pickedProductIds = [];

  List<KioskCatalogItem> catalog = [];
  bool catalogLoading = false;
  String? category;
  int _catalogRequestToken = 0;

  /// Полный каталог зала, закэшированный на время работы приложения.
  /// Товары не персональные, поэтому кэш переживает hardReset — следующий
  /// покупатель видит витрину мгновенно; свежесть обеспечивает фоновое
  /// обновление при каждом входе в каталог.
  List<KioskCatalogItem> _catalogAllCache = [];
  bool _catalogFetchInFlight = false;

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

  /// Сброс пришёл, пока каталог грузился: перезагрузить, когда текущая загрузка кончится.
  bool _catalogReloadPending = false;

  KioskLookWatch? _watch;
  Timer? _idleTimer;
  Timer? _graceTicker;
  Timer? _elapsedTicker;
  Timer? _demoGenTimer;
  Timer? _shareRetryTimer;

  String? get storeLabel => _storeLabel;
  KioskApi get api => _api;
  KioskDemoService get demoService => _demo;

  int get regenerationsLeft =>
      (maxRegenerations - attempt).clamp(0, maxRegenerations);

  bool get canRegenerate =>
      attempt < maxRegenerations && (look?.canRegenerate ?? true);

  /// Индекс сегмента прогресса (всегда 4 сегмента, независимо от ветки).
  int get stepIndex {
    if (path == MirrorPath.create) {
      switch (screen) {
        case MirrorScreen.camera:
          return 0;
        case MirrorScreen.gender:
        case MirrorScreen.shape:
          return 1;
        case MirrorScreen.style:
          return 2;
        default:
          return 3;
      }
    }
    switch (screen) {
      case MirrorScreen.catalog:
        return 0;
      case MirrorScreen.camera:
        return 1;
      case MirrorScreen.gender:
      case MirrorScreen.shape:
        return 2;
      default:
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
    (_logEvent ?? AnalyticsService.instance.logEvent)(event, parameters: {
      if (sessionId != null) 'kiosk_session_id': sessionId!,
      'demo': demoActive.toString(),
      ...?params,
    });
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
    touch();

    if (_demo.forced) {
      _startDemoSession();
    } else {
      try {
        final session =
            await _api.startSession(shopperLang, p == MirrorPath.create ? 'create' : 'catalog');
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
      _go(MirrorScreen.intro);
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

  /// Смена категории — мгновенный локальный фильтр по кэшу, без сети.
  void selectCategory(String? code) {
    category = code;
    catalog = _applyCategory(_catalogAllCache);
    touch();
    _notify();
  }

  /// Загрузка/освежение ПОЛНОГО каталога зала. Кэш показывается сразу,
  /// сеть докатывает свежие страницы в фоне (остатки меняются часто).
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

    if (_catalogFetchInFlight) {
      _catalogReloadPending = true;
      return;
    }
    _catalogFetchInFlight = true;

    void onPage(List<KioskCatalogItem> items) {
      if (_disposed) return;
      _catalogAllCache = List.of(items);
      catalog = _applyCategory(_catalogAllCache);
      _notify();
    }

    try {
      if (demoActive) {
        await _demo.catalog(onPage: onPage, cancelled: cancelled);
      } else {
        await _api.fetchWholeCatalog(onPage, cancelled: cancelled);
      }
    } catch (_) {
      // Сеть моргнула — показываем кэш/то, что успело прийти; пустое
      // состояние экран отрисует сам.
    } finally {
      _catalogFetchInFlight = false;
      if (!_disposed) {
        catalogLoading = false;
        _notify();
      }
      // Сброс/смена ветки во время загрузки: прошлая загрузка отменилась по токену,
      // а новая сразу вышла на флаге — без перезапуска новый покупатель видел пусто.
      if (_catalogReloadPending && !_disposed) {
        _catalogReloadPending = false;
        if (screen == MirrorScreen.catalog) loadCatalog();
      }
    }
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
    _go(MirrorScreen.camera);
  }

  // ── Камера ─────────────────────────────────────────────────────────────────

  /// «Начать» с интро-экрана.
  void proceedToCamera() => _go(MirrorScreen.camera);

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

  void setGender(String g) {
    touch();
    if (gender != g) {
      gender = g;
      // Списки фигур и стилей зависят от пола — прежний выбор не имеет смысла.
      bodyShape = null;
      styles.clear();
    }
    _notify();
    _go(MirrorScreen.shape);
  }

  void setShape(String shape) {
    touch();
    bodyShape = shape;
    _notify();
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
    attempt += 1;
    _track('kiosk_regenerate', {'attempt': attempt.toString()});
    startGeneration();
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
      case MirrorScreen.intro:
      case MirrorScreen.catalog:
        hardReset('manual');
      case MirrorScreen.generating:
        cancelGeneration();
      case MirrorScreen.camera:
        _go(path == MirrorPath.create ? MirrorScreen.intro : MirrorScreen.catalog);
      case MirrorScreen.gender:
        _go(MirrorScreen.camera);
      case MirrorScreen.shape:
        _go(MirrorScreen.gender);
      case MirrorScreen.style:
        _go(MirrorScreen.shape);
      case MirrorScreen.result:
        _go(path == MirrorPath.create ? MirrorScreen.style : MirrorScreen.catalog);
      case MirrorScreen.buy:
        _go(MirrorScreen.result);
      default:
        hardReset('manual');
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
    } else {
      _idleTimer?.cancel();
      _idleTimer = null;
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
    // Загрузка каталога идёт — дотянем после неё; следующий покупатель увидит полную витрину.
    if (_catalogFetchInFlight) _catalogReloadPending = true;
    demoActive = false;
    gender = null;
    bodyShape = null;
    styles.clear();
    pickedProductIds.clear();
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
    sellerCode = null;
    shareUrl = null;
    _sharedLookId = null;
    _shareRetries = 0;
    _genId++;
    idleWarning = false;
    idleLeft = idleGraceSeconds;
    // Новый покупатель не должен наследовать язык предыдущего.
    shopperLang = 'ru';

    screen = MirrorScreen.idle;
    _notify();
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
      if (_completedLook?.resultImageUrl != null) _completedLook!.resultImageUrl!,
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
  }

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
    final photo = capturedPhoto;
    if (photo != null) {
      // ignore: discarded_futures
      _deletePhotoFile(photo);
    }
    super.dispose();
  }
}
