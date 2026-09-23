import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Мужской силуэт типа фигуры — в той же манере, что женские иллюстрации
/// (`lib/img/body_type/*.png`): чёрный контур торса с руками поверх бежевой
/// геометрической фигуры. Для мужчин готовых картинок нет, поэтому силуэт
/// рисуется кодом: ширина плеч, талии и бёдер и фоновая фигура зависят от
/// типа, и карточки перестают быть одинаковыми.
class MirrorMaleBodyFigure extends StatelessWidget {
  const MirrorMaleBodyFigure({super.key, required this.shape});

  /// Код типа фигуры: RECTANGLE, INVERTED_TRIANGLE, TRIANGLE, OVAL.
  final String shape;

  /// Есть ли рисунок для [code].
  static bool supports(String? code) => _proportions.containsKey(code);

  @override
  Widget build(BuildContext context) {
    final p = _proportions[shape];
    if (p == null) return const SizedBox.shrink();
    // Та же пропорция холста, что у женских картинок (372×404).
    return AspectRatio(
      aspectRatio: 372 / 404,
      child: CustomPaint(painter: _MaleBodyPainter(shape: shape, p: p)),
    );
  }
}

/// Полуширины от центра в долях ширины холста.
class _Proportions {
  const _Proportions({
    required this.shoulder,
    required this.chest,
    required this.waist,
    required this.hip,
  });

  final double shoulder;
  final double chest;
  final double waist;
  final double hip;
}

const Map<String, _Proportions> _proportions = {
  // Плечи, грудь, талия и бёдра почти одной ширины.
  'RECTANGLE':
      _Proportions(shoulder: 0.33, chest: 0.26, waist: 0.24, hip: 0.245),
  // Широкие плечи и грудь, узкие талия и бёдра.
  'INVERTED_TRIANGLE':
      _Proportions(shoulder: 0.40, chest: 0.31, waist: 0.21, hip: 0.20),
  // Узкие плечи, низ шире верха.
  'TRIANGLE':
      _Proportions(shoulder: 0.27, chest: 0.215, waist: 0.25, hip: 0.29),
  // Округлый живот: талия шире груди и бёдер.
  'OVAL': _Proportions(shoulder: 0.32, chest: 0.26, waist: 0.33, hip: 0.27),
};

class _MaleBodyPainter extends CustomPainter {
  const _MaleBodyPainter({required this.shape, required this.p});

  final String shape;
  final _Proportions p;

  static const _ink = Color(0xFF141414);
  static const _fill = Color(0xFFF4E4D8);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const cx = 0.5;
    Offset at(double x, double y) => Offset(x * w, y * h);

    _paintBackdrop(canvas, size, at);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(w * 0.016, 1.4)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _ink;

    // Контрольные высоты.
    const yShoulder = 0.19;
    const yArmpit = 0.31;
    const yChest = 0.40;
    const yWaist = 0.62;
    const yHip = 0.86;

