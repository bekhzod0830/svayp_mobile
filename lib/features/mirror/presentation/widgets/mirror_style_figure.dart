import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Иллюстрация стиля — в той же манере, что силуэты фигуры
/// (`lib/img/body_type/*.png`, [MirrorMaleBodyFigure]): чёрный контур,
/// бежевая заливка, белый фон. Готовых картинок нет, и владелец решил
/// рисовать кодом (2026-10-06), поэтому каждый стиль — раскладка двух вещей
/// (верх поверх низа) или одно длинное платье. Набор вещей зависит от пола:
/// у мужчин «классика» — пиджак без галстука, «деловой» — с галстуком.
class MirrorStyleFigure extends StatelessWidget {
  const MirrorStyleFigure({
    super.key,
    required this.style,
    required this.gender,
  });

  /// Код стиля: CLASSIC, CASUAL, MODEST_CHIC, EVENING, OFFICE_SMART, SPORTY.
  final String style;

  /// FEMALE или MALE; неизвестный пол рисуется как женский.
  final String? gender;

  /// Есть ли рисунок для [code] у этого пола.
  static bool supports(String? code, String? gender) =>
      _outfits[_genderKey(gender)]!.containsKey(code);

  static String _genderKey(String? gender) =>
      gender == 'MALE' ? 'MALE' : 'FEMALE';

  @override
  Widget build(BuildContext context) {
    final outfit = _outfits[_genderKey(gender)]![style];
    if (outfit == null) return const SizedBox.shrink();
    // Та же пропорция холста, что у силуэтов фигуры.
    return AspectRatio(
      aspectRatio: 372 / 404,
      child: CustomPaint(painter: _OutfitPainter(outfit)),
    );
  }
}

/// Фигура пола: женщина в платье, мужчина в футболке и брюках — той же
/// манеры, что стили, чтобы карточки трёх шагов читались как одна серия.
class MirrorGenderFigure extends StatelessWidget {
  const MirrorGenderFigure({super.key, required this.gender});

  final String gender;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 372 / 404,
      child: CustomPaint(painter: _PersonPainter(male: gender == 'MALE')),
    );
  }
}

enum _Garment {
  tee,
  blouse,
  blazer,
  suitJacket,
  hoodie,
  zipHoodie,
  trousers,
  chinos,
  jeans,
  joggers,
  pencilSkirt,
  gown,
  abaya,
}

/// Вещи рисуются по порядку: низ, потом верх поверх него.
const Map<String, Map<String, List<_Garment>>> _outfits = {
  'FEMALE': {
    'CLASSIC': [_Garment.trousers, _Garment.blazer],
    'CASUAL': [_Garment.jeans, _Garment.tee],
    'MODEST_CHIC': [_Garment.abaya],
    'EVENING': [_Garment.gown],
    'OFFICE_SMART': [_Garment.pencilSkirt, _Garment.blouse],
    'SPORTY': [_Garment.joggers, _Garment.hoodie],
  },
  'MALE': {
    'CLASSIC': [_Garment.chinos, _Garment.blazer],
    'CASUAL': [_Garment.jeans, _Garment.tee],
    'OFFICE_SMART': [_Garment.trousers, _Garment.suitJacket],
    'SPORTY': [_Garment.joggers, _Garment.zipHoodie],
  },
};

const _ink = Color(0xFF141414);
const _fill = Color(0xFFF4E4D8);
const _paper = Color(0xFFFFFFFF);

/// Перо: пути задаются в долях холста (0..1) и масштабируются при рисовании,
/// толщина линии — в пикселях, как у силуэтов фигуры.
class _Pen {
  _Pen(this.canvas, Size size)
      : w = size.width,
        h = size.height;

  final Canvas canvas;
  final double w;
  final double h;

