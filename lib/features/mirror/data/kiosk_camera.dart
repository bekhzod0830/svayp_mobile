import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ffi_uvc/flutter_ffi_uvc.dart';

/// Ключ prefs с id камеры ([KioskCameraOption.id]), которую продавец выбрал
/// вручную в шите настройки. Нет значения — автовыбор.
const kKioskCameraPref = 'kiosk_camera';

/// Откуда киоск берёт картинку.
enum KioskCameraKind {
  /// USB-вебкамера напрямую по USB host (libuvc), минуя камерный сервис
  /// Android. Единственный путь на планшетах, чья прошивка не отдаёт UVC
  /// через Camera2 (тогда камеру не видит и системное приложение «Камера»).
  uvc,

  /// USB-камера, которую Android отдаёт через камерный сервис.
  external,

  /// Встроенная фронтальная.
  front,

  /// Встроенная задняя.
  back,
}

/// Одна камера в списке на выбор: либо камера Android, либо UVC-устройство.
class KioskCameraOption {
  KioskCameraOption.android(CameraDescription camera)
    : android = camera,
      uvc = null,
      id = camera.name,
      kind = switch (camera.lensDirection) {
        CameraLensDirection.external => KioskCameraKind.external,
        CameraLensDirection.front => KioskCameraKind.front,
        CameraLensDirection.back => KioskCameraKind.back,
      };

  /// Id устойчив между переподключениями: deviceId у Android меняется при
  /// каждом втыкании, а пара vendor:product — нет.
  KioskCameraOption.uvc(UvcUsbDevice device)
    : android = null,
      uvc = device,
      id = uvcCameraId(device),
      kind = KioskCameraKind.uvc;

  final String id;
  final KioskCameraKind kind;
  final CameraDescription? android;
  final UvcUsbDevice? uvc;

  /// Камера смотрит на покупателя: показ снимка зеркалим, в бэкенд уходит
  /// оригинал.
  bool get facesUser => kind != KioskCameraKind.back;

  /// Подпись для продавца в шите настройки.
  String get label => switch (kind) {
    KioskCameraKind.uvc => 'USB напрямую · ${_uvcName(uvc!)}',
    KioskCameraKind.external => 'USB-камера (через Android) · id $id',
    KioskCameraKind.front => 'Встроенная фронтальная · id $id',
    KioskCameraKind.back => 'Встроенная задняя · id $id',
  };

  static String _uvcName(UvcUsbDevice d) {
    final name = d.productName.isNotEmpty ? d.productName : d.deviceName;
    return '$name (${_hex(d.vendorId)}:${_hex(d.productId)})';
  }
}

String _hex(int v) => v.toRadixString(16).padLeft(4, '0');

String uvcCameraId(UvcUsbDevice d) =>
    'uvc:${_hex(d.vendorId)}:${_hex(d.productId)}';

/// Порядок автовыбора. UVC напрямую впереди Android-«external»: это тот путь,
/// которым мы управляем сами (режим, поворот, зеркало), и единственный
/// рабочий на планшетах зеркала. Если первая не завелась, экран камеры
/// пробует следующую.
const _autoOrder = [
  KioskCameraKind.uvc,
  KioskCameraKind.external,
  KioskCameraKind.front,
  KioskCameraKind.back,
];

/// Камеры в порядке, в котором киоск будет пробовать их открыть: ручной выбор
/// продавца, если такая камера сейчас подключена → USB напрямую → USB через
/// Android → фронтальная → любая.
List<KioskCameraOption> rankKioskCameras(
  List<KioskCameraOption> cameras, {
  String? preferredId,
}) {
  final ranked = <KioskCameraOption>[];
  if (preferredId != null) {
    for (final c in cameras) {
      if (c.id == preferredId) ranked.add(c);
    }
  }
  for (final kind in _autoOrder) {
    for (final c in cameras) {
      if (c.kind == kind && !ranked.contains(c)) ranked.add(c);
    }
  }
  return ranked;
}

/// Камера, которую киоск откроет первой; null — камер нет.
KioskCameraOption? pickKioskCamera(
  List<KioskCameraOption> cameras, {
  String? preferredId,
}) {
  final ranked = rankKioskCameras(cameras, preferredId: preferredId);
  return ranked.isEmpty ? null : ranked.first;
}

