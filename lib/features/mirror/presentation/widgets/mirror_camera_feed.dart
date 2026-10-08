import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffi_uvc/flutter_ffi_uvc.dart';
import 'package:image/image.dart' as img;

import '../../data/kiosk_camera.dart';

/// Закрытие предыдущей камеры, которого обязана дождаться следующая. Общее для
/// всех лент: Rapoo видна и как UVC напрямую, и как «external» камера Android —
/// это одно устройство, и пока прежняя лента его держит, новая получает «занято»
/// или зависает. Поэтому открытия и закрытия идут строго по очереди.
Future<void> _released = Future.value();

/// Сколько ждём закрытия камеры. Дольше — считаем, что закрытие зависло, и
/// отпускаем очередь: иначе одна зависшая лента навсегда оставляла киоск без
/// камеры (горит индикатор, на экране вечная загрузка).
const _releaseTimeout = Duration(seconds: 6);

/// Поставить закрытие ленты в общую очередь. Ошибки и зависания не рвут очередь.
Future<void> _enqueueRelease(String label, Future<void> Function() release) {
  final next = _released.then((_) async {
    try {
      await release().timeout(_releaseTimeout);
    } on TimeoutException {
      debugPrint('[mirror/camera] $label: release timed out');
    } catch (e) {
      debugPrint('[mirror/camera] $label: release failed: $e');
    }
  });
  _released = next;
  return next;
}

/// Живая картинка одной камеры киоска: запуск, превью, снимок, остановка.
/// Экран камеры работает с ней одинаково, откуда бы кадр ни шёл — из
/// камерного сервиса Android или напрямую с USB-вебкамеры.
///
/// Ни один шаг не ждёт бесконечно: запуск, снимок и закрытие ограничены по
/// времени, а [dispose] можно звать в любой момент, в том числе посреди
/// [start] — запуск прервётся, камера освободится.
abstract class MirrorCameraFeed {
  KioskCameraOption get option;

  /// Открыть камеру и запустить превью. Бросает, если камера не завелась —
  /// экран тогда пробует следующую из списка.
  Future<void> start();

  /// Превью как есть (без зеркала), заполняющее область по cover.
  Widget buildPreview();

  /// Нужно ли экрану самому отразить превью по горизонтали. Фронталку
  /// зеркалит плагин camera, UVC — сам плагин по трансформу, а USB-камеру
  /// через Android никто.
  bool get previewNeedsFlip;

  /// Снять кадр в файл [path] (JPEG). В файле — ровно то, что человек видел
  /// на превью (с зеркалом): иначе готовый снимок «переворачивался» после
  /// отсчёта, и в бэкенд уходил не тот кадр, что на экране.
  Future<File> capture(String path);

  /// Строка диагностики для оверлея на экране камеры: что идёт и как.
  String diagnostics();

  /// Сколько кадров пришло с камеры с запуска; null — лента этого не знает.
  /// Экран камеры по нему замечает, что поток встал, и перезапускает камеру.
  int? get frameCount;

  Future<void> dispose();

  static MirrorCameraFeed create(
    KioskCameraOption option, {
    int uvcMaxWidth = kUvcMaxWidth,
  }) {
    return option.kind == KioskCameraKind.uvc
        ? UvcCameraFeed(option, maxWidth: uvcMaxWidth)
        : AndroidCameraFeed(option);
  }
}

/// Камера через плагин `camera` (Camera2 / CameraX).
class AndroidCameraFeed implements MirrorCameraFeed {
  AndroidCameraFeed(this.option) : assert(option.android != null);

  @override
  final KioskCameraOption option;

  CameraController? _controller;
  Future<void>? _disposing;

  @override
  Future<void> start() async {
    await _released;
    if (_disposing != null) throw StateError('camera feed disposed');
    final controller = CameraController(
      option.android!,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    // USB-камера через Camera2 при повторном открытии иногда не отвечает
    // вовсе — без предела экран ждал бы её вечно.
    await controller.initialize().timeout(const Duration(seconds: 12));
  }

  @override
  int? get frameCount => null;

  @override
  bool get previewNeedsFlip => option.kind == KioskCameraKind.external;

  @override
  Widget buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
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

  @override
  Future<File> capture(String path) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('camera not initialized');
    }
    final xfile = await controller.takePicture().timeout(
      const Duration(seconds: 8),
    );
    final file = await File(xfile.path).copy(path);
    try {
      await File(xfile.path).delete();
    } catch (_) {}
    // Превью фронталки зеркалит плагин camera, внешней — экран; снимок оба
    // отдают без зеркала. Отражаем файл, чтобы он совпал с превью.
    if (_previewMirrored) {
      final mirrored = await compute(_mirrorJpeg, await file.readAsBytes());
      await file.writeAsBytes(mirrored, flush: true);
    }
    return file;
  }

  bool get _previewMirrored =>
      option.kind == KioskCameraKind.front ||
      option.kind == KioskCameraKind.external;

  @override
  String diagnostics() {
    final v = _controller?.value;
    if (v == null || !v.isInitialized) return 'Android: камера не готова';
    final size = v.previewSize;
    return 'Android ${option.kind.name} · '
        '${size == null ? '?' : '${size.width.round()}x${size.height.round()}'}';
  }

  @override
  Future<void> dispose() => _disposing ??= _enqueueRelease(option.label, () async {
        final controller = _controller;
        _controller = null;
        if (controller != null) await controller.dispose();
      });
}

