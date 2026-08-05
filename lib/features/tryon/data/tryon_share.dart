import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _pink = Color(0xFFF370A7);

/// Burn the LIBΛS wordmark into a try-on result and hand it to the OS share
/// sheet.
///
/// Port of the closet web app's `shareWatermarked` / `renderWatermarkedBlob`
/// (swipe-web `lib/canvas-snapshot.ts`) so a look shared from discovery or the
/// shop carries the same mark, in the same place, as one shared from the
/// closet. The proportions below are that function's, kept literally: font and
/// margin scale with the image so the mark lands identically on any output
/// size.
///
/// Throws on network/decode failure so the caller can tell the user.
Future<void> shareWatermarkedTryOn(String resultUrl) async {
  final file = await _renderWatermarked(resultUrl);
  await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')]);
}

Future<File> _renderWatermarked(String resultUrl) async {
  final res = await http.get(Uri.parse(resultUrl));
  if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
    throw HttpException('try-on image fetch failed (${res.statusCode})');
  }
  return _writeShareFile(await watermarkTryOnBytes(res.bodyBytes));
}

/// Draws the wordmark onto [source] (any format `dart:ui` can decode) and
/// returns PNG bytes. Split out from the network fetch so the placement can be
/// tested without one.
@visibleForTesting
Future<Uint8List> watermarkTryOnBytes(Uint8List source) async {
  final decoded = await ui.instantiateImageCodec(source);
  final frame = await decoded.getNextFrame();
  final image = frame.image;

  final w = image.width;
  final h = image.height;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  canvas.drawImage(image, Offset.zero, Paint());

  // Web: scale = max(width / 400, 1); font 14 * scale; margin 14 * scale;
  // baseline is vertically centred at margin + fontSize/2 + 16 * scale.
  final scale = (w / 400).clamp(1.0, double.infinity);
  final fontSize = (14 * scale).roundToDouble();
  final margin = (14 * scale).roundToDouble();
  final centreY = margin + fontSize / 2 + (16 * scale).roundToDouble();

  // A soft white glow, as on the web, so the mark survives a dark photo.
  final shadow = ui.Shadow(
    color: const Color(0xFFFFFFFF).withValues(alpha: 0.6),
    blurRadius: (4 * scale).roundToDouble(),
  );

  TextPainter run(String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
          shadows: [shadow],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  final lib = run('LIB', Colors.black);
  final lambda = run('Λ', _pink);
  final s = run('S', Colors.black);

  // Each run is painted from its top-left, so lift it by half its height to
  // land on the same optical centre the canvas version used.
  var x = margin;
  for (final tp in [lib, lambda, s]) {
    tp.paint(canvas, Offset(x, centreY - tp.height / 2));
    x += tp.width;
  }

  final picture = recorder.endRecording();
  final out = await picture.toImage(w, h);
  final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  out.dispose();
  if (bytes == null) throw const FormatException('watermark encode failed');

  return bytes.buffer.asUint8List();
}

/// Writes under cacheDir/share_images — this path MUST stay covered by
/// `res/xml/share_paths.xml`, which the Android FileProvider exposes to share
/// intents (same directory the WebView share bridge uses).
Future<File> _writeShareFile(Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final shareDir = Directory('${dir.path}/share_images');
  if (!shareDir.existsSync()) shareDir.createSync(recursive: true);
  final file = File('${shareDir.path}/libas-tryon.png');
  await file.writeAsBytes(bytes);
  return file;
}
