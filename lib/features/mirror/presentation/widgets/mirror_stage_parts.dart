import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';

import '../mirror_theme.dart';

/// Общие детали «примерочной»: стена бутика с линиями корта, арочное зеркало,
/// бейдж AI и раскладка фигуры в зеркале. Ими собраны сцена постера и сцена
/// генерации — чтобы путь покупателя начинался и заканчивался у одного зеркала.

/// Зелёная стена бутика: градиент бренда и разметка теннисного корта тонкими
/// линиями — наследие бренда вместо орнамента.
class MirrorStageWall extends StatelessWidget {
  const MirrorStageWall({
    super.key,
    required this.borderRadius,
    required this.child,
  });

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.primary, t.primaryDeep],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: MirrorCourtLinesPainter(
                color: t.onPrimary.withValues(alpha: 0.075),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Разметка корта: внешний контур, одиночные коридоры, сетка и линии подачи.
class MirrorCourtLinesPainter extends CustomPainter {
  const MirrorCourtLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.004)
      ..color = color;

    final court = Rect.fromLTRB(
      size.width * 0.07,
      size.height * 0.06,
      size.width * 0.93,
      size.height * 1.06, // дальняя половина уходит за нижний край
    );
    canvas.drawRect(court, paint);

    final alley = court.width * 0.125;
    canvas
      ..drawLine(
        Offset(court.left + alley, court.top),
        Offset(court.left + alley, court.bottom),
        paint,
      )
      ..drawLine(
        Offset(court.right - alley, court.top),
        Offset(court.right - alley, court.bottom),
        paint,
      );

    final net = court.top + court.height * 0.5;
    final service = court.top + court.height * 0.23;
    canvas
      ..drawLine(Offset(court.left, net), Offset(court.right, net), paint)
      ..drawLine(
        Offset(court.left + alley, service),
        Offset(court.right - alley, service),
        paint,
      )
      ..drawLine(
        Offset(court.center.dx, service),
        Offset(court.center.dx, net),
        paint,
      );
  }

  @override
  bool shouldRepaint(MirrorCourtLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Арочное зеркало: глиняная рама, светлое стекло, бегущий блик.
/// [head] — что стоит на месте головы отражения (по умолчанию нейтральный
/// намёк; сцена генерации ставит сюда фото покупателя). [glow] (0..1)
/// подсвечивает раму — «зеркало работает».
class MirrorArch extends StatelessWidget {
  const MirrorArch({super.key, this.head, this.glow = 0});

  final Widget? head;
  final double glow;

  /// Размер зеркала на артборде сцены.
  static const Size size = Size(170, 408);

  static const BorderRadius _arch = BorderRadius.vertical(
    top: Radius.circular(85),
    bottom: Radius.circular(8),
  );
  static const BorderRadius _glass = BorderRadius.vertical(
    top: Radius.circular(81),
    bottom: Radius.circular(5),
  );

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.accent,
        borderRadius: _arch,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 44,
            spreadRadius: -14,
            offset: const Offset(0, 26),
          ),
          if (glow > 0)
            BoxShadow(
              color: t.accent.withValues(alpha: 0.55 * glow),
              blurRadius: 34 * glow,
              spreadRadius: 2 * glow,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: _glass,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, t.surface, t.bg],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: head ?? const _HeadHint(),
                ),
              ),
              const Gleam(
                durationMs: 4200,
                travelFraction: 0.5,
                widthFraction: 0.5,
                opacity: 0.7,
                initialDelayMs: 1400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Намёк на голову и шею: вместе с плитками вещей отражение читается как
/// человек.
class _HeadHint extends StatelessWidget {
  const _HeadHint();

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final color = t.primary.withValues(alpha: 0.14);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          Container(width: 12, height: 8, color: color),
        ],
      ),
    );
  }
}

/// Бейдж «AI ✦».
class MirrorAiBadge extends StatelessWidget {
  const MirrorAiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AI',
            style: t.label(12, weight: FontWeight.w800, color: t.primary),
          ),
          const SizedBox(width: 5),
          Text('✦', style: TextStyle(color: t.accent, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Раскладка фигуры в зеркале (координаты артборда): верх шире, низ уже,
/// обувь — узкой полосой у пола; цельная вещь занимает место верха и низа.
/// Верх начинается ниже свода арки, чтобы углы плитки не вылезали за стекло.
class MirrorFigureLayout {
  MirrorFigureLayout._();

  static const double mirrorTop = 30;
  static const double bodyTop = 80;
  static const double bodyBottom = 418;
  static const double gap = 6;
  static const double shoesHeight = 60;
  static const double topWidth = 140;
  static const double bottomWidth = 124;
  static const double shoesWidth = 104;

  static Rect mirrorRect(double centerX) => Rect.fromLTWH(
        centerX - MirrorArch.size.width / 2,
        mirrorTop,
        MirrorArch.size.width,
        MirrorArch.size.height,
      );

  /// Слоты тела ([bodyCount] = 1 — цельная вещь, 2 — верх и низ) и, если
  /// [hasShoes], обувь последним элементом.
  static List<Rect> slots({
    required double centerX,
    required int bodyCount,
    required bool hasShoes,
    double bodyTop = MirrorFigureLayout.bodyTop,
  }) {
    final bottom = bodyBottom - (hasShoes ? shoesHeight + gap : 0);
    final height = bottom - bodyTop;

    Rect centered(double top, double width, double h) =>
        Rect.fromLTWH(centerX - width / 2, top, width, h);

    final result = <Rect>[];
    if (bodyCount <= 1) {
      result.add(centered(bodyTop, topWidth - 4, height));
    } else {
      final half = (height - gap) / 2;
      result
        ..add(centered(bodyTop, topWidth, half))
        ..add(centered(bodyTop + half + gap, bottomWidth, half));
    }
    if (hasShoes) {
      result.add(centered(bodyBottom - shoesHeight, shoesWidth, shoesHeight));
    }
    return result;
  }
}
