import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_diamond.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Stage scene for intro slide 7 ("Дарим N алмазов"): a hero brand diamond on a
/// soft gem sunburst, with a few accent diamonds arcing in and ambient
/// sparkles. The gift amount lives in the headline below, so the stage stays
/// clean. The confetti burst is fired from the carousel screen.
class IntroSceneGift extends StatelessWidget {
  const IntroSceneGift({super.key, required this.entrance, required this.coins});

  final Animation<double> entrance;
  final int coins;

  Widget _diamond({
    required Alignment alignment,
    required double size,
    required double delay,
    required int floatyVariant,
  }) {
    return Align(
      alignment: alignment,
      child: Entrance(
        parent: entrance,
        kind: IntroEntranceKind.coinDrop,
        delay: delay,
        child: Floaty(variant: floatyVariant, child: IntroDiamond(size: size)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Soft gem radial glow.
        Align(
          alignment: const Alignment(0, -0.05),
          child: IgnorePointer(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      IntroPalette.gem.withValues(alpha: 0.26),
                      IntroPalette.gem.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.65],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Sunburst + hero diamond, scaling in together.
        Center(
          child: Entrance(
            parent: entrance,
            kind: IntroEntranceKind.pop,
            delay: 0.12,
            child: SizedBox(
              width: 240,
              height: 240,
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  _Sunburst(),
                  Floaty(child: IntroDiamond(size: 108, withGleam: true)),
                ],
              ),
            ),
          ),
        ),
        // Accent diamonds arcing in.
        _diamond(
          alignment: const Alignment(-0.72, -0.5),
          size: 34,
          delay: 0.19,
          floatyVariant: 2,
        ),
        _diamond(
          alignment: const Alignment(0.74, -0.42),
          size: 40,
          delay: 0.33,
          floatyVariant: 1,
        ),
        _diamond(
          alignment: const Alignment(0.66, 0.55),
          size: 28,
          delay: 0.26,
          floatyVariant: 3,
        ),
        _diamond(
          alignment: const Alignment(-0.68, 0.5),
          size: 24,
          delay: 0.4,
          floatyVariant: 2,
        ),
        // Sparkles.
        const Align(
          alignment: Alignment(-0.3, -0.62),
          child: Twinkle(color: IntroPalette.gem, size: 16),
        ),
        const Align(
          alignment: Alignment(0.36, 0.5),
          child: Twinkle(color: IntroPalette.pink, size: 12, delaySeconds: 0.4),
        ),
      ],
    );
  }
}

/// A soft gem ray burst behind the gift diamond.
class _Sunburst extends StatelessWidget {
  const _Sunburst();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(painter: _SunburstPainter()),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  const _SunburstPainter();

  static const int _rays = 14;
  static const double _innerRadius = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final paint = Paint()
      ..color = IntroPalette.gem.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    const half = math.pi / _rays * 0.42; // ray half-angle (tapered)
    for (var i = 0; i < _rays; i++) {
      final a = (i / _rays) * 2 * math.pi;
      final tip = center + Offset(math.cos(a), math.sin(a)) * outer;
      final b1 =
          center + Offset(math.cos(a - half), math.sin(a - half)) * _innerRadius;
      final b2 =
          center + Offset(math.cos(a + half), math.sin(a + half)) * _innerRadius;
      canvas.drawPath(
        Path()
          ..moveTo(b1.dx, b1.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(b2.dx, b2.dy)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter oldDelegate) => false;
}

/// Balance chip under the slide-7 text block: a gem pill with a small
/// diamond and "N алмазов уже на балансе".
class IntroGiftChip extends StatelessWidget {
  const IntroGiftChip({super.key, required this.entrance, required this.coins});

  final Animation<double> entrance;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.topCenter,
      child: Entrance(
        parent: entrance,
        kind: IntroEntranceKind.rise,
        delay: 0.26,
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 9, 16, 9),
          decoration: BoxDecoration(
            color: IntroPalette.gemChipBg,
            border: Border.all(color: IntroPalette.gemChipBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IntroDiamond(size: 18),
              const SizedBox(width: 9),
              Text(
                l10n.introSlide7Chip(coins),
                style: const TextStyle(
                  fontFamily: IntroPalette.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: IntroPalette.gemText,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
