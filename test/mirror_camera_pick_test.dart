import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/features/mirror/data/kiosk_camera.dart';

CameraDescription _cam(String name, CameraLensDirection dir) =>
    CameraDescription(name: name, lensDirection: dir, sensorOrientation: 0);

void main() {
  final back = _cam('0', CameraLensDirection.back);
  final front = _cam('1', CameraLensDirection.front);
  final usb = _cam('100', CameraLensDirection.external);

  test('no cameras → null', () {
    expect(pickKioskCamera(const []), isNull);
  });

  test('USB camera wins over the built-in ones', () {
    expect(pickKioskCamera([back, front, usb]), usb);
  });

  test('without USB falls back to front, then to anything', () {
    expect(pickKioskCamera([back, front]), front);
    expect(pickKioskCamera([back]), back);
  });

  test('seller choice wins while that camera is connected', () {
    expect(pickKioskCamera([back, front, usb], preferredName: '1'), front);
  });

  test('unplugged seller choice falls back to auto', () {
    expect(pickKioskCamera([back, usb], preferredName: '1'), usb);
  });
}
