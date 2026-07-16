import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_diamond.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_garments.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_svgs.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Intro slide 1 stage — "Весь твой гардероб — в телефоне": a floating white
/// closet-preview card (garment grid + coin badge) over a soft pink radial
/// glow, with a dropping gold coin and ambient twinkles (deck slide 1).
class IntroSceneCloset extends StatelessWidget {
  const IntroSceneCloset({
    super.key,
    required this.entrance,
    required this.coins,
  });

  /// The slide's entrance controller; all choreography runs off it.
  final Animation<double> entrance;

  /// Coin balance shown in the card's gold badge.
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 392,
          height: 460,
          child: Stack(
            children: [
              // Soft radial glow behind the card.
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          IntroPalette.pinkLight.withValues(alpha: 0.22),
                          IntroPalette.pinkLight.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.62],
                      ),
                    ),
                  ),
                ),
              ),
              // Centered closet preview card.
              Center(
                child: Entrance(
                  parent: entrance,
                  kind: IntroEntranceKind.riseCard,
                  delay: 0.19,
                  child: Floaty(
                    child: _ClosetCard(coins: coins),
                  ),
                ),
              ),
              // Floating brand diamond, top-right.
              Align(
                alignment: const Alignment(0.74, -0.72),
                child: Entrance(
                  parent: entrance,
                  kind: IntroEntranceKind.coinDrop,
                  delay: 0.33,
                  child: const Floaty(
                    variant: 2,
                    child: IntroDiamond(size: 42, withGleam: true),
                  ),
                ),
              ),
              // Ambient twinkles.
              const Align(
                alignment: Alignment(-0.70, -0.56),
                child: Twinkle(size: 16),
              ),
              const Align(
                alignment: Alignment(0.60, 0.68),
                child: Twinkle(
                  color: IntroPalette.amber,
                  size: 13,
                  delaySeconds: 0.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The white "closet preview" card: header row (title + coin badge) above a
/// 3×2 garment grid with a dashed "add" cell.
class _ClosetCard extends StatelessWidget {
  const _ClosetCard({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 212,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 17),
      decoration: BoxDecoration(
        color: IntroPalette.bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF781446).withValues(alpha: 0.4),
            offset: const Offset(0, 28),
            blurRadius: 50,
            spreadRadius: -18,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.introSlide2Kicker,
                style: IntroPalette.label(size: 15),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(7, 4, 10, 4),
                decoration: const BoxDecoration(
                  color: IntroPalette.gemChipBg,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const IntroDiamond(size: 13),
                    const SizedBox(width: 5),
                    Text(
                      '$coins',
                      style: IntroPalette.label(
                        size: 10,
                        color: IntroPalette.gemText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _GarmentCell(asset: IntroGarments.top),
              SizedBox(width: 8),
              _GarmentCell(asset: IntroGarments.skirt),
              SizedBox(width: 8),
              _GarmentCell(asset: IntroGarments.dress),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _GarmentCell(asset: IntroGarments.romol),
              SizedBox(width: 8),
              _GarmentCell(asset: IntroGarments.bag),
              SizedBox(width: 8),
              _AddCell(),
            ],
          ),
        ],
      ),
    );
  }
}

/// One square garment tile of the grid — a real catalog photo cropped to fill.
class _GarmentCell extends StatelessWidget {
  const _GarmentCell({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: IntroPalette.chipBg,
            borderRadius: BorderRadius.all(Radius.circular(13)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: GarmentImage(asset: asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

/// The dashed-border "add a garment" tile.
class _AddCell extends StatelessWidget {
  const _AddCell();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          foregroundPainter: const _DashedBorderPainter(
            color: Color(0xFFF2A9CC),
            strokeWidth: 1.5,
            radius: 13,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFFCE9F1),
              borderRadius: BorderRadius.all(Radius.circular(13)),
            ),
            child: Center(
              child: SvgPicture.string(
                IntroSvgs.plus(),
                width: 20,
                height: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a dashed rounded-rectangle border (Flutter has no built-in dashed
/// BorderStyle).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  static const double _dashLength = 4;
  static const double _gapLength = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dashLength),
          paint,
        );
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