  late final Paint line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(w * 0.016, 1.4)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = _ink;
  late final Paint thin = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(w * 0.009, 0.9)
    ..strokeCap = StrokeCap.round
    ..color = _ink.withValues(alpha: 0.75);
  late final Paint fill = Paint()..color = _fill;
  late final Paint paper = Paint()..color = _paper;
  late final Paint dark = Paint()..color = _ink;

  Path _scaled(Path p) => p.transform(Matrix4.diagonal3Values(w, h, 1).storage);

  /// Отражение по вертикальной оси холста: правый рукав из левого.
  static Path mirror(Path p) => p.transform(
        (Matrix4.diagonal3Values(-1, 1, 1)..setTranslationRaw(1, 0, 0)).storage,
      );

  /// Залить и обвести.
  void shape(Path p, {Paint? paint}) {
    final s = _scaled(p);
    canvas.drawPath(s, paint ?? fill);
    canvas.drawPath(s, line);
  }

  void stroke(Path p, {bool light = false}) =>
      canvas.drawPath(_scaled(p), light ? thin : line);

  void seg(double x1, double y1, double x2, double y2, {bool light = false}) =>
      canvas.drawLine(
        Offset(x1 * w, y1 * h),
        Offset(x2 * w, y2 * h),
        light ? thin : line,
      );

  void dot(double x, double y, [double r = 0.013]) =>
      canvas.drawCircle(Offset(x * w, y * h), w * r, dark);

  void oval(double cx, double cy, double rx, double ry, {Paint? paint}) {
    final rect = Rect.fromCenter(
      center: Offset(cx * w, cy * h),
      width: rx * 2 * w,
      height: ry * 2 * h,
    );
    canvas.drawOval(rect, paint ?? fill);
    canvas.drawOval(rect, line);
  }
}

class _OutfitPainter extends CustomPainter {
  const _OutfitPainter(this.garments);

  final List<_Garment> garments;

  @override
  void paint(Canvas canvas, Size size) {
    final k = _Pen(canvas, size);
    for (final g in garments) {
      switch (g) {
        case _Garment.tee:
          _tee(k);
        case _Garment.blouse:
          _blouse(k);
        case _Garment.blazer:
          _blazer(k, tie: false);
        case _Garment.suitJacket:
          _blazer(k, tie: true);
        case _Garment.hoodie:
          _hoodie(k, zip: false);
        case _Garment.zipHoodie:
          _hoodie(k, zip: true);
        case _Garment.trousers:
          _trousers(k, creases: true);
        case _Garment.chinos:
          _trousers(k, creases: false, cuffs: true);
        case _Garment.jeans:
          _jeans(k);
        case _Garment.joggers:
          _joggers(k);
        case _Garment.pencilSkirt:
          _pencilSkirt(k);
        case _Garment.gown:
          _gown(k);
        case _Garment.abaya:
          _abaya(k);
      }
    }
  }

  // ── Верх ──────────────────────────────────────────────────────────────────

  /// Длинный рукав, висящий вдоль тела и сужающийся к манжете (левый;
  /// правый — отражение).
  static Path _longSleeve() => Path()
    ..moveTo(0.34, 0.10)
    ..lineTo(0.13, 0.19)
    ..lineTo(0.17, 0.52)
    ..lineTo(0.26, 0.53)
    ..lineTo(0.30, 0.29)
    ..close();

  static Path _shortSleeve() => Path()
    ..moveTo(0.34, 0.10)
    ..lineTo(0.14, 0.20)
    ..lineTo(0.20, 0.34)
    ..lineTo(0.30, 0.31)
    ..close();

  /// Корпус с круглым вырезом; [hem] — низ, [waist] — талия (0 — прямые
  /// бока, больше — приталено).
  static Path _torso({required double hem, double waist = 0}) => Path()
    ..moveTo(0.30, 0.09)
    ..lineTo(0.40, 0.075)
    ..quadraticBezierTo(0.50, 0.17, 0.60, 0.075)
    ..lineTo(0.70, 0.09)
    ..lineTo(0.71, 0.28)
    ..cubicTo(0.71 - waist, 0.36, 0.71 - waist, 0.44, 0.70, hem)
    ..lineTo(0.30, hem)
    ..cubicTo(0.29 + waist, 0.44, 0.29 + waist, 0.36, 0.29, 0.28)
    ..close();