/// USB-вебкамера напрямую (flutter_ffi_uvc, libuvc поверх USB host).
///
/// Превью рисуется в Texture как есть, зеркалит его экран (GPU). Снимок
/// отражается так же — в бэкенд уходит тот кадр, что человек видел на
/// экране. Поворота нет: камера висит горизонтально, как и отдаёт кадр.
class UvcCameraFeed implements MirrorCameraFeed {
  UvcCameraFeed(this.option, {this.maxWidth = kUvcMaxWidth})
    : assert(option.uvc != null);

  @override
  final KioskCameraOption option;

  /// Планка качества: ширина кадра, выше которой режимы идут в конец очереди.
  final int maxWidth;

  final UvcCamera _camera = UvcCamera();
  int? _textureId;
  UvcCameraMode? _mode;

  /// Режим, в котором реально идёт поток (после запуска).
  UvcCameraMode? get mode => _mode;

  Future<void>? _disposing;

  @override
  Future<void> start() async {
    // Пока прежняя лента держит то же USB-устройство, открытие падает с
    // «busy» — ждём её закрытия (см. [_released]).
    await _released;
    if (_disposing != null) throw StateError('camera feed disposed');
    // Первое открытие на планшете покажет системный диалог «Разрешить
    // приложению доступ к USB-устройству?» — продавец ставит галочку
    // «всегда», дальше без вопросов. Предел щедрый — успеть нажать.
    await _openWithRetry().timeout(const Duration(seconds: 45));
    final supported = _camera.supportedModes();
    final candidates = rankUvcModes(supported, maxWidth: maxWidth);
    final result = await _camera
        .startPreviewAuto(
          candidates: candidates,
          // Не больше четырёх режимов: первый подходящий MJPEG у Rapoo
          // заводится сразу, а перебор всего списка по 4 с растягивал
          // «загрузку» камеры на минуту.
          maxCandidates: candidates.isEmpty ? 4 : math.min(candidates.length, 4),
          preference: UvcAutoPreviewPreference.quality,
          // Крупный MJPEG на слабом процессоре раскачивается не сразу: даём
          // режиму больше времени, чем 2 с по умолчанию, прежде чем
          // откатиться на меньший.
          perModeTimeout: const Duration(seconds: 4),
        )
        .timeout(const Duration(seconds: 25));
    final mode = result.mode;
    final attempts = [
      for (final a in result.attempts)
        '${a.mode.label}: '
            '${a.success ? 'ok' : (a.lastError ?? a.errorCode?.name ?? 'no frames')}',
    ];
    // В шит настройки и в logcat: какой режим реально пошёл и почему не
    // крупнее — иначе откат на меньший режим молчаливый.
    kioskUvcStatus.value = KioskUvcStatus(
      device: option.uvc!,
      mode: mode,
      supportedModes: supported,
      attempts: attempts,
    );
    debugPrint('[mirror/uvc] ${option.label}: ${attempts.join('; ')}');
    if (!result.success || mode == null) {
      throw StateError('UVC preview failed: ${attempts.join('; ')}');
    }
    _mode = mode;
    _applyPictureControls();
    // Зеркало НЕ отдаём плагину: он переписывает каждый кадр на процессоре
    // (blit RGBA) поверх и так тяжёлого MJPEG-декода. Текстуру зеркалит
    // GPU через Transform.flip во Flutter, это бесплатно.
    _camera.setPreviewTransform(UvcPreviewTransform.identity);
    final textureId = await _camera.createPreviewTexture();
    _textureId = textureId;
    await _camera.attachPreviewTexture(
      textureId,
      width: mode.width,
      height: mode.height,
    );
  }

