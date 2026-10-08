import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ffi_uvc/flutter_ffi_uvc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_api.dart';
import '../../data/kiosk_camera.dart';
import '../../data/kiosk_models.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_arch.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_camera_feed.dart';

enum _CamPhase { live, countdown, captured, uploading }

/// Экран 1 — камера (только лицо). USB-камера зеркала по умолчанию, затем
/// фронталка (см. [rankKioskCameras]); если первая не завелась, пробуется
/// следующая. Рамка цветом бренда, отсчёт 5-4-3-2-1, превью с
/// «Переснять»/«Готово». Серверная валидация мягкая: блокирует только
/// «лицо не найдено», остальные подсказки показываются полторы секунды и
/// пропускают дальше.
class MirrorCameraScreen extends StatefulWidget {
  const MirrorCameraScreen({
    super.key,
    required this.controller,
    required this.cameraAllowed,
    this.preferredCamera,
    this.uvcMaxWidth = kUvcMaxWidth,
    this.showDiagnostics = false,
  });

  final MirrorSessionController controller;

  /// false, когда продавец ушёл с таба — индикатор записи не должен гореть.
  final bool cameraAllowed;

  /// Камера, выбранная продавцом в шите настройки; null — автовыбор.
  final String? preferredCamera;

  /// Планка качества USB-камеры напрямую (ширина кадра), из шита настройки.
  final int uvcMaxWidth;

  /// Диагностика потока мелким текстом в углу (тумблер в шите настройки).
  final bool showDiagnostics;

  @override
  State<MirrorCameraScreen> createState() => _MirrorCameraScreenState();
}