  static void _tee(_Pen k) {
    k.shape(_shortSleeve());
    k.shape(_Pen.mirror(_shortSleeve()));
    k.shape(_torso(hem: 0.50));
    // Бейка горловины.
    k.stroke(
      Path()
        ..moveTo(0.41, 0.10)
        ..quadraticBezierTo(0.50, 0.195, 0.59, 0.10),
      light: true,
    );
  }

  static void _blouse(_Pen k) {
    k.shape(_longSleeve());
    k.shape(_Pen.mirror(_longSleeve()));
    k.shape(_torso(hem: 0.52, waist: 0.045));
    // V-вырез с маленьким воротником и планка с пуговицами.
    k.shape(
      Path()
        ..moveTo(0.42, 0.08)
        ..lineTo(0.50, 0.24)
        ..lineTo(0.58, 0.08)
        ..close(),
      paint: k.paper,
    );
    k.stroke(
      Path()
        ..moveTo(0.42, 0.08)
        ..lineTo(0.36, 0.15)
        ..lineTo(0.47, 0.18),
    );
    k.stroke(
      Path()
        ..moveTo(0.58, 0.08)
        ..lineTo(0.64, 0.15)
        ..lineTo(0.53, 0.18),
    );
    k.seg(0.50, 0.24, 0.50, 0.52, light: true);
    for (final y in [0.30, 0.37, 0.44]) {
      k.dot(0.50, y, 0.010);
    }
    // Манжеты.
    k.seg(0.155, 0.47, 0.245, 0.48, light: true);
    k.seg(0.845, 0.47, 0.755, 0.48, light: true);
  }

  static void _blazer(_Pen k, {required bool tie}) {
    k.shape(_longSleeve());
    k.shape(_Pen.mirror(_longSleeve()));
    k.shape(_torso(hem: 0.55));
    // Борта: белый вырез под рубашку, лацканы, пуговицы, карманы.
    k.shape(
      Path()
        ..moveTo(0.40, 0.08)
        ..lineTo(0.50, 0.36)
        ..lineTo(0.60, 0.08)
        ..close(),
      paint: k.paper,
    );
    k.stroke(
      Path()
        ..moveTo(0.40, 0.08)
        ..lineTo(0.345, 0.17)
        ..lineTo(0.43, 0.215),
    );
    k.stroke(
      Path()
        ..moveTo(0.60, 0.08)
        ..lineTo(0.655, 0.17)
        ..lineTo(0.57, 0.215),
    );
    k.seg(0.50, 0.36, 0.50, 0.55);
    k.dot(0.50, 0.40);
    k.dot(0.50, 0.47);
    k.seg(0.33, 0.46, 0.42, 0.46, light: true);
    k.seg(0.58, 0.46, 0.67, 0.46, light: true);
    if (tie) {
      k.canvas.drawPath(
        k._scaled(
          Path()
            ..moveTo(0.47, 0.085)
            ..lineTo(0.53, 0.085)
            ..lineTo(0.525, 0.125)
            ..lineTo(0.55, 0.30)
            ..lineTo(0.50, 0.355)
            ..lineTo(0.45, 0.30)
            ..lineTo(0.475, 0.125)
            ..close(),
        ),
        k.dark,
      );
    } else {
      // Без галстука: ворот рубашки.
      k.stroke(
        Path()
          ..moveTo(0.445, 0.085)
          ..lineTo(0.50, 0.17)
          ..lineTo(0.555, 0.085),
        light: true,
      );
    }
  }

