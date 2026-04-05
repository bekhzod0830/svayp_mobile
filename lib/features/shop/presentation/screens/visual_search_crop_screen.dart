import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Embeddable interactive crop widget.
// Drop it inside any parent (e.g. a bottom sheet).
// Use a GlobalKey<VisualSearchCropWidgetState> to call cropImage() / resetSelection().
// ─────────────────────────────────────────────────────────────────────────────
class VisualSearchCropWidget extends StatefulWidget {
  final XFile image;

  const VisualSearchCropWidget({super.key, required this.image});

  @override
  State<VisualSearchCropWidget> createState() => VisualSearchCropWidgetState();
}

class VisualSearchCropWidgetState extends State<VisualSearchCropWidget> {
  ui.Image? _uiImage;
  Size? _naturalSize;

  // Selection rect in display coordinates (relative to the container widget).
  Rect _selection = Rect.zero;

  // Computed once we have both container size and natural image size.
  Rect _imageRect = Rect.zero;
  Size _containerSize = Size.zero;

  /// Reset selection to the full image bounds (call via GlobalKey).
  void resetSelection() => setState(() => _selection = _imageRect);

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  // Load the image into a ui.Image so we can decode its natural size and later
  // crop it pixel-accurately.
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

  // Replicate Flutter's BoxFit.contain placement of image inside container.
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
    final dx = (container.width - w) / 2;
    final dy = (container.height - h) / 2;
    return Rect.fromLTWH(dx, dy, w, h);
  }

  // Called by LayoutBuilder whenever the container size is known/changes.
  void _updateLayout(Size containerSize) {
    if (_naturalSize == null) return;
    if (containerSize == _containerSize && _selection != Rect.zero) return;
    _containerSize = containerSize;
    _imageRect = _containedRect(containerSize, _naturalSize!);
    // Initialize selection to full image bounds on first layout.
    if (_selection == Rect.zero) {
      _selection = _imageRect;
    }
  }

  static const double _minSize = 48.0;

  void _moveTopLeft(Offset delta) => setState(() {
    final l = (_selection.left + delta.dx).clamp(
      _imageRect.left,
      _selection.right - _minSize,
    );
    final t = (_selection.top + delta.dy).clamp(
      _imageRect.top,
      _selection.bottom - _minSize,
    );
    _selection = Rect.fromLTRB(l, t, _selection.right, _selection.bottom);
  });

  void _moveTopRight(Offset delta) => setState(() {
    final r = (_selection.right + delta.dx).clamp(
      _selection.left + _minSize,
      _imageRect.right,
    );
    final t = (_selection.top + delta.dy).clamp(
      _imageRect.top,
      _selection.bottom - _minSize,
    );
    _selection = Rect.fromLTRB(_selection.left, t, r, _selection.bottom);
  });

  void _moveBottomRight(Offset delta) => setState(() {
    final r = (_selection.right + delta.dx).clamp(
      _selection.left + _minSize,
      _imageRect.right,
    );
    final b = (_selection.bottom + delta.dy).clamp(
      _selection.top + _minSize,
      _imageRect.bottom,
    );
    _selection = Rect.fromLTRB(_selection.left, _selection.top, r, b);
  });

  void _moveBottomLeft(Offset delta) => setState(() {
    final l = (_selection.left + delta.dx).clamp(
      _imageRect.left,
      _selection.right - _minSize,
    );
    final b = (_selection.bottom + delta.dy).clamp(
      _selection.top + _minSize,
      _imageRect.bottom,
    );
    _selection = Rect.fromLTRB(l, _selection.top, _selection.right, b);
  });

  /// Crop the source image to the current selection and return a new [XFile].
  ///
  /// Output is capped at [_maxOutputDim] on the longest side to keep upload
  /// sizes well within server limits while retaining enough detail for AI
  /// visual search.
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

      // Scale down so neither dimension exceeds _maxOutputDim.
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
    } catch (e, stack) {
      return widget.image;
    }
  }

  // ── Handle widget ──────────────────────────────────────────────────────────
  /// Invisible touch radius (48 px – Apple/Material minimum tap target).
  static const double _hTouchR = 24.0;

  /// Visible dot radius.
  static const double _hVisR = 14.0;

  Widget _handle(Offset pos, void Function(Offset) onDrag) {
    return Positioned(
      left: pos.dx - _hTouchR,
      top: pos.dy - _hTouchR,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => onDrag(d.delta),
        child: SizedBox(
          width: _hTouchR * 2,
          height: _hTouchR * 2,
          child: Center(
            child: Container(
              width: _hVisR * 2,
              height: _hVisR * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Thin edge drag handle (wide invisible strip, no visible dot).
  Widget _edgeHandle({
    required double left,
    required double top,
    required double width,
    required double height,
    required void Function(Offset) onDrag,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => onDrag(d.delta),
        child: SizedBox(width: width, height: height),
      ),
    );
  }

  void _moveTop(Offset delta) => setState(() {
    final t = (_selection.top + delta.dy).clamp(
      _imageRect.top,
      _selection.bottom - _minSize,
    );
    _selection = Rect.fromLTRB(
      _selection.left,
      t,
      _selection.right,
      _selection.bottom,
    );
  });

  void _moveBottom(Offset delta) => setState(() {
    final b = (_selection.bottom + delta.dy).clamp(
      _selection.top + _minSize,
      _imageRect.bottom,
    );
    _selection = Rect.fromLTRB(
      _selection.left,
      _selection.top,
      _selection.right,
      b,
    );
  });

  void _moveLeft(Offset delta) => setState(() {
    final l = (_selection.left + delta.dx).clamp(
      _imageRect.left,
      _selection.right - _minSize,
    );
    _selection = Rect.fromLTRB(
      l,
      _selection.top,
      _selection.right,
      _selection.bottom,
    );
  });

  void _moveRight(Offset delta) => setState(() {
    final r = (_selection.right + delta.dx).clamp(
      _selection.left + _minSize,
      _imageRect.right,
    );
    _selection = Rect.fromLTRB(
      _selection.left,
      _selection.top,
      r,
      _selection.bottom,
    );
  });

  // ── build ──────────────────────────────────────────────────────────────────
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

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(widget.image.path), fit: BoxFit.contain),
            if (ready)
              CustomPaint(painter: _CropOverlayPainter(selection: _selection)),
            if (ready) ...[
              _handle(_selection.topLeft, _moveTopLeft),
              _handle(_selection.topRight, _moveTopRight),
              _handle(_selection.bottomRight, _moveBottomRight),
              _handle(_selection.bottomLeft, _moveBottomLeft),
              // Edge handles (invisible strips along each side)
              _edgeHandle(
                left: _selection.left + _hTouchR,
                top: _selection.top - _hTouchR,
                width: _selection.width - _hTouchR * 2,
                height: _hTouchR * 2,
                onDrag: _moveTop,
              ),
              _edgeHandle(
                left: _selection.left + _hTouchR,
                top: _selection.bottom - _hTouchR,
                width: _selection.width - _hTouchR * 2,
                height: _hTouchR * 2,
                onDrag: _moveBottom,
              ),
              _edgeHandle(
                left: _selection.left - _hTouchR,
                top: _selection.top + _hTouchR,
                width: _hTouchR * 2,
                height: _selection.height - _hTouchR * 2,
                onDrag: _moveLeft,
              ),
              _edgeHandle(
                left: _selection.right - _hTouchR,
                top: _selection.top + _hTouchR,
                width: _hTouchR * 2,
                height: _selection.height - _hTouchR * 2,
                onDrag: _moveRight,
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay painter: dims outside, draws the same rounded corner brackets
// ─────────────────────────────────────────────────────────────────────────────
class _CropOverlayPainter extends CustomPainter {
  final Rect selection;

  const _CropOverlayPainter({required this.selection});

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent dim outside selection
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.52);
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final selPath = Path()
      ..addRRect(RRect.fromRectAndRadius(selection, Radius.zero));
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, selPath),
      dimPaint,
    );

    // Thin border around the selection
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(selection, borderPaint);

    // Rounded corner brackets (same style as results screen)
    const armLen = 26.0;
    const cr = 14.0;
    const strokeW = 3.0;

    final bracketPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final corners = [
      (selection.topLeft, 1.0, 1.0),
      (selection.topRight, -1.0, 1.0),
      (selection.bottomRight, -1.0, -1.0),
      (selection.bottomLeft, 1.0, -1.0),
    ];

    for (final (origin, sx, sy) in corners) {
      final path = Path()
        ..moveTo(origin.dx + sx * armLen, origin.dy)
        ..lineTo(origin.dx + sx * cr, origin.dy)
        ..arcToPoint(
          Offset(origin.dx, origin.dy + sy * cr),
          radius: const Radius.circular(cr),
          clockwise: sx * sy < 0,
        )
        ..lineTo(origin.dx, origin.dy + sy * armLen);
      canvas.drawPath(path, bracketPaint);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) => old.selection != selection;
}
