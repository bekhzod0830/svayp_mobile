import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_api.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';

enum _CamPhase { live, countdown, captured, uploading }

/// Экран 2 — камера (только лицо). Фронталка по умолчанию, круглая рамка,
/// отсчёт 3-2-1, превью с «Переснять»/«Готово». Серверная валидация мягкая:
/// блокирует только «лицо не найдено», остальное — предупреждает и пропускает.
class MirrorCameraScreen extends StatefulWidget {
  const MirrorCameraScreen({
    super.key,
    required this.controller,
    required this.cameraAllowed,
  });

  final MirrorSessionController controller;

  /// false, когда продавец ушёл с таба — индикатор записи не должен гореть.
  final bool cameraAllowed;

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

  _CamPhase _phase = _CamPhase.live;
  int _countdown = 3;
  Timer? _countdownTimer;
  File? _shot;
  // Кадр из галереи не зеркалим — он уже «как есть», в отличие от фронталки.
  bool _shotFromGallery = false;
  String? _hint;

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
    _countdownTimer?.cancel();
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
      if (!mounted || cameras.isEmpty) {
        // Пусто и с разрешением — камеры физически нет (например, симулятор).
        if (mounted) setState(() => _initFailed = true);
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _frontCamera = front.lensDirection == CameraLensDirection.front;

      final prev = _camera;
      if (prev != null) await prev.dispose();

      final controller = CameraController(
        front,
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
    _camera?.dispose();
    _camera = null;
    if (mounted) {
      setState(() {
        _initialized = false;
        if (_phase == _CamPhase.countdown) _phase = _CamPhase.live;
      });
    }
  }

  void _startCountdown() {
    if (!_initialized || _phase != _CamPhase.live) return;
    setState(() {
      _phase = _CamPhase.countdown;
      _countdown = 3;
      _hint = null;
    });
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) return;
      if (_countdown <= 1) {
        t.cancel();
        _capture();
      } else {
        setState(() => _countdown -= 1);
      }
    });
  }

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
      widget.controller.onPhotoTaken();
      if (mounted) {
        setState(() {
          _shot = file;
          _shotFromGallery = true;
          _hint = null;
          _phase = _CamPhase.captured;
        });
      }
    } catch (_) {
      // Галерея недоступна/отменена — остаёмся на камере.
    }
  }

  void _retake() {
    widget.controller.onPhotoRetaken();
    setState(() {
      _shot = null;
      _shotFromGallery = false;
      _hint = null;
      _phase = _CamPhase.live;
    });
  }

  Future<void> _confirm() async {
    final shot = _shot;
    if (shot == null || _phase == _CamPhase.uploading) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _phase = _CamPhase.uploading;
      _hint = null;
    });
    try {
      final validation = await widget.controller.uploadAndConfirmPhoto(shot);
      if (!mounted) return;
      if (!validation.faceFound) {
        // Единственный жёсткий блок: без лица дальше нельзя.
        setState(() {
          _phase = _CamPhase.captured;
          _hint = l10n.mirrorFaceNotFound;
        });
        return;
      }
      // Мягкие подсказки не блокируют (веб-паритет): предупреждаем — и дальше.
      widget.controller.confirmPhoto();
    } on KioskApiException {
      if (!mounted) return;
      setState(() {
        _phase = _CamPhase.captured;
        _hint = l10n.mirrorUploadFailed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _CamPhase.captured;
        _hint = l10n.mirrorUploadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = MirrorTheme.scale(context);

    // Камера недоступна, но кадр ещё не выбран: даём путь через галерею
    // (это же спасает симулятор без камеры).
    if (_initFailed && _phase != _CamPhase.captured && _phase != _CamPhase.uploading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40 * s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_outlined,
                  size: 48 * s, color: MirrorTheme.gray),
              SizedBox(height: 20 * s),
              Text(
                l10n.mirrorCamNoAccess,
                textAlign: TextAlign.center,
                style: MirrorTheme.headline(24 * s),
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

    final captured = _phase == _CamPhase.captured || _phase == _CamPhase.uploading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final circle = math.min(
          constraints.maxWidth * 0.72,
          constraints.maxHeight * 0.46,
        );

        return Column(
          children: [
            SizedBox(height: 10 * s),
            Text(
              captured ? l10n.mirrorCamDone : l10n.mirrorCamAim,
              textAlign: TextAlign.center,
              style: MirrorTheme.headline(26 * s),
            ),
            SizedBox(height: 6 * s),
            Text(
              _hint ?? (captured ? l10n.mirrorCamDoneHint : l10n.mirrorCamLook),
              textAlign: TextAlign.center,
              style: MirrorTheme.subtitle(
                15 * s,
                color: _hint != null ? MirrorTheme.pink : MirrorTheme.gray,
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: circle,
                  height: circle,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipOval(
                        child: captured && _shot != null
                            ? Transform.flip(
                                // Зеркалим показ фронтального кадра — человек
                                // видит себя как в зеркале; в бэкенд уходит
                                // оригинал.
                                flipX: _frontCamera && !_shotFromGallery,
                                child: Image.file(_shot!, fit: BoxFit.cover),
                              )
                            : _initialized && _camera != null
                                ? _CoverPreview(controller: _camera!)
                                : const ColoredBox(
                                    color: MirrorTheme.surface,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: MirrorTheme.pink,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _DashedRingPainter(
                            color: MirrorTheme.pink,
                            strokeWidth: 3.5 * s,
                          ),
                        ),
                      ),
                      if (_phase == _CamPhase.countdown)
                        ColoredBox(
                          color: Colors.black.withValues(alpha: 0.25),
                          child: Center(
                            child: Text(
                              '$_countdown',
                              style: MirrorTheme.headline(
                                96 * s,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 28 * s),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 14 * s, color: MirrorTheme.gray),
                      SizedBox(width: 6 * s),
                      Flexible(
                        child: Text(
                          l10n.mirrorPrivacyShort,
                          style: MirrorTheme.subtitle(13 * s),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14 * s),
                  if (!captured) ...[
                    MirrorPrimaryButton(
                      label: l10n.mirrorShoot,
                      height: 64 * s,
                      enabled:
                          _initialized && _phase == _CamPhase.live,
                      onTap: _startCountdown,
                    ),
                    SizedBox(height: 12 * s),
                    MirrorGhostButton(
                      label: l10n.mirrorUpload,
                      height: 56 * s,
                      enabled: _phase == _CamPhase.live,
                      onTap: _pickFromGallery,
                    ),
                  ] else
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
                  SizedBox(height: 24 * s),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Превью камеры, заполняющее круг без искажений (cover).
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewRatio = controller.value.aspectRatio;
        // Камера отдаёт landscape-отношение; в портретном превью оно
        // инвертируется.
        final ratio = previewRatio > 1 ? 1 / previewRatio : previewRatio;
        var scale = ratio / (constraints.maxWidth / constraints.maxHeight);
        if (scale < 1) scale = 1 / scale;
        return ClipRect(
          child: Transform.scale(
            scale: scale,
            child: Center(child: CameraPreview(controller)),
          ),
        );
      },
    );
  }
}

/// Пунктирное розовое кольцо-ориентир по краю круга.
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;
    const dashCount = 36;
    const dashFraction = 0.55;
    final step = 2 * math.pi / dashCount;
    for (var i = 0; i < dashCount; i++) {
      final start = i * step;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        step * dashFraction,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