  static void _hoodie(_Pen k, {required bool zip}) {
    // Капюшон — за корпусом.
    k.shape(
      Path()
        ..moveTo(0.37, 0.10)
        ..cubicTo(0.38, -0.01, 0.62, -0.01, 0.63, 0.10)
        ..quadraticBezierTo(0.50, 0.18, 0.37, 0.10)
        ..close(),
    );
    k.stroke(
      Path()
        ..moveTo(0.42, 0.09)
        ..cubicTo(0.43, 0.025, 0.57, 0.025, 0.58, 0.09),
      light: true,
    );
    k.shape(_longSleeve());
    k.shape(_Pen.mirror(_longSleeve()));
    k.shape(_torso(hem: 0.54));
    // Шнурки.
    k.seg(0.465, 0.16, 0.455, 0.29);
    k.seg(0.535, 0.16, 0.545, 0.29);
    k.dot(0.455, 0.30, 0.010);
    k.dot(0.545, 0.30, 0.010);
    if (zip) {
      k.seg(0.50, 0.17, 0.50, 0.54);
      for (var y = 0.20; y < 0.53; y += 0.04) {
        k.seg(0.485, y, 0.515, y, light: true);
      }
    } else {
      // Карман-кенгуру.
      k.stroke(
        Path()
          ..moveTo(0.34, 0.40)
          ..lineTo(0.40, 0.37)
          ..lineTo(0.60, 0.37)
          ..lineTo(0.66, 0.40)
          ..lineTo(0.66, 0.52)
          ..lineTo(0.34, 0.52)
          ..close(),
      );
    }
    // Резинка по низу.
    k.seg(0.30, 0.505, 0.70, 0.505, light: true);
  }

  // ── Низ ───────────────────────────────────────────────────────────────────

  static void _waistband(_Pen k, double left, double right) {
    k.shape(
      Path()
        ..moveTo(left, 0.46)
        ..lineTo(right, 0.46)
        ..lineTo(right, 0.51)
        ..lineTo(left, 0.51)
        ..close(),
    );
  }

  static Path _legs({
    required double hipL,
    required double hemOuter,
    required double hemInner,
    double hemY = 0.96,
    double crotch = 0.64,
  }) =>
      Path()
        ..moveTo(hipL, 0.51)
        ..lineTo(hemOuter, hemY)
        ..lineTo(hemInner, hemY)
        ..lineTo(0.50, crotch)
        ..lineTo(1 - hemInner, hemY)
        ..lineTo(1 - hemOuter, hemY)
        ..lineTo(1 - hipL, 0.51)
        ..close();

  static void _trousers(_Pen k, {required bool creases, bool cuffs = false}) {
    k.shape(_legs(hipL: 0.33, hemOuter: 0.31, hemInner: 0.465));
    _waistband(k, 0.33, 0.67);
    k.seg(0.50, 0.51, 0.50, 0.62, light: true);
    if (creases) {
      k.seg(0.40, 0.56, 0.39, 0.94, light: true);
      k.seg(0.60, 0.56, 0.61, 0.94, light: true);
    }
    if (cuffs) {
      k.seg(0.315, 0.915, 0.467, 0.915, light: true);
      k.seg(0.533, 0.915, 0.685, 0.915, light: true);
    }
  }

  static void _jeans(_Pen k) {
    k.shape(_legs(hipL: 0.33, hemOuter: 0.335, hemInner: 0.465));
    _waistband(k, 0.33, 0.67);
    // Карманы, ширинка, шлёвки, отворот.
    k.stroke(
      Path()
        ..moveTo(0.335, 0.53)
        ..quadraticBezierTo(0.41, 0.53, 0.43, 0.60),
      light: true,
    );
    k.stroke(
      Path()
        ..moveTo(0.665, 0.53)
        ..quadraticBezierTo(0.59, 0.53, 0.57, 0.60),
      light: true,
    );
    k.stroke(
      Path()
        ..moveTo(0.50, 0.51)
        ..lineTo(0.50, 0.62)
        ..quadraticBezierTo(0.46, 0.60, 0.465, 0.53),
      light: true,
    );
    for (final x in [0.37, 0.50, 0.63]) {
      k.seg(x, 0.465, x, 0.505, light: true);
    }
    k.seg(0.34, 0.92, 0.465, 0.92, light: true);
    k.seg(0.535, 0.92, 0.66, 0.92, light: true);
  }

