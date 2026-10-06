import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../mirror_theme.dart';

/// Контур зеркала: по умолчанию арка — полукруглый верх, прямые стенки,
/// мягкие нижние углы; у бренда с [MirrorArchShape.window] — прямоугольная
/// витрина. Путь начинается в левом нижнем углу и идёт вверх, через верх,
/// вниз по правой стенке и по низу обратно — поэтому его удобно
/// «дорисовывать» по прогрессу (экран генерации).
Path mirrorArchPath(Size size, [MirrorArchShape shape = MirrorArchShape.arch]) {
  final w = size.width;
  final h = size.height;
  final rb = w * shape.corner;
  final r = (w / 2 * shape.top).clamp(rb, w / 2);
  return Path()
    ..moveTo(0, h - rb)
    ..lineTo(0, r)
    ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
    ..lineTo(w - r, 0)
    ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
    ..lineTo(w, h - rb)
    ..arcToPoint(Offset(w - rb, h), radius: Radius.circular(rb))
    ..lineTo(rb, h)
    ..arcToPoint(Offset(0, h - rb), radius: Radius.circular(rb))
    ..close();
}

/// Стекло зеркала одного размера на всех экранах киоска — постере, камере,
/// генерации и результате: покупатель на каждом шаге видит одну и ту же
/// раму. Размер считается от экрана, а не от свободного места конкретной
/// вёрстки: по высоте — экран без системных полей минус место под текст и
/// кнопки самого плотного экрана (камера: заголовок, подсказка, две кнопки
/// и подпись), по ширине — поля по 28 единиц. Экраны подстраивают свои
/// отступы под этот размер, а не наоборот.
Size mirrorGlassSize(
  Size screen,
  EdgeInsets padding,
  MirrorArchShape shape,
  double s,
) {
  final usable = screen.height - padding.vertical;
  final maxH = math.max(usable - 320 * s, 160.0);
  final maxW = math.max(screen.width - 56 * s, 120.0);
  final w = math.min(maxH * shape.aspect, maxW);
  return Size(w, w / shape.aspect);
}

/// То же от контекста экрана.
Size mirrorGlassSizeOf(BuildContext context) => mirrorGlassSize(
      MediaQuery.sizeOf(context),
      MediaQuery.paddingOf(context),
      MirrorTheme.of(context).mirror,
      MirrorTheme.scale(context),
    );

/// Стекло общего размера в боксе экрана, по центру [center] (по умолчанию —
/// центр бокса). Если бокс меньше стекла с рамой — чего в штатных вёрстках
/// не бывает — стекло уменьшается, сохраняя пропорцию. [margin] — поле
/// от краёв бокса, по умолчанию под раму ([mirrorFrameInset]).
Rect mirrorGlassRect(
  BuildContext context,
  Size box, {
  Offset? center,
  double? margin,
}) {
  final glass = mirrorGlassSizeOf(context);
  final shape = MirrorTheme.of(context).mirror;
  final m = margin ?? mirrorFrameInset(shape, MirrorTheme.scale(context));
  final fitW = math.max(box.width - m * 2, 40.0);
  final fitH = math.max(box.height - m * 2, 40.0);
  var w = math.min(glass.width, fitW);
  var h = w / shape.aspect;
  if (h > fitH) {
    h = fitH;
    w = h * shape.aspect;
  }
  return Rect.fromCenter(
    center: center ?? Offset(box.width / 2, box.height / 2),
    width: w,
    height: h,
  );
}

/// Отступ рамы от стекла: контур рисуется снаружи стекла на этом
/// расстоянии. У двойной рамы по кромке стекла проходит волосяная линия.
double mirrorFrameInset(MirrorArchShape shape, double s) =>
    shape.doubleLine ? 7 * s : 8 * s;

/// Обрезка по арке [mirrorArchPath].
class MirrorArchClipper extends CustomClipper<Path> {
  const MirrorArchClipper([this.shape = MirrorArchShape.arch]);

  final MirrorArchShape shape;

  @override
  Path getClip(Size size) => mirrorArchPath(size, shape);

  @override
  bool shouldReclip(MirrorArchClipper oldClipper) => oldClipper.shape != shape;
}

/// Мягкое свечение цветом бренда за зеркалом. Арка — овальный ореол;
/// витрина — свет по контуру рамы и пятно на «полу» под ней, как
/// подсветка витрины магазина. [arch] — прямоугольник стекла.
class MirrorArchHaloPainter extends CustomPainter {
  const MirrorArchHaloPainter({
    required this.arch,
    required this.color,
    required this.strength,
    this.shape = MirrorArchShape.arch,
    this.s = 1,
  });

  final Rect arch;
  final Color color;
  final double strength;
  final MirrorArchShape shape;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    if (shape.doubleLine) {
      _paintWindow(canvas);
      return;
    }
    final rect = arch.inflate(arch.width * 0.45);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: strength),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  void _paintWindow(Canvas canvas) {
    final frame = arch.inflate(mirrorFrameInset(shape, s));
    final path = mirrorArchPath(frame.size, shape).shift(frame.topLeft);
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16 * s
          ..color = color.withValues(alpha: strength * 0.75)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * s),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * s
          ..color = color.withValues(alpha: strength)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * s),
      )
      ..drawOval(
        Rect.fromCenter(
          center: Offset(frame.center.dx, frame.bottom + 5 * s),
          width: frame.width * 1.1,
          height: 18 * s,
        ),
        Paint()
          ..color = color.withValues(alpha: strength * 0.65)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * s),
      );
  }

  @override
  bool shouldRepaint(MirrorArchHaloPainter old) =>
      old.arch != arch ||
      old.color != color ||
      old.strength != strength ||
      old.shape != shape ||
      old.s != s;
}

