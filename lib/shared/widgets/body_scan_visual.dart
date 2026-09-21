import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Reusable body-scan visual: the dotted-body silhouette illustration floating
/// on a clean white (or dark) stage, with anchored glowing rings, a soft
/// travelling scan and sparkles, plus a [badge] pill (the diamond cost in the
/// try-on sheet, or "AI" while processing). Extracted from the try-on sheet so
/// the Magic Mirror kiosk can share the same scan effect.
class BodyScanVisual extends StatefulWidget {
  final Widget badge;
  const BodyScanVisual({super.key, required this.badge});

  @override
  State<BodyScanVisual> createState() => _BodyScanVisualState();
}

class _BodyScanVisualState extends State<BodyScanVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Barely-there pink aura behind the figure; the edges stay transparent
        // so the stage reads as the sheet's own clean white (or dark) surface.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.15),
              radius: 0.9,
              colors: [
                const Color(0xFFF370A7).withValues(alpha: isDark ? 0.10 : 0.06),
                const Color(0xFFF370A7).withValues(alpha: 0),
              ],
            ),
          ),
        ),
        // The figure breathes very slightly so the stage feels alive even
        // between scan passes.
        AnimatedBuilder(
          animation: _anim,
          builder: (context, child) => Transform.scale(
            scale: 1 + 0.012 * math.sin(_anim.value * 2 * math.pi),
            child: child,
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Image(
              image: AssetImage('assets/images/tryon_silhouette.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _anim,
          builder: (context, _) =>
              CustomPaint(painter: ScanGlowPainter(_anim.value, isDark)),
        ),
        Positioned(top: 12, right: 12, child: widget.badge),
      ],
    );
  }
}

/// Body-scan glow: three rings anchored at bust / hips / shins that softly
/// pulse, a faint scan ring gliding down and back up the figure (igniting each
/// anchored ring as it passes), and slow sparkles around the body. All motion
/// is sine-eased so the loop has no visible seam or snap-back.
class ScanGlowPainter extends CustomPainter {
  final double t; // 0..1 loop phase
  final bool isDark;
  ScanGlowPainter(this.t, this.isDark);

  static const _pink = Color(0xFFF370A7);

  // Ring anchors as a fraction of the figure's height, and each ring's width
  // as a multiple of the figure's width (wider toward the ground, like the
  // reference's perspective).
  static const _ringAnchors = [0.30, 0.55, 0.80];
  static const _ringWidths = [2.0, 2.5, 3.0];
  // Sparkle field: x, y as stage fractions + twinkle phase offset.
  static const _sparks = [
    [0.26, 0.14, 0.00], [0.72, 0.10, 0.45], [0.16, 0.36, 0.20],
    [0.82, 0.32, 0.65], [0.28, 0.56, 0.85], [0.78, 0.55, 0.10],
    [0.22, 0.78, 0.55], [0.72, 0.80, 0.30], [0.50, 0.05, 0.75],
    [0.64, 0.68, 0.90], [0.34, 0.28, 0.50], [0.60, 0.44, 0.15],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // The illustration sits in 14px vertical padding with a 453x1357 aspect.
    const figTop = 14.0;
    final figH = size.height - 28.0;
    final figW = figH * (453 / 1357);

    // Ping-pong sweep (0 -> 1 -> 0 over one loop): cosine velocity reaches
    // zero at both turnarounds, so the scan glides instead of snapping back.
    final sweep = 0.5 - 0.5 * math.cos(2 * math.pi * t);
    final sweepY = figTop + figH * (0.08 + 0.84 * sweep);

    double ringW(double anchor) {
      final a = ((anchor - _ringAnchors.first) /
              (_ringAnchors.last - _ringAnchors.first))
          .clamp(0.0, 1.0);
      final w = figW *
          (_ringWidths.first + (_ringWidths.last - _ringWidths.first) * a);
      return math.min(w, size.width * 0.92);
    }

    void drawRing(double cy, double w, double alpha) {
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, cy),
        width: w,
        height: w * 0.20,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = _pink.withValues(alpha: 0.22 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _pink.withValues(alpha: 0.60 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: 0.9 * alpha),
      );
    }

    // Faint travelling scan ring.
    drawRing(sweepY, ringW((sweepY - figTop) / figH), 0.30);

    // Anchored rings: gentle ambient pulse + a bright flare as the scan
    // passes through them.
    for (var i = 0; i < _ringAnchors.length; i++) {
      final cy = figTop + figH * _ringAnchors[i];
      final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * (2 * t + i / 3));
      final d = (sweepY - cy) / figH;
      final flare = math.exp(-(d * d) / 0.006);
      final alpha = (0.30 + 0.22 * pulse + 0.48 * flare).clamp(0.0, 1.0);
      drawRing(cy, ringW(_ringAnchors[i]) * (1 + 0.03 * flare), alpha);
    }

    // Slow sparkles, each twinkling once per loop on its own phase.
    final sparkCore = isDark ? Colors.white : _pink;
    for (var i = 0; i < _sparks.length; i++) {
      final s = _sparks[i];
      final tw = math.sin(2 * math.pi * (t + s[2]));
      if (tw <= 0) continue;
      final a = tw * tw * tw * tw;
      final c = Offset(size.width * s[0], size.height * s[1]);
      final r = 1.4 + (i % 3) * 0.6;
      canvas.drawCircle(
        c,
        r * 2.6,
        Paint()
          ..color = _pink.withValues(alpha: 0.30 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
          c, r, Paint()..color = sparkCore.withValues(alpha: 0.9 * a));
      final arm = r * 3.2 * a;
      final p = Paint()
        ..strokeWidth = 1
        ..color = sparkCore.withValues(alpha: 0.7 * a);
      canvas.drawLine(c - Offset(arm, 0), c + Offset(arm, 0), p);
      canvas.drawLine(c - Offset(0, arm), c + Offset(0, arm), p);
    }
  }

  @override
  bool shouldRepaint(ScanGlowPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.isDark != isDark;
}
