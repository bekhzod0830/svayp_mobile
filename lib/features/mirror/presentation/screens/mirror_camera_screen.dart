import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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

enum _CamPhase { live, countdown, captured, uploading }

/// Экран 1 — камера (только лицо). USB-камера зеркала по умолчанию, затем
/// фронталка (см. [pickKioskCamera]); круглая рамка
/// цветом бренда, отсчёт 3-2-1, превью с «Переснять»/«Готово». Серверная
/// валидация мягкая: блокирует только «лицо не найдено», остальные подсказки
/// показываются полторы секунды и пропускают дальше.
class MirrorCameraScreen extends StatefulWidget {
  const MirrorCameraScreen({
    super.key,
    required this.controller,
    required this.cameraAllowed,
    this.preferredCamera,
  });

  final MirrorSessionController controller;

  /// false, когда продавец ушёл с таба — индикатор записи не должен гореть.
  final bool cameraAllowed;

  /// Камера, выбранная продавцом в шите настройки; null — автовыбор.
  final String? preferredCamera;

  @override
  State<MirrorCameraScreen> createState() => _MirrorCameraScreenState();
}

class _MirrorCameraScreenState extends State<MirrorCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  bool _initialized = false;
  bool _initFailed = false;
  // Разрешение отклонено (навсегда) — показываем кнопку «Открыть настройки»,
  // это действие продавца, покупатель сам в настройки не полезет.
  bool _permissionDenied = false;
  bool _frontCamera = true;

  /// Внешняя USB-камера смотрит на покупателя, но плагин зеркалит превью
  /// только фронталке — зеркалим сами.
  bool _externalCamera = false;

  _CamPhase _phase = _CamPhase.live;
  int _countdown = 3;
  Timer? _countdownTimer;

  /// Автозапуск отсчёта: камера готова — через паузу «3-2-1» стартует сам,
  /// кнопка «Сфотографировать» остаётся запасным ручным путём.
  Timer? _autoStartTimer;
  static const _autoStartDelay = Duration(milliseconds: 1400);
  File? _shot;
  // Кадр из галереи не зеркалим — он уже «как есть», в отличие от фронталки.
  bool _shotFromGallery = false;

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
    if (widget.cameraAllowed) _initCamera();
  }

  @override
  void didUpdateWidget(covariant MirrorCameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cameraAllowed != oldWidget.cameraAllowed) {
      widget.cameraAllowed ? _initCamera() : _teardownCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _teardownCamera();
    } else if (state == AppLifecycleState.resumed && widget.cameraAllowed) {
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
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      // Явно просим разрешение: системный диалог при первом заходе, а не
      // молчаливый экран «нет доступа».
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        setState(() {
          _initFailed = true;
          _permissionDenied = true;
        });
        return;
      }

      final cameras = await availableCameras();
      if (!mounted) return;
      final chosen = pickKioskCamera(
        cameras,
        preferredName: widget.preferredCamera,
      );
      if (chosen == null) {
        // Пусто и с разрешением — Android не видит ни одной камеры
        // (симулятор, или USB-камеру планшет не поддерживает).
        setState(() => _initFailed = true);
        return;
      }
      _frontCamera = chosen.lensDirection == CameraLensDirection.front;
      _externalCamera = chosen.lensDirection == CameraLensDirection.external;

      final prev = _camera;
      if (prev != null) await prev.dispose();

      final controller = CameraController(
        chosen,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _camera = controller;
      await controller.initialize();
      if (mounted) {
        setState(() {
          _initialized = true;
          _initFailed = false;
          _permissionDenied = false;
        });
        _scheduleAutoCountdown();
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _initFailed = true;
          _permissionDenied = e.code.toLowerCase().contains('accessdenied') ||
              e.code.toLowerCase().contains('permission');
        });
      }
    } catch (_) {
      if (mounted) setState(() => _initFailed = true);
    }
  }

  void _teardownCamera() {
    _countdownTimer?.cancel();
    _autoStartTimer?.cancel();
    _camera?.dispose();
    _camera = null;
    if (mounted) {
      setState(() {
        _initialized = false;
        if (_phase == _CamPhase.countdown) _phase = _CamPhase.live;
      });
    }
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
      _countdown = 3;
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

  /// Шаг отсчёта; вся полоса рамки проходит за [_countdownTick] × 3.
  static const _countdownTick = Duration(milliseconds: 1000);

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      setState(() => _phase = _CamPhase.live);
      return;
    }
    try {
      final xfile = await camera.takePicture();
      // Кадр — собственность контроллера сессии: копия в temp живёт до
      // hardReset (обещание «удалится через 15 минут» исполняется буквально).
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/mirror_face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = await File(xfile.path).copy(path);
      try {
        await File(xfile.path).delete();
      } catch (_) {}
      widget.controller.onPhotoTaken();
      if (mounted) {
        setState(() {
          _shot = file;
          _shotFromGallery = false;
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
          _shotFromGallery = true;
          _error = null;
          _softHint = null;
          _phase = _CamPhase.captured;
        });
      }
    } catch (_) {
      // Галерея недоступна/отменена — остаёмся на камере.
    }
  }

  /// Кадр, который так и не ушёл в контроллер, — удаляем: на экране обещано, что
  /// фото не останется. Отправленный кадр принадлежит контроллеру, он удалит его сам.
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
      _shotFromGallery = false;
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
        widget.controller.confirmPhoto();
        return;
      }
      // Мягкие подсказки не блокируют (веб-паритет): показываем полторы
      // секунды — и дальше. Фаза остаётся uploading, чтобы «Готово» не ушло
      // на повторную загрузку.
      setState(() => _softHint = soft);
      _softHintTimer?.cancel();
      _softHintTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) widget.controller.confirmPhoto();
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
    final hintText = _error ??
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
                          captured && _shot != null
                              ? Transform.flip(
                                  // Зеркалим показ кадра с фронталки или
                                  // USB-камеры зеркала — человек
                                  // видит себя как в зеркале; в бэкенд уходит
                                  // оригинал.
                                  flipX: (_frontCamera || _externalCamera) &&
                                      !_shotFromGallery,
                                  child: Image.file(_shot!, fit: BoxFit.cover),
                                )
                              : _initialized && _camera != null
                                  ? Transform.flip(
                                      flipX: _externalCamera,
                                      child:
                                          _CoverPreview(controller: _camera!),
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
                  // Рама: во время отсчёта линия цвета бренда обегает арку
                  // ровно за три секунды — как прогресс на экране генерации.
                  Positioned.fromRect(
                    rect: arch.inflate(mirrorFrameInset(t.mirror, s)),
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(counting),
                        tween: Tween(begin: counting ? 0 : 1, end: 1),
                        duration: counting ? _countdownTick * 3 : Duration.zero,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14 * s,
                    color: t.muted,
                  ),
                  SizedBox(width: 6 * s),
                  Flexible(
                    child: Text(
                      l10n.mirrorPrivacyShort,
                      style: t.subtitle(13 * s),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * s),
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
                  onTap:
                      _phase == _CamPhase.uploading ? null : _pickFromGallery,
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

/// Превью камеры, заполняющее круг без искажений (cover).
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    // Камера отдаёт landscape-отношение; в портрете оно инвертируется.
    final raw = controller.value.aspectRatio;
    final portrait = raw > 1 ? 1 / raw : raw;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: 1000 * portrait,
        height: 1000,
        child: CameraPreview(controller),
      ),
    );
  }
}
