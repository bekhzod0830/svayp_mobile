import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../mirror_theme.dart';

/// Контур арочного зеркала: полукруглый верх, прямые стенки, мягкие нижние
/// углы. Путь начинается в левом нижнем углу и идёт вверх, через верх, вниз
/// по правой стенке и по низу обратно — поэтому его удобно «дорисовывать»
/// по прогрессу (экран генерации).
Path mirrorArchPath(Size size) {
  final w = size.width;
  final h = size.height;
  final r = w / 2;
  final rb = w * 0.07;
  return Path()
    ..moveTo(0, h - rb)
    ..lineTo(0, r)
    ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
    ..lineTo(w, h - rb)
    ..arcToPoint(Offset(w - rb, h), radius: Radius.circular(rb))
    ..lineTo(rb, h)
    ..arcToPoint(Offset(0, h - rb), radius: Radius.circular(rb))
    ..close();
}

/// Обрезка по арке [mirrorArchPath].
class MirrorArchClipper extends CustomClipper<Path> {
  const MirrorArchClipper();

  @override
  Path getClip(Size size) => mirrorArchPath(size);

  @override
  bool shouldReclip(MirrorArchClipper oldClipper) => false;
}

/// Мягкое свечение цветом бренда за арочным зеркалом.
class MirrorArchHaloPainter extends CustomPainter {
  const MirrorArchHaloPainter(
      {required this.arch, required this.color, required this.strength});

  final Rect arch;
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
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

  @override
  bool shouldRepaint(MirrorArchHaloPainter old) =>
      old.arch != arch || old.color != color || old.strength != strength;
}

/// Рама зеркала: контур-дорожка и линия прогресса по нему со светящейся
/// точкой на конце. При [progress] = 1 рама замкнута и точки нет.
class MirrorArchFramePainter extends CustomPainter {
  const MirrorArchFramePainter({
    required this.progress,
    required this.track,
    required this.color,
    required this.glow,
    required this.s,
  });

  final double progress;
  final Color track;
  final Color color;
  final double glow;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final path = mirrorArchPath(size);
    final width = 4 * s;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = track,
    );
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
      old.s != s;
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