  static void _joggers(_Pen k) {
    k.shape(_legs(hipL: 0.33, hemOuter: 0.385, hemInner: 0.47, hemY: 0.90));
    _waistband(k, 0.33, 0.67);
    // Манжеты, шнурок, лампасы.
    for (final l in [0.385, 0.53]) {
      k.shape(
        Path()
          ..moveTo(l, 0.90)
          ..lineTo(l + 0.085, 0.90)
          ..lineTo(l + 0.085, 0.96)
          ..lineTo(l, 0.96)
          ..close(),
      );
    }
    k.seg(0.47, 0.485, 0.455, 0.57);
    k.seg(0.53, 0.485, 0.545, 0.57);
    k.seg(0.345, 0.53, 0.40, 0.89, light: true);
    k.seg(0.655, 0.53, 0.60, 0.89, light: true);
  }

  static void _pencilSkirt(_Pen k) {
    k.shape(
      Path()
        ..moveTo(0.34, 0.51)
        ..quadraticBezierTo(0.33, 0.62, 0.37, 0.88)
        ..lineTo(0.63, 0.88)
        ..quadraticBezierTo(0.67, 0.62, 0.66, 0.51)
        ..close(),
    );
    _waistband(k, 0.34, 0.66);
    // Шлица.
    k.seg(0.50, 0.74, 0.50, 0.88, light: true);
  }

  // ── Платья ────────────────────────────────────────────────────────────────

  static void _gown(_Pen k) {
    k.seg(0.425, 0.06, 0.435, 0.15, light: true);
    k.seg(0.575, 0.06, 0.565, 0.15, light: true);
    k.shape(
      Path()
        ..moveTo(0.37, 0.15)
        ..quadraticBezierTo(0.435, 0.105, 0.50, 0.165)
        ..quadraticBezierTo(0.565, 0.105, 0.63, 0.15)
        ..cubicTo(0.64, 0.25, 0.61, 0.33, 0.60, 0.40)
        ..cubicTo(0.63, 0.56, 0.78, 0.78, 0.80, 0.95)
        ..quadraticBezierTo(0.50, 1.0, 0.20, 0.95)
        ..cubicTo(0.22, 0.78, 0.37, 0.56, 0.40, 0.40)
        ..cubicTo(0.39, 0.33, 0.36, 0.25, 0.37, 0.15)
        ..close(),
    );
    // Шов по талии и складки юбки.
    k.seg(0.40, 0.40, 0.60, 0.40);
    k.stroke(
      Path()
        ..moveTo(0.47, 0.42)
        ..quadraticBezierTo(0.40, 0.70, 0.36, 0.93),
      light: true,
    );
    k.stroke(
      Path()
        ..moveTo(0.56, 0.44)
        ..quadraticBezierTo(0.60, 0.70, 0.66, 0.94),
      light: true,
    );
  }

  static void _abaya(_Pen k) {
    k.shape(
      Path()
        ..moveTo(0.27, 0.30)
        ..lineTo(0.12, 0.96)
        ..lineTo(0.88, 0.96)
        ..lineTo(0.73, 0.30)
        ..close(),
    );
    // Рукава и застёжка.
    k.seg(0.33, 0.33, 0.235, 0.70, light: true);
    k.seg(0.67, 0.33, 0.765, 0.70, light: true);
    k.seg(0.50, 0.33, 0.50, 0.96, light: true);
    // Платок поверх плеч, лицо — белый овал.
    k.shape(
      Path()
        ..moveTo(0.50, 0.025)
        ..cubicTo(0.31, 0.025, 0.29, 0.21, 0.26, 0.31)
        ..lineTo(0.74, 0.31)
        ..cubicTo(0.71, 0.21, 0.69, 0.025, 0.50, 0.025)
        ..close(),
    );
    k.oval(0.50, 0.145, 0.085, 0.105, paint: k.paper);
  }

