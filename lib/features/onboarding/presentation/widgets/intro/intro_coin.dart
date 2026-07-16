import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_svgs.dart';

/// The LIBAS gold coin from the design deck: radial-gold disc with an "L"
/// glyph, drop shadow, an inner-shadow approximation and an optional
/// travelling gleam highlight.
class IntroCoin extends StatelessWidget {
  const IntroCoin({
    super.key,
    required this.size,
    this.withGleam = false,
    this.withRing,
  });

  final double size;

  /// Adds the sweeping light bar (deck: only the hero coins have it).
  final bool withGleam;

  /// Draw the inner ring. Defaults to the deck behavior: rings on coins
  /// ≥ 40px, none on the tiny inline ones.
  final bool? withRing;

  @override
  Widget build(BuildContext context) {
    final ring = withRing ?? size >= 40;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0A337).withValues(alpha: 0.45),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.15),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.string(IntroSvgs.coin(withRing: ring)),
            // Inset-shadow approximation: white top highlight, dark bottom rim.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.30),
                    Colors.white.withValues(alpha: 0),
                    const Color(0xFF7A4A0A).withValues(alpha: 0),
                    const Color(0xFF7A4A0A).withValues(alpha: 0.22),
                  ],
                  stops: const [0.0, 0.28, 0.72, 1.0],
                ),
              ),
            ),
            if (withGleam) const Positioned.fill(child: Gleam()),
          ],
        ),
      ),
    );
  }
}