class _MirrorCameraScreenState extends State<MirrorCameraScreen>
    with WidgetsBindingObserver {
  MirrorCameraFeed? _feed;
  bool _initialized = false;
  bool _initFailed = false;
  // Разрешение отклонено (навсегда) — показываем кнопку «Открыть настройки»,
  // это действие продавца, покупатель сам в настройки не полезет.
  bool _permissionDenied = false;

  /// Почему камера не завелась — мелким текстом под ошибкой, чтобы продавец
  /// мог переслать, не подключая планшет к компьютеру.
  String? _failReason;

  /// Номер запуска камеры: resume, смена таба и втыкание USB могут
  /// накладываться — доигрывает только последний.
  int _initSeq = 0;
  bool _initInFlight = false;

  /// Втыкание/выдёргивание USB-камеры: подхватываем без перезапуска.
  StreamSubscription<UvcDeviceEvent>? _usbSub;

  /// Раз в секунду перерисовывает диагностику, пока она включена.
  Timer? _diagTimer;

  /// Лента, которая сейчас запускается (ещё не [_feed]). Уходя с экрана,
  /// закрываем и её — иначе запуск, переживший экран, держал камеру занятой
  /// (горит индикатор), и следующий экран камеры её уже не открывал.
  MirrorCameraFeed? _starting;

  /// Сторож камеры: замечает зависший запуск и вставший поток и сам
  /// перезапускает камеру, не дожидаясь продавца.
  Timer? _watchdog;
  DateTime? _initStartedAt;
  int? _lastFrameCount;
  DateTime? _framesStalledSince;
  int _autoRestarts = 0;
  static const _maxAutoRestarts = 3;
  static const _stallLimit = Duration(seconds: 5);
  static const _initLimit = Duration(seconds: 90);

  _CamPhase _phase = _CamPhase.live;
  int _countdown = _countdownFrom;
  Timer? _countdownTimer;

  /// Автозапуск отсчёта: камера готова — через паузу отсчёт стартует сам,
  /// кнопка «Сфотографировать» остаётся запасным ручным путём.
  Timer? _autoStartTimer;
  static const _autoStartDelay = Duration(milliseconds: 1400);
  File? _shot;

  /// Жёсткая ошибка (лицо не найдено, фото не ушло) — блокирует.
  String? _error;

  /// Мягкая подсказка бэкенда (несколько лиц, темно, далеко) — не блокирует:
  /// показывается перед переходом дальше.
  String? _softHint;
  Timer? _softHintTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.onCameraOpened();
    if (Platform.isAndroid) {
      try {
        _usbSub = uvcCamera.deviceEvents.listen(_onUsbEvent);
      } catch (_) {
        // Плагина нет (не Android-сборка) — просто без автоподхвата.
      }
    }
    if (widget.cameraAllowed) _initCamera();
    _syncDiagTimer();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) => _checkCamera());
  }

  /// Раз в секунду: запуск не идёт дольше [_initLimit], поток живой. Кадры
  /// не приходят [_stallLimit] (индикатор камеры горит, а картинки нет) —
  /// перезапуск. Подряд не больше [_maxAutoRestarts] раз, дальше — экран
  /// ошибки с кнопкой «Повторить», а не вечный цикл.
  void _checkCamera() {
    if (!mounted || !widget.cameraAllowed) return;
    final now = DateTime.now();
    final startedAt = _initStartedAt;
    if (_initInFlight &&
        startedAt != null &&
        now.difference(startedAt) > _initLimit) {
      _autoRestart('start hung');
      return;
    }
    final feed = _feed;
    if (!_initialized || feed == null) return;
    final frames = feed.frameCount;
    if (frames == null) return;
    if (frames != _lastFrameCount) {
      _lastFrameCount = frames;
      _framesStalledSince = null;
      // Кадры идут — счётчик автоперезапусков обнуляем.
      if (frames > 0) _autoRestarts = 0;
      return;
    }
    _framesStalledSince ??= now;
    if (now.difference(_framesStalledSince!) > _stallLimit) {
      _autoRestart('no frames');
    }
  }

  void _autoRestart(String reason) {
    debugPrint('[mirror/camera] auto restart: $reason');
    _framesStalledSince = null;
    _lastFrameCount = null;
    if (_autoRestarts >= _maxAutoRestarts) {
      _teardownCamera();
      if (mounted) {
        setState(() {
          _initFailed = true;
          _failReason = reason;
        });
      }
      return;
    }
    _autoRestarts++;
    _teardownCamera();
    // Зависший запуск держит очередь запусков этого экрана — начинаем новую.
    _initChain = Future.value();
    _initCamera();
  }

  void _syncDiagTimer() {
    if (widget.showDiagnostics) {
      _diagTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _initialized) setState(() {});
      });
    } else {
      _diagTimer?.cancel();
      _diagTimer = null;
    }
  }

  void _onUsbEvent(UvcDeviceEvent event) {
    if (!widget.cameraAllowed || !mounted) return;
    switch (event.type) {
      case UvcDeviceEventType.attached:
        // Воткнули камеру: если сейчас работаем не с USB напрямую (или
        // вообще без камеры) — переоткрываем, она в приоритете.
        if (_feed?.option.kind != KioskCameraKind.uvc) {
          setState(() {
            _initFailed = false;
            _permissionDenied = false;
          });
          _initCamera();
        }
      case UvcDeviceEventType.detached:
        final current = _feed?.option.uvc;
        if (current != null && current.deviceId == event.device.deviceId) {
          // Плагин сам закроет устройство следом; нам — переоткрыться на
          // том, что осталось (встроенная), либо честно показать «нет камеры».
          _initCamera();
        }
    }
  }

  @override
  void didUpdateWidget(covariant MirrorCameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDiagTimer();
    if (widget.cameraAllowed != oldWidget.cameraAllowed) {
      widget.cameraAllowed ? _initCamera() : _teardownCamera();
    } else if (widget.cameraAllowed &&
        (widget.preferredCamera != oldWidget.preferredCamera ||
            widget.uvcMaxWidth != oldWidget.uvcMaxWidth)) {
      // Продавец поменял камеру или качество в шите — применяем сразу.
      _initCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Гасим камеру, только когда приложение реально ушло с экрана. На
    // `inactive` — нет: его даёт любой системный диалог, включая запрос
    // разрешения на камеру и на USB-устройство, а выключать камеру под
    // диалогом «разрешить USB?» значит отменять сам запрос.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _teardownCamera();
    } else if (state == AppLifecycleState.resumed &&
        widget.cameraAllowed &&
        _feed == null &&
        !_initInFlight) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _discardShot();
    _countdownTimer?.cancel();
    _autoStartTimer?.cancel();
    _softHintTimer?.cancel();
    _diagTimer?.cancel();
    _watchdog?.cancel();
    _usbSub?.cancel();
    _initSeq++;
    _starting?.dispose();
    _starting = null;
    _feed?.dispose();
    _feed = null;
    super.dispose();
  }

  /// Запуски камеры идут строго друг за другом. Две смены настройки подряд
  /// (поворот 90° и обратно) иначе стартуют параллельно: второй пытается
  /// открыть USB-устройство, пока первый его ещё держит, получает «занято»
  /// и киоск остаётся без камеры.
  Future<void> _initCamera() {
    final previous = _initChain;
    final task = previous.then((_) => _initCameraNow());
    _initChain = task.catchError((_) {});
    return task;
  }

  Future<void> _initChain = Future.value();

  Future<void> _initCameraNow() async {
    if (!mounted || !widget.cameraAllowed) return;
    final seq = ++_initSeq;
    bool stale() => !mounted || seq != _initSeq;

    _initInFlight = true;
    _initStartedAt = DateTime.now();
    _lastFrameCount = null;
    _framesStalledSince = null;
    try {
      // Явно просим разрешение: системный диалог при первом заходе, а не
      // молчаливый экран «нет доступа». USB напрямую в нём не нуждается,
      // поэтому отказ блокирует только встроенные камеры.
      final status = await Permission.camera.request();
      if (stale()) return;

      // Сначала только USB напрямую. Камерный сервис Android видит ту же
      // Rapoo как камеру №1; его опрос (availableCameras) поднимает CameraX,
      // и тот дёргается на каждое наше открытие и закрытие Rapoo — лишняя
      // возня вокруг того же устройства (в логах планшета — его внутренние
      // ошибки). Камеры Android спрашиваем, только если продавец выбрал
      // именно такую, USB-камеры нет или она не завелась.
      final preferred = widget.preferredCamera;
      final preferAndroid = preferred != null && !preferred.startsWith('uvc:');
      Future<List<KioskCameraOption>> list({
        required bool uvc,
        required bool android,
      }) =>
          listKioskCameras(
            includeUvc: uvc,
            androidAllowed: android && status.isGranted,
          ).timeout(const Duration(seconds: 8), onTimeout: () => const []);

      var androidListed = preferAndroid;
      var cameras = await list(uvc: true, android: preferAndroid);
      if (stale()) return;
      if (cameras.isEmpty && !androidListed) {
        androidListed = true;
        cameras = await list(uvc: false, android: true);
        if (stale()) return;
      }
      var ranked = rankKioskCameras(cameras, preferredId: preferred);

      // Прежняя лента уходит в любом случае: даже если камер не осталось
      // (выдернули единственную), мёртвое превью висеть не должно.
      final prev = _feed;
      _feed = null;
      if (_initialized) setState(() => _initialized = false);
      if (prev != null) await prev.dispose();
      if (stale()) return;

      if (ranked.isEmpty) {
        // Ни одной камеры: симулятор, или USB-камера не воткнута, или
        // без разрешения на встроенную.
        setState(() {
          _initFailed = true;
          _permissionDenied = !status.isGranted;
        });
        return;
      }

      // Первая, что завелась, и остаётся: UVC напрямую может не отдать
      // кадры (режим согласовался, поток пустой), тогда очередь за встроенной.
      final errors = <String>[];
      Future<MirrorCameraFeed?> firstThatStarts(
        List<KioskCameraOption> options,
      ) async {
        for (final option in options) {
          final feed = MirrorCameraFeed.create(
            option,
            uvcMaxWidth: widget.uvcMaxWidth,
          );
          _starting = feed;
          try {
            await feed.start();
          } catch (e) {
            debugPrint('[mirror/camera] ${option.label}: start failed: $e');
            errors.add('${option.label}: $e');
            if (identical(_starting, feed)) _starting = null;
            await feed.dispose();
            if (stale()) return null;
            continue;
          }
          if (identical(_starting, feed)) _starting = null;
          if (stale()) {
            await feed.dispose();
            return null;
          }
          return feed;
        }
        return null;
      }

      var started = await firstThatStarts(ranked);
      if (stale()) return;
      if (started == null && !androidListed && status.isGranted) {
        // USB напрямую не завелась — запасной путь через камеры Android.
        ranked = rankKioskCameras(
          await list(uvc: false, android: true),
          preferredId: preferred,
        );
        if (stale()) return;
        started = await firstThatStarts(ranked);
        if (stale()) return;
      }
      if (started == null) {
        setState(() {
          _initFailed = true;
          _permissionDenied = !status.isGranted;
          _failReason = errors.join('\n');
        });
        return;
      }
      _feed = started;
      setState(() {
        _initialized = true;
        _initFailed = false;
        _permissionDenied = false;
        _failReason = null;
      });
      _scheduleAutoCountdown();
    } catch (e) {
      if (!stale()) {
        setState(() {
          _initFailed = true;
          _failReason = '$e';
        });
      }
    } finally {
      if (seq == _initSeq) _initInFlight = false;
    }
  }

  void _teardownCamera() {
    // Запуск, что шёл, становится «чужим»; его ленту закрываем сразу —
    // закрытие прерывает запуск, и камера освобождается, а не ждёт его конца.
    _initSeq++;
    _initInFlight = false;
    _initStartedAt = null;
    _countdownTimer?.cancel();
    _autoStartTimer?.cancel();
    _starting?.dispose();
    _starting = null;
    _feed?.dispose();
    _feed = null;
    if (mounted) {
      setState(() {
        _initialized = false;
        if (_phase == _CamPhase.countdown) _phase = _CamPhase.live;
      });
    }
  }

  /// Фото принято — камера больше не нужна. Закрываем её ещё на этом экране,
  /// пока превью на месте, а не когда экран уже исчез: следующий покупатель
  /// получает свободную камеру.
  void _releaseCameraAndContinue() {
    _watchdog?.cancel();
    _teardownCamera();
    widget.controller.confirmPhoto();
  }

  void _scheduleAutoCountdown() {
    _autoStartTimer?.cancel();
    if (!_initialized || _phase != _CamPhase.live || _shot != null) return;
    _autoStartTimer = Timer(_autoStartDelay, () {
      if (mounted) _startCountdown();
    });
  }

  void _startCountdown() {
    _autoStartTimer?.cancel();
    if (!_initialized || _phase != _CamPhase.live) return;
    setState(() {
      _phase = _CamPhase.countdown;
      _countdown = _countdownFrom;
      _error = null;
      _softHint = null;
    });
    _countdownTimer = Timer.periodic(_countdownTick, (t) {
      if (!mounted) return;
      if (_countdown <= 1) {
        t.cancel();
        _capture();
      } else {
        setState(() => _countdown -= 1);
      }
    });
  }

  /// Шаг отсчёта; вся полоса рамки проходит за [_countdownTick] × [_countdownFrom].
  static const _countdownTick = Duration(milliseconds: 1000);

  /// С какого числа идёт отсчёт: 5 с — успеть встать и поправиться (задачи по
  /// планшетам, 07.10.2026; было 3).
  static const _countdownFrom = 5;

  Future<void> _capture() async {
    final feed = _feed;
    if (feed == null || !_initialized) {
      setState(() => _phase = _CamPhase.live);
      return;
    }
    try {
      // Кадр — собственность контроллера сессии: файл в temp живёт до
      // hardReset, затем удаляется.
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/mirror_face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = await feed.capture(path);
      widget.controller.onPhotoTaken();
      if (mounted) {
        setState(() {
          _shot = file;
          _phase = _CamPhase.captured;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _phase = _CamPhase.live);
    }
  }

  /// Загрузка готового фото из галереи — человек выбирает лучший кадр,
  /// дальше тот же путь: подтверждение → валидация лица → вопросы.
  Future<void> _pickFromGallery() async {
    _autoStartTimer?.cancel();
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/mirror_face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = await File(picked.path).copy(path);
      // Копия у нас — исходник во временной папке image_picker удаляем сразу.
      try {
        await File(picked.path).delete();
      } catch (_) {}
      widget.controller.onPhotoTaken();
      if (mounted) {
        setState(() {
          _shot = file;
          _error = null;
          _softHint = null;
          _phase = _CamPhase.captured;
        });
      }
    } catch (_) {
      // Галерея недоступна/отменена — остаёмся на камере.
    }
  }

  /// Кадр, который так и не ушёл в контроллер, — удаляем: фото покупателя не
  /// должно оставаться на планшете. Отправленный кадр принадлежит контроллеру,
  /// он удалит его сам.
  void _discardShot() {
    final shot = _shot;
    if (shot == null || shot.path == widget.controller.capturedPhoto?.path) {
      return;
    }
    shot.delete().catchError((_) => shot);
  }

  void _retake() {
    _softHintTimer?.cancel();
    widget.controller.onPhotoRetaken();
    _discardShot();
    setState(() {
      _shot = null;
      _error = null;
      _softHint = null;
      _phase = _CamPhase.live;
    });
    // «Переснять» — снова сам отсчитает.
    _scheduleAutoCountdown();
  }

  Future<void> _confirm() async {
    final shot = _shot;
    if (shot == null || _phase == _CamPhase.uploading) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _phase = _CamPhase.uploading;
      _error = null;
      _softHint = null;
    });
    try {
      final validation = await widget.controller.uploadAndConfirmPhoto(shot);
      if (!mounted) return;
      if (!validation.faceFound) {
        // Единственный жёсткий блок: без лица дальше нельзя.
        setState(() {
          _phase = _CamPhase.captured;
          _error = l10n.mirrorFaceNotFound;
        });
        return;
      }
      final soft = _softHintFor(validation, l10n);
      if (soft == null) {
        _releaseCameraAndContinue();
        return;
      }
      // Мягкие подсказки не блокируют (веб-паритет): показываем полторы
      // секунды — и дальше. Фаза остаётся uploading, чтобы «Готово» не ушло
      // на повторную загрузку.
      setState(() => _softHint = soft);
      _softHintTimer?.cancel();
      _softHintTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) _releaseCameraAndContinue();
      });
    } on KioskApiException {
      if (!mounted) return;
      setState(() {
        _phase = _CamPhase.captured;
        _error = l10n.mirrorUploadFailed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _CamPhase.captured;
        _error = l10n.mirrorUploadFailed;
      });
    }
  }

  /// FACE_NOT_FOUND обрабатывается отдельно как блок; остальное — совет.
  String? _softHintFor(KioskPhotoValidation v, AppLocalizations l10n) {
    switch (v.hint) {
      case 'MULTIPLE_FACES':
        return l10n.mirrorFaceMultiple;
      case 'MOVE_CLOSER':
        return l10n.mirrorFaceCloser;
      case 'TOO_DARK':
        return l10n.mirrorFaceTooDark;
    }
    if (v.faceCount > 1) return l10n.mirrorFaceMultiple;
    if (v.tooDark) return l10n.mirrorFaceTooDark;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    // Камера недоступна, но кадр ещё не выбран: даём путь через галерею
    // (это же спасает симулятор без камеры).
    if (_initFailed &&
        _phase != _CamPhase.captured &&
        _phase != _CamPhase.uploading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40 * s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_outlined, size: 48 * s, color: t.muted),
              SizedBox(height: 20 * s),
              Text(
                l10n.mirrorCamNoAccess,
                textAlign: TextAlign.center,
                style: t.headline(24 * s),
              ),
              if (_failReason != null) ...[
                SizedBox(height: 8 * s),
                Text(
                  _failReason!,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: t.subtitle(12 * s),
                ),
              ],
              SizedBox(height: 24 * s),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 360 * s),
                child: MirrorPrimaryButton(
                  label: l10n.mirrorUpload,
                  height: 56 * s,
                  onTap: _pickFromGallery,
                ),
              ),
              SizedBox(height: 12 * s),
              if (_permissionDenied)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 360 * s),
                  child: MirrorGhostButton(
                    label: l10n.mirrorOpenSettings,
                    height: 56 * s,
                    onTap: () => openAppSettings(),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 360 * s),
                  child: MirrorGhostButton(
                    label: l10n.mirrorGenRetry,
                    height: 56 * s,
                    onTap: () {
                      setState(() {
                        _initFailed = false;
                        _permissionDenied = false;
                      });
                      _autoRestarts = 0;
                      _initChain = Future.value();
                      _initCamera();
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final captured =
        _phase == _CamPhase.captured || _phase == _CamPhase.uploading;
    final hintText =
        _error ??
        _softHint ??
        (captured ? l10n.mirrorCamDoneHint : l10n.mirrorCamLook);
    final hintColor = _error != null
        ? t.danger
        : _softHint != null
        ? t.accent
        : t.muted;

    // Отступы колонки плотные: самый тесный экран киоска, от него считается
    // общий размер стекла (см. mirrorGlassSize).
    return Column(
      children: [
        SizedBox(height: 8 * s),
        Text(
          captured ? l10n.mirrorCamDone : l10n.mirrorCamAim,
          textAlign: TextAlign.center,
          style: t.headline(26 * s),
        ),
        SizedBox(height: 4 * s),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: t.subtitle(15 * s, color: hintColor),
          textAlign: TextAlign.center,
          child: Text(hintText),
        ),
        SizedBox(height: 8 * s),
        Expanded(
          // То же зеркало, что на постере, генерации и результате: человек
          // видит себя в той же раме, в которой потом «проявится» образ.
          child: LayoutBuilder(
            builder: (context, box) {
              final arch = mirrorGlassRect(context, box.biggest);
              final counting = _phase == _CamPhase.countdown;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: MirrorArchHaloPainter(
                        arch: arch,
                        color: t.glow,
                        strength: 0.2,
                        shape: t.mirror,
                        s: s,
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: arch,
                    child: ClipPath(
                      clipper: MirrorArchClipper(t.mirror),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Живое превью остаётся в дереве и под готовым
                          // снимком: пока камера отдаёт кадры, их должен
                          // кто-то забирать с текстуры. Снятое с экрана
                          // превью при работающем потоке — подозреваемый в
                          // «камера горит, а картинки нет» после снимка.
                          _initialized && _feed != null
                              ? Transform.flip(
                                  flipX: _feed!.previewNeedsFlip,
                                  child: _feed!.buildPreview(),
                                )
                              : ColoredBox(
                                  color: t.surface,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: t.primary,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                          // Снимок уже отражён при съёмке (см.
                          // MirrorCameraFeed.capture) — показываем как есть,
                          // он совпадает с живым превью.
                          if (captured && _shot != null)
                            Image.file(_shot!, fit: BoxFit.cover),
                          if (counting)
                            ColoredBox(
                              color: Colors.black.withValues(alpha: 0.25),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (child, a) =>
                                      ScaleTransition(
                                        scale: Tween(
                                          begin: 1.4,
                                          end: 1.0,
                                        ).animate(a),
                                        child: FadeTransition(
                                          opacity: a,
                                          child: child,
                                        ),
                                      ),
                                  child: Text(
                                    '$_countdown',
                                    key: ValueKey(_countdown),
                                    style: t.display(
                                      96 * s,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.showDiagnostics &&
                      _initialized &&
                      _feed != null &&
                      !captured)
                    Positioned(
                      left: arch.left + 8,
                      bottom: box.biggest.height - arch.bottom + 8,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_feed!.diagnostics()}\n'
                            'арка ${arch.width.round()}x${arch.height.round()} '
                            'лог. px · экран '
                            '${MediaQuery.sizeOf(context).width.round()}x'
                            '${MediaQuery.sizeOf(context).height.round()} '
                            '@${MediaQuery.devicePixelRatioOf(context).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              height: 1.3,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Рама: во время отсчёта линия цвета бренда обегает арку
                  // ровно за время отсчёта — как прогресс на экране генерации.
                  Positioned.fromRect(
                    rect: arch.inflate(mirrorFrameInset(t.mirror, s)),
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(counting),
                        tween: Tween(begin: counting ? 0 : 1, end: 1),
                        duration: counting ? _countdownTick * _countdownFrom : Duration.zero,
                        builder: (context, p, _) => CustomPaint(
                          painter: MirrorArchFramePainter(
                            shape: t.mirror,
                            progress: p,
                            track: t.hairline,
                            color: t.primary,
                            glow: 0.5,
                            s: s,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 8 * s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28 * s),
          child: Column(
            children: [
              SizedBox(height: 6 * s),
              if (!captured) ...[
                MirrorPrimaryButton(
                  label: l10n.mirrorShoot,
                  height: 64 * s,
                  enabled: _initialized && _phase == _CamPhase.live,
                  onTap: _startCountdown,
                ),
                SizedBox(height: 4 * s),
                // Галерея — тихой ссылкой: главный путь — снимок у
                // зеркала, но готовое фото тоже подойдёт.
                MirrorTextButton(
                  label: l10n.mirrorFromGallery,
                  height: 36 * s,
                  color: t.muted,
                  onTap: _phase == _CamPhase.live ? _pickFromGallery : null,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: MirrorGhostButton(
                        label: l10n.mirrorRetake,
                        height: 64 * s,
                        enabled: _phase != _CamPhase.uploading,
                        onTap: _retake,
                      ),
                    ),
                    SizedBox(width: 14 * s),
                    Expanded(
                      child: MirrorPrimaryButton(
                        label: l10n.mirrorDone,
                        height: 64 * s,
                        isLoading: _phase == _CamPhase.uploading,
                        onTap: _confirm,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * s),
                // После снимка тоже можно взять фото из галереи — так же
                // тихо, чтобы не спорить с «Переснять» и «Готово».
                MirrorTextButton(
                  label: l10n.mirrorFromGallery,
                  height: 36 * s,
                  color: t.muted,
                  onTap: _phase == _CamPhase.uploading
                      ? null
                      : _pickFromGallery,
                ),
              ],
              SizedBox(height: 12 * s),
            ],
          ),
        ),
      ],
    );
  }
}