/// Ключ prefs тумблера «диагностика камеры на экране»: режим, реальные fps,
/// пропуски — мелким текстом в углу экрана камеры. Для настройки на месте.
const kKioskCameraDebugPref = 'kiosk_camera_debug';

/// Ключ prefs с верхней границей ширины кадра UVC-камеры (см.
/// [kUvcQualityOptions]). Нет значения — [kUvcMaxWidth].
const kKioskUvcMaxWidthPref = 'kiosk_uvc_max_width';

/// Верхняя граница кадра UVC-камеры по умолчанию. Full HD, а не родные 2K
/// Rapoo C280: MJPEG декодируется на процессоре планшета, и на 32" киоске
/// 1440p30 шёл рывками (проверено 06.10.2026), а для лица 1080p хватает.
/// 2K остаётся выбором в шите настройки для планшета посильнее.
const kUvcMaxWidth = 1920;

/// Планки качества USB-камеры на выбор продавца: ширина кадра → подпись.
const kUvcQualityOptions = <int, String>{
  2560: '2K',
  1920: 'Full HD',
  1280: 'HD',
};

/// Планка из prefs: только значения из [kUvcQualityOptions], иначе
/// [kUvcMaxWidth].
int parseKioskUvcMaxWidth(int? value) =>
    kUvcQualityOptions.containsKey(value) ? value! : kUvcMaxWidth;

/// Что реально отдаёт USB-камера напрямую — для шита настройки. Пишет лента
/// UVC при каждом запуске; живёт в памяти процесса, после перезапуска пусто.
final ValueNotifier<KioskUvcStatus?> kioskUvcStatus = ValueNotifier(null);

class KioskUvcStatus {
  const KioskUvcStatus({
    required this.device,
    required this.mode,
    required this.supportedModes,
    required this.attempts,
  });

  final UvcUsbDevice device;

  /// Режим, в котором идёт поток; null — ни один не завёлся.
  final UvcCameraMode? mode;
  final List<UvcCameraMode> supportedModes;

  /// Что пробовали и чем кончилось, по порядку: «MJPEG 2560x1440 @ 30fps:
  /// ok» / «…: no frames».
  final List<String> attempts;
}

/// Режимы UVC-камеры в порядке, в котором их стоит пробовать: сначала MJPEG
/// (не упирается в полосу USB 2.0), от большего разрешения к меньшему в
/// пределах [maxWidth], затем всё, что крупнее лимита, затем остальные
/// форматы. Плагин идёт по списку и оставляет первый, который реально отдаёт
/// кадры.
List<UvcCameraMode> rankUvcModes(
  List<UvcCameraMode> modes, {
  int maxWidth = kUvcMaxWidth,
}) {
  int tier(UvcCameraMode m) {
    final mjpeg = m.formatName == 'MJPEG';
    final fits = m.width <= maxWidth;
    if (mjpeg && fits) return 0;
    if (mjpeg) return 1;
    if (fits) return 2;
    return 3;
  }

  final ranked = [...modes]
    ..sort((a, b) {
      final t = tier(a).compareTo(tier(b));
      if (t != 0) return t;
      final area = (b.width * b.height).compareTo(a.width * a.height);
      if (area != 0) return area;
      return b.fps.compareTo(a.fps);
    });
  return ranked;
}

/// Все камеры, которые видит планшет прямо сейчас: UVC-устройства по USB
/// плюс то, что отдаёт камерный сервис Android (последнее — только с
/// разрешением на камеру, [androidAllowed]). Ошибки каждого источника
/// глотаются: пустой список, а не падение киоска.
Future<List<KioskCameraOption>> listKioskCameras({
  bool androidAllowed = true,
}) async {
  final result = <KioskCameraOption>[];
  if (Platform.isAndroid) {
    try {
      for (final d in await uvcCamera.listUsbDevices()) {
        result.add(KioskCameraOption.uvc(d));
      }
    } catch (_) {}
  }
  if (androidAllowed) {
    try {
      for (final c in await availableCameras()) {
        result.add(KioskCameraOption.android(c));
      }
    } catch (_) {}
  }
  return result;
}