    for (final side in [-1.0, 1.0]) {
      double x(double half) => cx + side * half;

      // Шея и плечо.
      canvas.drawPath(
        Path()
          ..moveTo(at(x(0.075), 0).dx, 0)
          ..lineTo(at(x(0.08), 0.075).dx, at(0, 0.075).dy)
          ..quadraticBezierTo(
            at(x(0.10), 0.13).dx,
            at(0, 0.13).dy,
            at(x(p.shoulder - 0.07), 0.14).dx,
            at(0, 0.14).dy,
          )
          ..quadraticBezierTo(
            at(x(p.shoulder), 0.15).dx,
            at(0, 0.15).dy,
            at(x(p.shoulder), yShoulder + 0.07).dx,
            at(0, yShoulder + 0.07).dy,
          ),
        line,
      );

      // Внешний край руки: от плеча вниз, следом за контуром тела.
      final armOut = Path()
        ..moveTo(at(x(p.shoulder), yShoulder + 0.07).dx,
            at(0, yShoulder + 0.07).dy)
        ..cubicTo(
          at(x(p.shoulder + 0.01), 0.42).dx,
          at(0, 0.42).dy,
          at(x(p.waist + 0.10), 0.58).dx,
          at(0, 0.58).dy,
          at(x(math.max(p.waist, p.hip) + 0.105), 1.0).dx,
          h,
        );
      canvas.drawPath(armOut, line);

      // Внутренний край руки.
      final armIn = Path()
        ..moveTo(at(x(p.chest + 0.02), yArmpit).dx, at(0, yArmpit).dy)
        ..cubicTo(
          at(x(p.chest + 0.02), 0.45).dx,
          at(0, 0.45).dy,
          at(x(p.waist + 0.035), 0.60).dx,
          at(0, 0.60).dy,
          at(x(math.max(p.waist, p.hip) + 0.04), 1.0).dx,
          h,
        );
      canvas.drawPath(armIn, line);

      // Бок торса: подмышка → талия → бёдра → низ.
      final torso = Path()
        ..moveTo(at(x(p.chest), yArmpit + 0.01).dx, at(0, yArmpit + 0.01).dy)
        ..cubicTo(
          at(x(p.chest), 0.47).dx,
          at(0, 0.47).dy,
          at(x(p.waist), yWaist - 0.08).dx,
          at(0, yWaist - 0.08).dy,
          at(x(p.waist), yWaist).dx,
          at(0, yWaist).dy,
        )
        ..cubicTo(
          at(x(p.waist), yWaist + 0.1).dx,
          at(0, yWaist + 0.1).dy,
          at(x(p.hip), yHip - 0.08).dx,
          at(0, yHip - 0.08).dy,
          at(x(p.hip), yHip).dx,
          at(0, yHip).dy,
        )
        ..lineTo(at(x(p.hip - 0.005), 1.0).dx, h);
      canvas.drawPath(torso, line);

      // Линия грудной мышцы.
      canvas.drawPath(
        Path()
          ..moveTo(at(x(0.03), yChest + 0.035).dx, at(0, yChest + 0.035).dy)
          ..quadraticBezierTo(
            at(x(p.chest * 0.55), yChest + 0.07).dx,
            at(0, yChest + 0.07).dy,
            at(x(p.chest - 0.035), yChest + 0.01).dx,
            at(0, yChest + 0.01).dy,
          ),
        line,
      );
    }

    // Пах: узкая перевёрнутая «V» внизу по центру.
    canvas.drawPath(
      Path()
        ..moveTo(at(cx - 0.05, 1.0).dx, h)
        ..lineTo(at(cx - 0.012, 0.915).dx, at(0, 0.915).dy)
        ..quadraticBezierTo(
          at(cx, 0.905).dx,
          at(0, 0.905).dy,
          at(cx + 0.012, 0.915).dx,
          at(0, 0.915).dy,
        )
        ..lineTo(at(cx + 0.05, 1.0).dx, h),
      line,
    );

    // Пупок — у овала живот главный признак.
    if (shape == 'OVAL') {
      canvas.drawCircle(at(cx, 0.66), w * 0.008, Paint()..color = _ink);
    }
  }

  /// Бежевая фигура за торсом — как на женских иллюстрациях.
  void _paintBackdrop(
    Canvas canvas,
    Size size,
    Offset Function(double, double) at,
  ) {
    final fill = Paint()..color = _fill;
    switch (shape) {
      case 'RECTANGLE':
        canvas.drawRect(
          Rect.fromPoints(at(0.26, 0.17), at(0.74, 0.93)),
          fill,
        );
      case 'INVERTED_TRIANGLE':
        canvas.drawPath(
          Path()
            ..moveTo(at(0.13, 0.17).dx, at(0, 0.17).dy)
            ..lineTo(at(0.87, 0.17).dx, at(0, 0.17).dy)
            ..lineTo(at(0.5, 0.97).dx, at(0, 0.97).dy)
            ..close(),
          fill,
        );
      case 'TRIANGLE':
        canvas.drawPath(
          Path()
            ..moveTo(at(0.5, 0.08).dx, at(0, 0.08).dy)
            ..lineTo(at(0.85, 0.93).dx, at(0, 0.93).dy)
            ..lineTo(at(0.15, 0.93).dx, at(0, 0.93).dy)
            ..close(),
          fill,
        );
      case 'OVAL':
        canvas.drawCircle(at(0.5, 0.58), size.width * 0.34, fill);
    }
  }

  @override
  bool shouldRepaint(_MaleBodyPainter old) => old.shape != shape;
}
