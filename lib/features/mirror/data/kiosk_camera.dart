import 'package:camera/camera.dart';

/// Ключ prefs с именем (id) камеры, которую продавец выбрал вручную в шите
/// настройки. Нет значения — автовыбор.
const kKioskCameraPref = 'kiosk_camera';

/// Какую камеру открывает киоск.
///
/// На планшете зеркала камера обычно внешняя USB (Android отдаёт её как
/// [CameraLensDirection.external]), и у планшета может быть ещё своя
/// встроенная. Порядок: ручной выбор продавца, если такая камера сейчас
/// подключена → внешняя USB → фронтальная → любая.
CameraDescription? pickKioskCamera(
  List<CameraDescription> cameras, {
  String? preferredName,
}) {
  if (cameras.isEmpty) return null;
  if (preferredName != null) {
    for (final c in cameras) {
      if (c.name == preferredName) return c;
    }
  }
  for (final direction in const [
    CameraLensDirection.external,
    CameraLensDirection.front,
  ]) {
    for (final c in cameras) {
      if (c.lensDirection == direction) return c;
    }
  }
  return cameras.first;
}

/// Подпись камеры для продавца в шите настройки.
String kioskCameraLabel(CameraDescription c) {
  final kind = switch (c.lensDirection) {
    CameraLensDirection.external => 'USB-камера',
    CameraLensDirection.front => 'Встроенная фронтальная',
    CameraLensDirection.back => 'Встроенная задняя',
  };
  return '$kind · id ${c.name}';
}