  @override
  bool shouldRepaint(_OutfitPainter old) => old.garments != garments;
}

/// Фигура человека: голова, платье или футболка с брюками, руки и ноги —
/// пиктограмма, но той же манеры, что раскладки стилей.
class _PersonPainter extends CustomPainter {
  const _PersonPainter({required this.male});

  final bool male;

  @override
  void paint(Canvas canvas, Size size) {
    final k = _Pen(canvas, size);
    k.oval(0.50, 0.11, 0.08, 0.075, paint: k.paper);
    k.seg(0.47, 0.185, 0.465, 0.235);
    k.seg(0.53, 0.185, 0.535, 0.235);

    if (male) {
      // Футболка, брюки, руки и ступни.
      k.shape(
        Path()
          ..moveTo(0.33, 0.25)
          ..lineTo(0.22, 0.31)
          ..lineTo(0.26, 0.43)
          ..lineTo(0.345, 0.405)
          ..close(),
      );
      k.shape(
        Path()
          ..moveTo(0.67, 0.25)
          ..lineTo(0.78, 0.31)
          ..lineTo(0.74, 0.43)
          ..lineTo(0.655, 0.405)
          ..close(),
      );
      k.shape(
        Path()
          ..moveTo(0.345, 0.58)
          ..lineTo(0.355, 0.94)
          ..lineTo(0.47, 0.94)
          ..lineTo(0.50, 0.68)
          ..lineTo(0.53, 0.94)
          ..lineTo(0.645, 0.94)
          ..lineTo(0.655, 0.58)
          ..close(),
      );
      k.shape(
        Path()
          ..moveTo(0.33, 0.25)
          ..lineTo(0.44, 0.235)
          ..quadraticBezierTo(0.50, 0.29, 0.56, 0.235)
          ..lineTo(0.67, 0.25)
          ..lineTo(0.655, 0.58)
          ..lineTo(0.345, 0.58)
          ..close(),
      );
      k.seg(0.255, 0.43, 0.235, 0.62);
      k.seg(0.745, 0.43, 0.765, 0.62);
      k.seg(0.345, 0.95, 0.47, 0.95);
      k.seg(0.53, 0.95, 0.655, 0.95);
    } else {
      // Платье А-силуэта, руки, ноги и ступни.
      k.seg(0.36, 0.26, 0.29, 0.54);
      k.seg(0.64, 0.26, 0.71, 0.54);
      k.seg(0.445, 0.80, 0.445, 0.95);
      k.seg(0.555, 0.80, 0.555, 0.95);
      k.seg(0.405, 0.955, 0.465, 0.955);
      k.seg(0.535, 0.955, 0.595, 0.955);
      k.shape(
        Path()
          ..moveTo(0.36, 0.25)
          ..quadraticBezierTo(0.50, 0.31, 0.64, 0.25)
          ..cubicTo(0.63, 0.33, 0.59, 0.40, 0.58, 0.46)
          ..cubicTo(0.63, 0.56, 0.70, 0.68, 0.72, 0.80)
          ..lineTo(0.28, 0.80)
          ..cubicTo(0.30, 0.68, 0.37, 0.56, 0.42, 0.46)
          ..cubicTo(0.41, 0.40, 0.37, 0.33, 0.36, 0.25)
          ..close(),
      );
      k.seg(0.42, 0.46, 0.58, 0.46, light: true);
    }
  }

  @override
  bool shouldRepaint(_PersonPainter old) => old.male != male;
}
