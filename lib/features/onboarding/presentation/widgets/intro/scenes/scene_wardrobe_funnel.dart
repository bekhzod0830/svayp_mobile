import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_garments.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_svgs.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

/// Deck slide 2 ("Создавай образы из своих вещей"): six white garment tiles
/// are continuously "sucked" into the pink wardrobe below — each tile flies
/// along its own diagonal while shrinking and fading on a shared 2.7s loop,
/// and the wardrobe pulses in sympathy every time a tile lands.
class IntroSceneWardrobeFunnel extends StatefulWidget {
  const IntroSceneWardrobeFunnel({super.key, required this.entrance});

  final Animation<double> entrance;

  @override
  State<IntroSceneWardrobeFunnel> createState() =>
      _IntroSceneWardrobeFunnelState();
}

class _IntroSceneWardrobeFunnelState extends State<IntroSceneWardrobeFunnel>
    with SingleTickerProviderStateMixin {
  /// Deck canvas: 392 logical px wide, 57%-stage ≈ 460 tall.
  static const double _canvasW = 392;
  static const double _canvasH = 460;

  /// One shared loop drives every tile (phased) and the wardrobe pulse —
  /// deck: `funnel 2.7s cubic-bezier(.55,0,.5,1) infinite`.
  static const double _cycleSeconds = 2.7;
  static const Curve _funnelCurve = Cubic(0.55, 0, 0.5, 1);

  /// Six tiles filled with real garment photos (5 unique + 1 repeat).
  static const List<_FunnelTile> _tiles = [
    _FunnelTile(
      left: 22,
      top: 34,
      size: 58,
      radius: 16,
      asset: IntroGarments.top,
      dx: 118,
      dy: 250,
      phase: 0.0,
    ),
    _FunnelTile(
      left: 112,
      top: 26,
      size: 58,
      radius: 16,
      asset: IntroGarments.dress,
      dx: 44,
      dy: 262,
      phase: 0.45,
    ),
    _FunnelTile(
      left: 206,
      top: 34,
      size: 58,
      radius: 16,
      asset: IntroGarments.skirt,
      dx: -40,
      dy: 250,
      phase: 0.90,
    ),
    _FunnelTile(
      left: 296,
      top: 28,
      size: 58,
      radius: 16,
      asset: IntroGarments.romol,
      dx: -116,
      dy: 258,
      phase: 1.35,
    ),
    _FunnelTile(
      left: 72,
      top: 104,
      size: 52,
      radius: 15,
      asset: IntroGarments.bag,
      dx: 92,
      dy: 176,
      phase: 0.70,
    ),
    _FunnelTile(
      left: 262,
      top: 104,
      size: 52,
      radius: 15,
      asset: IntroGarments.top,
      dx: -78,
      dy: 178,
      phase: 1.15,
    ),
  ];

  late final AnimationController _cycle;

  @override
  void initState() {
    super.initState();
    _cycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _cycle
        ..stop()
        ..value = 0.0;
    } else if (!_cycle.isAnimating) {
      _cycle.repeat();
    }
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  /// Wardrobe pulse (deck `suck`): scale 1 at 0/64/100%, 1.05 at 72%.
  static double _suckScale(double p) {
    if (p < 0.64) return 1.0;
    if (p < 0.72) {
      return 1.0 + 0.05 * Curves.easeInOut.transform((p - 0.64) / 0.08);
    }
    return 1.05 - 0.05 * Curves.easeInOut.transform((p - 0.72) / 0.28);
  }

  Widget _buildTile(_FunnelTile tile, bool reduced) {
    final box = GarmentTile(
      asset: tile.asset,
      size: tile.size,
      radius: tile.radius,
      shadow: true,
    );
    if (reduced) return box;

    return AnimatedBuilder(
      animation: _cycle,
      child: box,
      builder: (context, child) {
        // Dart's % keeps the result non-negative, so phases wrap for free.
        final p = ((_cycle.value * _cycleSeconds - tile.phase) % _cycleSeconds) /
            _cycleSeconds;
        final e = _funnelCurve.transform(p);
        final double opacity;
        if (p < 0.14) {
          opacity = p / 0.14;
        } else if (p < 0.72) {
          opacity = 1.0;
        } else {
          opacity = 1.0 - (p - 0.72) / 0.28;
        }
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(tile.dx * e, tile.dy * e),
            child: Transform.scale(scale: 1.0 - 0.78 * e, child: child),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _canvasW,
          height: _canvasH,
          child: Stack(
            children: [
              for (final tile in _tiles)
                Positioned(
                  left: tile.left,
                  top: tile.top,
                  child: _buildTile(tile, reduced),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 26,
                child: Center(
                  child: Entrance(
                    parent: widget.entrance,
                    kind: IntroEntranceKind.riseCard,
                    delay: 0.12,
                    child: AnimatedBuilder(
                      animation: _cycle,
                      child: SvgPicture.string(
                        IntroSvgs.wardrobe,
                        width: 156,
                        height: 185,
                      ),
                      builder: (context, child) => Transform.scale(
                        scale: reduced ? 1.0 : _suckScale(_cycle.value),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
              // Deck: top 44% / left 24% and top 40% / right 26%.
              const Positioned(
                left: 94,
                top: 202,
                child: Twinkle(size: 13),
              ),
              const Positioned(
                right: 102,
                top: 184,
                child: Twinkle(
                  color: IntroPalette.amber,
                  size: 12,
                  delaySeconds: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Geometry + loop parameters for one flying garment tile.
class _FunnelTile {
  const _FunnelTile({
    required this.left,
    required this.top,
    required this.size,
    required this.radius,
    required this.asset,
    required this.dx,
    required this.dy,
    required this.phase,
  });

  final double left;
  final double top;
  final double size;
  final double radius;
  final String asset;

  /// Travel target (deck `--dx`/`--dy`) — ends inside the wardrobe.
  final double dx;
  final double dy;

  /// Loop offset in seconds (deck `animation-delay`).
  final double phase;
}
