import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

/// The LIBAS brand-gem diamond — the in-app currency. A faceted brilliant
/// cut drawn with [CustomPaint], with a soft gem glow and an optional
/// sweeping gleam. Drop-in replacement for the old gold coin.
class IntroDiamond extends StatelessWidget {
  const IntroDiamond({super.key, required this.size, this.withGleam = false});

  final double size;

  /// Adds the sweeping light bar (hero diamonds only).
  final bool withGleam;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: IntroPalette.gem.withValues(alpha: 0.45),
              blurRadius: size * 0.38,
              offset: Offset(0, size * 0.16),
            ),
          ],
        ),
        child: ClipPath(
          clipper: _DiamondClipper(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(size: Size.square(size), painter: _DiamondPainter()),
              if (withGleam) const Positioned.fill(child: Gleam()),
            ],
          ),
        ),
      ),
    );
  }
}

// Diamond outline in a unit square (y grows downward): a flat top table, angled
// crown shoulders, then a tapering pavilion to a bottom point.
const double _tableL = 0.30;
const double _tableR = 0.70;
const double _girdleY = 0.34;
const double _crownL = 0.40; // where the table meets the girdle, left
const double _crownR = 0.60;

Path _diamondOutline(Size s) {
  final w = s.width, h = s.height;
  return Path()
    ..moveTo(_tableL * w, 0)
    ..lineTo(_tableR * w, 0)
    ..lineTo(w, _girdleY * h)
    ..lineTo(0.5 * w, h)
    ..lineTo(0, _girdleY * h)
    ..close();
}

class _DiamondClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _diamondOutline(size);

  @override
  bool shouldReclip(_DiamondClipper oldClipper) => false;
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final gy = _girdleY * h;

    void facet(List<Offset> pts, Color color) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    // Base fill (deep) so any seams read as a dark pavilion.
    facet(
      [Offset(_tableL * w, 0), Offset(_tableR * w, 0), Offset(w, gy),
       Offset(0.5 * w, h), Offset(0, gy)],
      IntroPalette.gemDeep,
    );

    // Crown facets (upper third).
    facet([Offset(_tableL * w, 0), Offset(_crownL * w, gy), Offset(0, gy)],
        const Color(0xFFF79BC2));
    facet([Offset(_tableR * w, 0), Offset(w, gy), Offset(_crownR * w, gy)],
        const Color(0xFFF285B4));
    // Table (top) — lightest.
    facet([
      Offset(_tableL * w, 0), Offset(_tableR * w, 0),
      Offset(_crownR * w, gy), Offset(_crownL * w, gy),
    ], const Color(0xFFFCC3DC));

    // Pavilion facets (lower two thirds).
    facet([Offset(0, gy), Offset(_crownL * w, gy), Offset(0.5 * w, h)],
        const Color(0xFFDD6EA0));
    facet([Offset(_crownL * w, gy), Offset(_crownR * w, gy), Offset(0.5 * w, h)],
        IntroPalette.gem);
    facet([Offset(_crownR * w, gy), Offset(w, gy), Offset(0.5 * w, h)],
        IntroPalette.gemDeep);

    // Girdle highlight + a sparkle on the table's top-left.
    canvas.drawLine(
      Offset(0, gy),
      Offset(w, gy),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = w * 0.012,
    );
    canvas.drawCircle(
      Offset(_tableL * w + w * 0.10, h * 0.10),
      w * 0.05,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_DiamondPainter oldDelegate) => false;
}
