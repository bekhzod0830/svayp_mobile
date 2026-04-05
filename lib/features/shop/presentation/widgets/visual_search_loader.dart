import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Compact AI visual search loader dialog.
//
// Shows a themed dialog with:
//  • Cropped image + sweeping scan beam + corner brackets.
//  • Phase-cycling status text (translated).
// ─────────────────────────────────────────────────────────────────────────────
class VisualSearchLoader extends StatefulWidget {
  final File image;

  const VisualSearchLoader({super.key, required this.image});

  @override
  State<VisualSearchLoader> createState() => _VisualSearchLoaderState();
}

class _VisualSearchLoaderState extends State<VisualSearchLoader>
    with TickerProviderStateMixin {
  late final AnimationController _beamCtrl;
  late final Animation<double> _beamAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  late final AnimationController _dotCtrl;
  late final Animation<int> _dotAnim;

  int _phaseIndex = 0;
  Timer? _phaseTimer;

  @override
  void initState() {
    super.initState();

    _beamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _beamAnim = CurvedAnimation(parent: _beamCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotAnim = StepTween(begin: 0, end: 4).animate(_dotCtrl);

    _phaseTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) setState(() => _phaseIndex = (_phaseIndex + 1) % 4);
    });
  }

  @override
  void dispose() {
    _beamCtrl.dispose();
    _pulseCtrl.dispose();
    _dotCtrl.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final phases = [
      l10n.vsScanningImage,
      l10n.vsIdentifyingStyle,
      l10n.vsFindingMatches,
      l10n.vsAlmostThere,
    ];

    final textColor = isDark
        ? AppColors.darkPrimaryText
        : AppColors.primaryText;
    final subtleColor = isDark
        ? AppColors.darkSecondaryText
        : AppColors.secondaryText;
    final dotActiveColor = isDark
        ? AppColors.darkPrimaryText
        : AppColors.brandBlack;
    final dotInactiveColor = isDark
        ? AppColors.darkStandardBorder
        : AppColors.gray300;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xF2050508)
                    : const Color(0xF2FFFFFF),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? const Color(0x22FFFFFF)
                      : const Color(0x28000000),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0x44000000)
                        : const Color(0x18000000),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Image + scan animation ─────────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) =>
                        Transform.scale(scale: _pulseAnim.value, child: child),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(widget.image, fit: BoxFit.contain),
                            Container(color: Colors.black.withOpacity(0.18)),
                            AnimatedBuilder(
                              animation: _beamAnim,
                              builder: (_, __) => CustomPaint(
                                painter: _ScanBeamPainter(_beamAnim.value),
                              ),
                            ),
                            CustomPaint(painter: _CornerBracketsPainter()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Phase text ─────────────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      phases[_phaseIndex],
                      key: ValueKey(_phaseIndex),
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Animated dots ──────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _dotAnim,
                    builder: (_, __) {
                      final count = _dotAnim.value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final active = i < count;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 7 : 5,
                            height: active ? 7 : 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? dotActiveColor : dotInactiveColor,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // ── "Powered by AI" ────────────────────────────────────────────
                  Text(
                    l10n.vsPoweredByAI,
                    style: AppTypography.caption.copyWith(
                      color: subtleColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sweeping scan beam
// ─────────────────────────────────────────────────────────────────────────────
class _ScanBeamPainter extends CustomPainter {
  final double progress;
  const _ScanBeamPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    final glowHeight = size.height * 0.18;
    final glowRect = Rect.fromLTWH(0, y - glowHeight, size.width, glowHeight);
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.18)],
      ).createShader(glowRect);
    canvas.drawRect(glowRect, glowPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
  }

  @override
  bool shouldRepaint(_ScanBeamPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Rounded corner brackets
// ─────────────────────────────────────────────────────────────────────────────
class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 28.0;
    const cr = 14.0;
    const strokeW = 3.0;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final corners = [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomRight, -1.0, -1.0),
      (rect.bottomLeft, 1.0, -1.0),
    ];

    for (final (origin, sx, sy) in corners) {
      final path = Path()
        ..moveTo(origin.dx + sx * arm, origin.dy)
        ..lineTo(origin.dx + sx * cr, origin.dy)
        ..arcToPoint(
          Offset(origin.dx, origin.dy + sy * cr),
          radius: const Radius.circular(cr),
          clockwise: sx * sy < 0,
        )
        ..lineTo(origin.dx, origin.dy + sy * arm);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter _) => false;
}
