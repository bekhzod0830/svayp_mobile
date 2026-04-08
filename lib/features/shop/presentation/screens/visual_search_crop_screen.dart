import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// Which part of the crop rectangle is being dragged.
enum _DragMode {
  none,
  moveBox,
  topLeft,
  topRight,
  bottomRight,
  bottomLeft,
  top,
  bottom,
  left,
  right,
}

class VisualSearchCropWidget extends StatefulWidget {
  final XFile image;
  const VisualSearchCropWidget({super.key, required this.image});
  @override
  State<VisualSearchCropWidget> createState() => VisualSearchCropWidgetState();
}

class VisualSearchCropWidgetState extends State<VisualSearchCropWidget> {
  ui.Image? _uiImage;
  Size? _naturalSize;
  Rect _selection = Rect.zero;
  Rect _imageRect = Rect.zero;
  Size _containerSize = Size.zero;
  _DragMode _dragMode = _DragMode.none;

  static const double _cornerHitR = 44.0;
  static const double _edgeHitW = 24.0;
  static const double _minSize = 48.0;

  void resetSelection() => setState(() => _selection = _imageRect);

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.image.path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _uiImage = frame.image;
        _naturalSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      });
    }
  }

  static Rect _containedRect(Size container, Size natural) {
    final imgAspect = natural.width / natural.height;
    final ctnAspect = container.width / container.height;
    double w, h;
    if (imgAspect > ctnAspect) {
      w = container.width;
      h = container.width / imgAspect;
    } else {
      h = container.height;
      w = container.height * imgAspect;
    }
    return Rect.fromLTWH(
      (container.width - w) / 2,
      (container.height - h) / 2,
      w,
      h,
    );
  }

  void _updateLayout(Size containerSize) {
    if (_naturalSize == null) return;
    if (containerSize == _containerSize && _selection != Rect.zero) return;
    _containerSize = containerSize;
    _imageRect = _containedRect(containerSize, _naturalSize!);
    if (_selection == Rect.zero) _selection = _imageRect;
  }

  _DragMode _hitTest(Offset pos) {
    final sel = _selection;
    if ((pos - sel.topLeft).distance <= _cornerHitR) return _DragMode.topLeft;
    if ((pos - sel.topRight).distance <= _cornerHitR) return _DragMode.topRight;
    if ((pos - sel.bottomRight).distance <= _cornerHitR)
      return _DragMode.bottomRight;
    if ((pos - sel.bottomLeft).distance <= _cornerHitR)
      return _DragMode.bottomLeft;
    final inH =
        pos.dx >= sel.left - _edgeHitW && pos.dx <= sel.right + _edgeHitW;
    final inV =
        pos.dy >= sel.top - _edgeHitW && pos.dy <= sel.bottom + _edgeHitW;
    if ((pos.dy - sel.top).abs() <= _edgeHitW && inH) return _DragMode.top;
    if ((pos.dy - sel.bottom).abs() <= _edgeHitW && inH)
      return _DragMode.bottom;
    if ((pos.dx - sel.left).abs() <= _edgeHitW && inV) return _DragMode.left;
    if ((pos.dx - sel.right).abs() <= _edgeHitW && inV) return _DragMode.right;
    if (sel.contains(pos)) return _DragMode.moveBox;
    return _DragMode.none;
  }

  void _applyDelta(Offset delta) {
    if (_dragMode == _DragMode.none) return;
    final sel = _selection;
    final img = _imageRect;
    Rect next;
    switch (_dragMode) {
      case _DragMode.moveBox:
        final nl = (sel.left + delta.dx).clamp(img.left, img.right - sel.width);
        final nt = (sel.top + delta.dy).clamp(img.top, img.bottom - sel.height);
        next = Rect.fromLTWH(nl, nt, sel.width, sel.height);
      case _DragMode.topLeft:
        next = Rect.fromLTRB(
          (sel.left + delta.dx).clamp(img.left, sel.right - _minSize),
          (sel.top + delta.dy).clamp(img.top, sel.bottom - _minSize),
          sel.right,
          sel.bottom,
        );
      case _DragMode.topRight:
        next = Rect.fromLTRB(
          sel.left,
          (sel.top + delta.dy).clamp(img.top, sel.bottom - _minSize),
          (sel.right + delta.dx).clamp(sel.left + _minSize, img.right),
          sel.bottom,
        );
      case _DragMode.bottomRight:
        next = Rect.fromLTRB(
          sel.left,
          sel.top,
          (sel.right + delta.dx).clamp(sel.left + _minSize, img.right),
          (sel.bottom + delta.dy).clamp(sel.top + _minSize, img.bottom),
        );
      case _DragMode.bottomLeft:
        next = Rect.fromLTRB(
          (sel.left + delta.dx).clamp(img.left, sel.right - _minSize),
          sel.top,
          sel.right,
          (sel.bottom + delta.dy).clamp(sel.top + _minSize, img.bottom),
        );
      case _DragMode.top:
        next = Rect.fromLTRB(
          sel.left,
          (sel.top + delta.dy).clamp(img.top, sel.bottom - _minSize),
          sel.right,
          sel.bottom,
        );
      case _DragMode.bottom:
        next = Rect.fromLTRB(
          sel.left,
          sel.top,
          sel.right,
          (sel.bottom + delta.dy).clamp(sel.top + _minSize, img.bottom),
        );
      case _DragMode.left:
        next = Rect.fromLTRB(
          (sel.left + delta.dx).clamp(img.left, sel.right - _minSize),
          sel.top,
          sel.right,
          sel.bottom,
        );
      case _DragMode.right:
        next = Rect.fromLTRB(
          sel.left,
          sel.top,
          (sel.right + delta.dx).clamp(sel.left + _minSize, img.right),
          sel.bottom,
        );
      case _DragMode.none:
        return;
    }
    setState(() => _selection = next);
  }

  static const int _maxOutputDim = 1200;

  Future<XFile> cropImage() async {
    if (_uiImage == null || _naturalSize == null || _selection == Rect.zero) {
      return widget.image;
    }
    try {
      final scaleX = _naturalSize!.width / _imageRect.width;
      final scaleY = _naturalSize!.height / _imageRect.height;
      final cropLeft = (_selection.left - _imageRect.left) * scaleX;
      final cropTop = (_selection.top - _imageRect.top) * scaleY;
      final cropW = (_selection.width * scaleX).clamp(1.0, _naturalSize!.width);
      final cropH = (_selection.height * scaleY).clamp(
        1.0,
        _naturalSize!.height,
      );
      final longestSide = cropW > cropH ? cropW : cropH;
      final outputScale = longestSide > _maxOutputDim
          ? _maxOutputDim / longestSide
          : 1.0;
      final outW = (cropW * outputScale).round().clamp(1, _maxOutputDim);
      final outH = (cropH * outputScale).round().clamp(1, _maxOutputDim);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        _uiImage!,
        Rect.fromLTWH(cropLeft, cropTop, cropW, cropH),
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(outW, outH);
      final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final outFile = File(
        '${tempDir.path}/vs_crop_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await outFile.writeAsBytes(bytes);
      return XFile(outFile.path);
    } catch (e) {
      return widget.image;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _selection != Rect.zero;
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              (_containerSize != containerSize || _selection == Rect.zero)) {
            setState(() => _updateLayout(containerSize));
          }
        });
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: ready
              ? (d) => setState(() => _dragMode = _hitTest(d.localPosition))
              : null,
          onPanUpdate: (d) => _applyDelta(d.delta),
          onPanEnd: (_) => setState(() => _dragMode = _DragMode.none),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(widget.image.path), fit: BoxFit.contain),
              if (ready)
                CustomPaint(
                  painter: _CropOverlayPainter(
                    selection: _selection,
                    showGrid: _dragMode != _DragMode.none,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay painter: dim mask + border + rule-of-thirds grid + corner brackets +
// edge midpoint handles
// ─────────────────────────────────────────────────────────────────────────────
class _CropOverlayPainter extends CustomPainter {
  final Rect selection;
  final bool showGrid;

  const _CropOverlayPainter({required this.selection, this.showGrid = false});

  static const double _bracketLen = 22.0;
  static const double _bracketThick = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final sel = selection;

    // Dim outside
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(sel),
      ),
      dimPaint,
    );

    // Border
    canvas.drawRect(
      sel,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    // Rule-of-thirds grid while dragging
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      for (int i = 1; i <= 2; i++) {
        canvas.drawLine(
          Offset(sel.left + sel.width / 3 * i, sel.top),
          Offset(sel.left + sel.width / 3 * i, sel.bottom),
          gridPaint,
        );
        canvas.drawLine(
          Offset(sel.left, sel.top + sel.height / 3 * i),
          Offset(sel.right, sel.top + sel.height / 3 * i),
          gridPaint,
        );
      }
    }

    _drawCorners(canvas, sel);
  }

  void _drawCorners(Canvas canvas, Rect sel) {
    // Radius of the rounded corner bend.
    const double r = 8.0;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..strokeWidth = _bracketThick + 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = _bracketThick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Build a rounded-corner L-bracket.
    // pt   = the corner point of the selection rect.
    // dx/dy = inward direction (+1 or -1) along x and y.
    Path makeCorner(Offset pt, double dx, double dy) {
      // Horizontal arm end → start of arc tangent point.
      final hx = pt.dx + dx * _bracketLen;
      final hy = pt.dy;
      // Vertical arm start (after the arc).
      final vx = pt.dx;
      final vy = pt.dy + dy * _bracketLen;
      // Arc centre is inset by r from the corner.
      final cx = pt.dx + dx * r;
      final cy = pt.dy + dy * r;

      return Path()
        ..moveTo(hx, hy)
        ..lineTo(cx, hy) // horizontal arm up to arc start
        ..arcToPoint(
          Offset(vx, cy), // arc end (start of vertical arm)
          radius: Radius.circular(r),
          clockwise: dx * dy < 0, // direction depends on which corner
        )
        ..lineTo(vx, vy); // vertical arm
    }

    for (final path in [
      makeCorner(sel.topLeft, 1, 1),
      makeCorner(sel.topRight, -1, 1),
      makeCorner(sel.bottomRight, -1, -1),
      makeCorner(sel.bottomLeft, 1, -1),
    ]) {
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) =>
      old.selection != selection || old.showGrid != showGrid;
}