  /// Сеть в Узбекистане 50 Гц, а вебкамеры с завода часто стоят на 60:
  /// под магазинными лампами это мерцание яркости и плывущий цвет. Ставим
  /// 50 Гц (UVC: 0 — выкл, 1 — 50 Гц, 2 — 60 Гц), если камера этот контрол
  /// объявляет. Остальное (экспозиция, баланс белого) оставляем камере.
  void _applyPictureControls() {
    try {
      final supported = _camera.supportedControls();
      final hasPowerLine = supported.any(
        (c) => c.id == UvcControlId.powerLineFrequency,
      );
      if (!hasPowerLine) return;
      final current = _camera.getControl(UvcControlId.powerLineFrequency);
      if (current != 1) {
        _camera.setControl(UvcControlId.powerLineFrequency, 1);
        debugPrint('[mirror/uvc] power line frequency: $current → 50 Hz');
      }
    } catch (e) {
      debugPrint('[mirror/uvc] controls: $e');
    }
  }

  @override
  String diagnostics() {
    final mode = _mode;
    if (mode == null) return 'UVC: поток не запущен';
    try {
      final s = _camera.getStreamStats();
      final dropped = s.callbackLockDropCount + s.staleFrameCount;
      return 'UVC ${mode.label}\n'
          'fps: камера ${s.inputFps.toStringAsFixed(1)} → '
          'экран ${s.deliveredFps.toStringAsFixed(1)}\n'
          'кадров: ${s.inputFrameCount}, пропущено: $dropped, '
          'ошибок декода: ${s.decodeFailureCount}\n'
          'пауза между кадрами: ср. ${s.avgInterFrameGapMs.round()} мс, '
          'p95 ${s.p95InterFrameGapMs.round()} мс';
    } catch (e) {
      return 'UVC ${mode.label}\nстатистика недоступна: $e';
    }
  }

  /// Сразу после закрытия вебкамера секунду-другую может не открываться
  /// (libuvc ещё отпускает интерфейс) — пробуем ещё раз, прежде чем отдать
  /// очередь встроенной камере.
  Future<void> _openWithRetry() async {
    const attempts = 3;
    for (var i = 1; ; i++) {
      try {
        await _camera.openUsbDevice(option.uvc!.deviceId);
        return;
      } on UvcException catch (e) {
        if (i >= attempts || e.code == UvcErrorCode.access) rethrow;
        debugPrint('[mirror/uvc] open failed ($i/$attempts): $e');
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
    }
  }

  @override
  /// Зеркалит экран (GPU), плагин отдаёт кадр как есть.
  bool get previewNeedsFlip => true;

  @override
  int? get frameCount {
    if (_mode == null) return null;
    try {
      return _camera.getStreamStats().inputFrameCount;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget buildPreview() {
    final textureId = _textureId;
    final mode = _mode;
    if (textureId == null || mode == null) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: mode.width.toDouble(),
        height: mode.height.toDouble(),
        child: Texture(
          textureId: textureId,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }

  @override
  Future<File> capture(String path) async {
    // Кадр уже прошёл MJPEG-сжатие в камере; второе сжатие держим почти
    // без потерь.
    final picture = _camera.takePicture(
      quality: 96,
      // Как на превью: экран зеркалит текстуру, кадр зеркалим при кодировании.
      transform: const UvcPreviewTransform(flipHorizontal: true),
    );
    if (picture == null) {
      throw StateError('UVC capture failed: ${_camera.lastError}');
    }
    return File(path).writeAsBytes(picture.jpegBytes, flush: true);
  }

  /// Можно звать посреди [start]: закрытие плагина прерывает запуск потока.
  @override
  Future<void> dispose() =>
      _disposing ??= _enqueueRelease(option.label, _teardown);

  Future<void> _teardown() async {
    final textureId = _textureId;
    _textureId = null;
    _mode = null;
    try {
      await _camera.dispose();
    } catch (_) {}
    if (textureId != null) {
      try {
        await _camera.disposePreviewTexture(textureId);
      } catch (_) {}
    }
  }
}

/// JPEG, отражённый по горизонтали. Ориентацию из EXIF сначала «запекаем» в
/// пиксели — иначе после отражения повёрнутый кадр перевернулся бы не по той оси.
/// Верхнеуровневая функция — для [compute]: декод крупного кадра не держит UI.
Uint8List _mirrorJpeg(Uint8List bytes) {
  final decoded = img.decodeJpg(bytes);
  if (decoded == null) throw StateError('JPEG decode failed');
  final upright = img.bakeOrientation(decoded);
  return img.encodeJpg(img.flipHorizontal(upright), quality: 95);
}
