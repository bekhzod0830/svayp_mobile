import 'package:camera/camera.dart';
import 'package:flutter_ffi_uvc/flutter_ffi_uvc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/features/mirror/data/kiosk_camera.dart';

KioskCameraOption _android(String name, CameraLensDirection dir) =>
    KioskCameraOption.android(
      CameraDescription(name: name, lensDirection: dir, sensorOrientation: 0),
    );

KioskCameraOption _uvc({
  int deviceId = 1002,
  int vendorId = 0x1bcf,
  int productId = 0x2a0c,
  String product = 'Rapoo C280',
}) => KioskCameraOption.uvc(
  UvcUsbDevice(
    deviceId: deviceId,
    deviceName: '/dev/bus/usb/001/002',
    vendorId: vendorId,
    productId: productId,
    productName: product,
    manufacturerName: 'Rapoo',
    serialNumber: '',
    hasPermission: true,
  ),
);

UvcCameraMode _mode(String format, int w, int h, int fps) => UvcCameraMode(
  frameFormat: format == 'MJPEG' ? 7 : 4,
  formatName: format,
  width: w,
  height: h,
  fps: fps,
);

void main() {
  final back = _android('0', CameraLensDirection.back);
  final front = _android('1', CameraLensDirection.front);
  final external = _android('100', CameraLensDirection.external);
  final rapoo = _uvc();

  group('rankKioskCameras', () {
    test('no cameras → empty / null', () {
      expect(rankKioskCameras(const []), isEmpty);
      expect(pickKioskCamera(const []), isNull);
    });

    test(
      'USB напрямую впереди USB через Android, затем фронталка, затем всё',
      () {
        expect(rankKioskCameras([back, front, external, rapoo]), [
          rapoo,
          external,
          front,
          back,
        ]);
      },
    );

    test('без USB — фронталка, затем что есть', () {
      expect(pickKioskCamera([back, front]), front);
      expect(pickKioskCamera([back]), back);
    });

    test('ручной выбор впереди, пока камера подключена', () {
      expect(rankKioskCameras([back, front, rapoo], preferredId: '1'), [
        front,
        rapoo,
        back,
      ]);
    });

    test('ручной выбор UVC по устойчивому id (vendor:product)', () {
      // Тот же Rapoo, но Android выдал другой deviceId после переподключения.
      final replugged = _uvc(deviceId: 1007);
      expect(
        pickKioskCamera([front, replugged], preferredId: rapoo.id),
        replugged,
      );
      expect(rapoo.id, 'uvc:1bcf:2a0c');
    });

    test('отключённый ручной выбор → авто', () {
      expect(pickKioskCamera([back, external], preferredId: '1'), external);
    });
  });

  group('KioskCameraOption', () {
    test('камеры, что смотрят на покупателя, зеркалятся при показе', () {
      expect(rapoo.facesUser, isTrue);
      expect(external.facesUser, isTrue);
      expect(front.facesUser, isTrue);
      expect(back.facesUser, isFalse);
    });

    test('подписи для продавца', () {
      expect(rapoo.label, 'USB напрямую · Rapoo C280 (1bcf:2a0c)');
      expect(external.label, 'USB-камера (через Android) · id 100');
      expect(front.label, 'Встроенная фронтальная · id 1');
      expect(back.label, 'Встроенная задняя · id 0');
    });

    test('UVC без имени продукта подписывается именем устройства', () {
      final nameless = _uvc(product: '');
      expect(nameless.label, contains('/dev/bus/usb/001/002'));
    });
  });

  group('rankUvcModes', () {
    final modes = [
      _mode('YUYV', 640, 480, 30),
      _mode('MJPEG', 640, 480, 30),
      _mode('MJPEG', 2560, 1440, 30),
      _mode('MJPEG', 1920, 1080, 30),
      _mode('MJPEG', 1280, 720, 30),
      _mode('MJPEG', 1920, 1080, 60),
      _mode('YUYV', 1920, 1080, 5),
    ];

    test(
      'MJPEG до лимита от большего к меньшему, потом крупнее, потом YUYV',
      () {
        final labels = rankUvcModes(
          modes,
          maxWidth: 1920,
        ).map((m) => m.label).toList();
        expect(labels, [
          'MJPEG 1920x1080 @ 60fps',
          'MJPEG 1920x1080 @ 30fps',
          'MJPEG 1280x720 @ 30fps',
          'MJPEG 640x480 @ 30fps',
          'MJPEG 2560x1440 @ 30fps',
          'YUYV 1920x1080 @ 5fps',
          'YUYV 640x480 @ 30fps',
        ]);
      },
    );

    test('по умолчанию планка Full HD → 1080p первый, 2K — по выбору', () {
      expect(kUvcMaxWidth, 1920);
      expect(kUvcQualityOptions.keys, contains(2560));
      expect(rankUvcModes(modes).first.label, 'MJPEG 1920x1080 @ 60fps');
      expect(
        rankUvcModes(modes, maxWidth: 2560).first.label,
        'MJPEG 2560x1440 @ 30fps',
      );
    });

    test('планка HD → 720p первый, крупные MJPEG после всех до лимита', () {
      final labels = rankUvcModes(
        modes,
        maxWidth: 1280,
      ).map((m) => m.label).toList();
      expect(labels.first, 'MJPEG 1280x720 @ 30fps');
      expect(
        labels.indexOf('MJPEG 640x480 @ 30fps'),
        lessThan(labels.indexOf('MJPEG 1920x1080 @ 60fps')),
      );
    });

    test('не меняет исходный список', () {
      final copy = [...modes];
      rankUvcModes(modes);
      expect(modes, copy);
    });
  });

  test('parseKioskUvcMaxWidth принимает только планки из списка', () {
    expect(parseKioskUvcMaxWidth(null), kUvcMaxWidth);
    expect(parseKioskUvcMaxWidth(1920), 1920);
    expect(parseKioskUvcMaxWidth(1280), 1280);
    expect(parseKioskUvcMaxWidth(640), kUvcMaxWidth);
    expect(parseKioskUvcMaxWidth(4096), kUvcMaxWidth);
  });
}
