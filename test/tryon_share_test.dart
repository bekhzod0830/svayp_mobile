import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/features/tryon/data/tryon_share.dart';

/// A plain white [w]x[h] PNG to watermark.
Future<Uint8List> _whitePng(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = Colors.white,
  );
  final img = await recorder.endRecording().toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

/// True if any pixel in the rect is not white — i.e. something was drawn.
Future<bool> _hasInk(ui.Image img, Rect area) async {
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  for (var y = area.top.toInt(); y < area.bottom.toInt(); y++) {
    for (var x = area.left.toInt(); x < area.right.toInt(); x++) {
      final i = (y * img.width + x) * 4;
      if (bytes[i] < 245 || bytes[i + 1] < 245 || bytes[i + 2] < 245) return true;
    }
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('watermark keeps the source dimensions', () async {
    final out = await watermarkTryOnBytes(await _whitePng(400, 600));
    final img = await _decode(out);
    expect(img.width, 400);
    expect(img.height, 600);
  });

  test('mark lands top-left and leaves the rest of the photo alone', () async {
    const w = 400, h = 600;
    final out = await watermarkTryOnBytes(await _whitePng(w, h));
    final img = await _decode(out);

    // At 400px wide the web's scale is 1: 14px bold text at x=14, optically
    // centred on y = 14 + 7 + 16 = 37. So the mark sits well inside this box.
    expect(await _hasInk(img, const Rect.fromLTRB(10, 20, 120, 55)), isTrue,
        reason: 'wordmark should be drawn in the top-left corner');

    // The subject of the photo must be untouched.
    expect(await _hasInk(img, const Rect.fromLTRB(150, 200, w - 1, h - 1)), isFalse,
        reason: 'watermark must not bleed into the rest of the image');
  });

  test('mark scales with the image instead of staying 14px', () async {
    // A 1200px-wide render is scale 3, so the mark occupies proportionally the
    // same corner — nothing should appear where the small version had ink.
    final big = await _decode(await watermarkTryOnBytes(await _whitePng(1200, 1800)));

    expect(await _hasInk(big, const Rect.fromLTRB(30, 60, 360, 165)), isTrue,
        reason: 'scaled wordmark should occupy the proportional corner');
    // Same absolute box as the 400px case, but scaled up 3x it is far past the
    // mark, so a non-scaling implementation would fail here.
    expect(await _hasInk(big, const Rect.fromLTRB(400, 300, 1199, 1799)), isFalse);
  });
}