/// Рама зеркала: контур-дорожка и линия прогресса по нему со светящейся
/// точкой на конце. При [progress] = 1 рама замкнута и точки нет.
/// Рисуется на прямоугольнике стекла, расширенном на [mirrorFrameInset];
/// у двойной рамы ([MirrorArchShape.doubleLine]) линия тоньше, а по кромке
/// стекла идёт вторая, волосяная.
class MirrorArchFramePainter extends CustomPainter {
  const MirrorArchFramePainter({
    required this.progress,
    required this.track,
    required this.color,
    required this.glow,
    required this.s,
    this.shape = MirrorArchShape.arch,
  });

  final double progress;
  final Color track;
  final Color color;
  final double glow;
  final double s;
  final MirrorArchShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final path = mirrorArchPath(size, shape);
    final width = shape.doubleLine ? 2.4 * s : 4 * s;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = track,
    );
    if (shape.doubleLine) {
      final inset = mirrorFrameInset(shape, s);
      final inner = mirrorArchPath(
        Size(size.width - inset * 2, size.height - inset * 2),
        shape,
      ).shift(Offset(inset, inset));
      canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0 * s, 0.9)
          ..color = color.withValues(alpha: 0.6),
      );
    }
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    final metric = path.computeMetrics().first;
    final done = metric.extractPath(0, metric.length * p);
    canvas
      ..drawPath(
        done,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 3
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.18 + 0.12 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * s),
      )
      ..drawPath(
        done,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    final tip = metric.getTangentForOffset(metric.length * p)?.position;
    if (tip != null && p < 1) {
      canvas
        ..drawCircle(
          tip,
          (8 + 6 * glow) * s,
          Paint()..color = color.withValues(alpha: 0.22),
        )
        ..drawCircle(tip, 5 * s, Paint()..color = Colors.white)
        ..drawCircle(tip, 3.2 * s, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(MirrorArchFramePainter old) =>
      old.progress != progress ||
      old.glow != glow ||
      old.color != color ||
      old.track != track ||
      old.shape != shape ||
      old.s != s;
}

/// Фактура бренда под экраном ([MirrorBrand.backdropAsset]) под вуалью
/// цвета фона; без фактуры — ровный фон. Статичный слой.
class MirrorBackdrop extends StatelessWidget {
  const MirrorBackdrop({super.key, this.veil});

  /// Плотность вуали вместо [MirrorBrand.backdropVeil].
  final double? veil;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final asset = t.brand.backdropAsset;
    if (asset == null) return ColoredBox(color: t.bg);
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: t.bg),
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
          ),
          ColoredBox(
            color: t.bg.withValues(alpha: veil ?? t.brand.backdropVeil),
          ),
        ],
      ),
    );
  }
}

/// Карточка, «приколотая» к раме зеркала: светлая плашка с тенью и точкой
/// цвета бренда на внутреннем крае (со стороны зеркала).
class MirrorPinnedCard extends StatelessWidget {
  const MirrorPinnedCard({
    super.key,
    required this.fromLeft,
    required this.child,
    this.maxWidth = double.infinity,
    this.padding,
    this.highlight = false,
  });

  /// Карточка слева от зеркала — точка на правом крае.
  final bool fromLeft;
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  /// Подсветить рамкой и свечением цвета бренда (например, QR после
  /// касания «Скачать фото»).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final pin = 10 * s;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: padding ??
          EdgeInsets.fromLTRB(
            fromLeft ? 14 * s : 20 * s,
            10 * s,
            fromLeft ? 20 * s : 14 * s,
            10 * s,
          ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(math.min(t.rCard, 16 * s)),
        border: Border.all(
          color: highlight ? t.primary : t.hairline,
          width: highlight ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: t.ink.withValues(alpha: 0.10),
            blurRadius: 16 * s,
            spreadRadius: -2 * s,
            offset: Offset(0, 6 * s),
          ),
          if (highlight)
            BoxShadow(
              color: t.primary.withValues(alpha: 0.45),
              blurRadius: 22 * s,
            ),
        ],
      ),
      child: child,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: 0,
          bottom: 0,
          left: fromLeft ? null : -pin / 2,
          right: fromLeft ? -pin / 2 : null,
          child: Center(
            child: Container(
              width: pin,
              height: pin,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.primary,
                border: Border.all(color: Colors.white, width: pin * 0.22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Плашка на нижней кромке рамы (процент, сумма образа): цвет бренда,
/// градиент, если он у бренда есть, и борт цветом фона.
class MirrorArchBadge extends StatelessWidget {
  const MirrorArchBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final gradient = t.brand.palette.primaryGradient;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 7 * s),
      decoration: BoxDecoration(
        color: t.primary,
        gradient: gradient == null ? null : LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(t.roundControls ? 999 : t.rButton),
        border: Border.all(color: t.bg, width: 3 * s),
        boxShadow: [
          BoxShadow(
            color: t.primary.withValues(alpha: 0.25),
            blurRadius: 12 * s,
            spreadRadius: -3 * s,
            offset: Offset(0, 4 * s),
          ),
        ],
      ),
      child: child,
    );
  }
}
