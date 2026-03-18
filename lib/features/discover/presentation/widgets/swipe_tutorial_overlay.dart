// ignore_for_file: unused_element
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';

const String _kTutorialSeenKey = 'has_seen_swipe_tutorial';

Future<bool> shouldShowSwipeTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kTutorialSeenKey) ?? false);
}

Future<void> markSwipeTutorialSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kTutorialSeenKey, true);
}

enum _Gesture { right, left, up, tap }

const _kImages = [
  'lib/img/onboarding/product-to-model-1772382538543.png',
  'lib/img/onboarding/product-to-model-1772293596144.png',
  'lib/img/onboarding/fashn-export-1772902229261.png',
  'lib/img/onboarding/IMG_20260315_174737_977.jpg',
];

typedef _L10nString = String Function(AppLocalizations);

class _StepData {
  final _Gesture gesture;
  final Color stampColor;
  final Color stampBorder;
  final IconData stampIcon;
  final String stampLabel;
  final _L10nString title;
  final _L10nString description;
  final _L10nString productName;

  const _StepData({
    required this.gesture,
    required this.stampColor,
    required this.stampBorder,
    required this.stampIcon,
    required this.stampLabel,
    required this.title,
    required this.description,
    required this.productName,
  });
}

final _steps = [
  _StepData(
    gesture: _Gesture.right,
    stampColor: const Color(0xFF2ECC71),
    stampBorder: const Color(0xFF27AE60),
    stampIcon: Icons.favorite_rounded,
    stampLabel: 'LIKE',
    title: (l) => l.swipeRightToLike,
    description: (l) => l.swipeRightDescription,
    productName: (l) => l.tutorialWhiteBlouse,
  ),
  _StepData(
    gesture: _Gesture.left,
    stampColor: const Color(0xFFE74C3C),
    stampBorder: const Color(0xFFC0392B),
    stampIcon: Icons.close_rounded,
    stampLabel: 'PASS',
    title: (l) => l.swipeLeftToPass,
    description: (l) => l.swipeLeftDescription,
    productName: (l) => l.tutorialLongDress,
  ),
  _StepData(
    gesture: _Gesture.up,
    stampColor: const Color(0xFF3498DB),
    stampBorder: const Color(0xFF2980B9),
    stampIcon: Icons.shopping_bag_rounded,
    stampLabel: 'CART',
    title: (l) => l.swipeUpToAddToCart,
    description: (l) => l.swipeUpDescription,
    productName: (l) => l.tutorialBeigeShoes,
  ),
  _StepData(
    gesture: _Gesture.tap,
    stampColor: const Color(0xFF000000),
    stampBorder: const Color(0xFF333333),
    stampIcon: Icons.camera_alt_rounded,
    stampLabel: 'SEARCH',
    title: (l) => l.visualSearch,
    description: (l) => l.vsTutorialDesc,
    productName: (l) => l.visualSearch,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class SwipeTutorialOverlay extends StatefulWidget {
  const SwipeTutorialOverlay({super.key, required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  State<SwipeTutorialOverlay> createState() => _SwipeTutorialOverlayState();
}

class _SwipeTutorialOverlayState extends State<SwipeTutorialOverlay>
    with TickerProviderStateMixin {
  int _stepIndex = 0;
  // 0 = rest/arrow  1 = flying out  2 = reveal
  int _phase = 0;

  late AnimationController _cardCtrl;
  late AnimationController _cardRevealCtrl;
  late AnimationController _arrowCtrl;
  late AnimationController _fadeCtrl;

  late Animation<Offset> _cardOffset;
  late Animation<double> _cardRotation;
  late Animation<double> _stampOpacity;
  late Animation<double> _arrowScale;
  late Animation<double> _fadeAnim;
  late Animation<double> _cardReveal;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    _cardCtrl = AnimationController(vsync: this);

    _cardRevealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardReveal = CurvedAnimation(
      parent: _cardRevealCtrl,
      curve: Curves.easeOut,
    );

    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _arrowScale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut));

    _cardOffset = const AlwaysStoppedAnimation(Offset.zero);
    _cardRotation = const AlwaysStoppedAnimation(0.0);
    _stampOpacity = const AlwaysStoppedAnimation(0.0);

    _startRestPhase();
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _cardRevealCtrl.dispose();
    _arrowCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Animation phases ──────────────────────────────────────────────────────

  void _startRestPhase() {
    if (!mounted) return;
    _cardCtrl.stop();
    _cardCtrl.value = 0;
    _cardOffset = const AlwaysStoppedAnimation(Offset.zero);
    _cardRotation = const AlwaysStoppedAnimation(0.0);
    _stampOpacity = const AlwaysStoppedAnimation(0.0);
    // Reveal card fully for the rest phase (no fade-in here, already visible)
    _cardRevealCtrl.value = 1.0;
    setState(() => _phase = 0);

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted || _phase != 0) return;
      _startFlyPhase();
    });
  }

  void _startFlyPhase() {
    if (!mounted) return;

    final gesture = _steps[_stepIndex].gesture;

    // Visual-search step: no card fly — just loop the rest/scan phase.
    if (gesture == _Gesture.tap) {
      _startRestPhase();
      return;
    }

    setState(() => _phase = 1);
    final dx = gesture == _Gesture.right
        ? 1.6
        : gesture == _Gesture.left
        ? -1.6
        : 0.0;
    final dy = gesture == _Gesture.up ? -2.0 : 0.0;
    final rot = gesture == _Gesture.right
        ? 0.3
        : gesture == _Gesture.left
        ? -0.3
        : 0.0;

    _cardCtrl.duration = const Duration(milliseconds: 1000);
    _cardOffset = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(dx, dy),
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeInOut));
    _cardRotation = Tween<double>(
      begin: 0,
      end: rot,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeInOut));
    _stampOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardCtrl,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _cardCtrl.forward(from: 0).then((_) {
      if (!mounted) return;
      _startRevealPhase();
    });
  }

  // After fly-out: instantly reset position (card is off-screen so no visual
  // jump), then fade it back in smoothly.
  void _startRevealPhase() {
    if (!mounted) return;
    // Reset card to center instantly (it's already off-screen, so invisible).
    _cardCtrl.stop();
    _cardCtrl.value = 0;
    _cardOffset = const AlwaysStoppedAnimation(Offset.zero);
    _cardRotation = const AlwaysStoppedAnimation(0.0);
    _stampOpacity = const AlwaysStoppedAnimation(0.0);
    setState(() => _phase = 2);

    // Fade the card back in smoothly.
    _cardRevealCtrl.forward(from: 0).then((_) {
      if (!mounted) return;
      _startRestPhase();
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _goToStep(int index) {
    if (!mounted) return;
    _cardCtrl.stop();
    _cardRevealCtrl.stop();
    _arrowCtrl.stop();
    _arrowCtrl.reset();
    setState(() {
      _stepIndex = index;
      _phase = 0;
    });
    _arrowCtrl.repeat(reverse: true);
    _startRestPhase();
  }

  Future<void> _finish() async {
    await markSwipeTutorialSeen();
    _fadeCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = _steps[_stepIndex];
    final isLast = _stepIndex == _steps.length - 1;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black87,
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StepDots(count: _steps.length, current: _stepIndex),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        l10n.skip,
                        style: AppTypography.body1.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Animated card ─────────────────────────────────────────────
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _cardCtrl,
                      _cardRevealCtrl,
                      _arrowCtrl,
                    ]),
                    builder: (context, _) {
                      // During the reveal phase, card fades in from 0→1.
                      // During fly-out, card is fully opaque (1.0).
                      // During rest, card is fully opaque (1.0).
                      final cardOpacity = _phase == 2 ? _cardReveal.value : 1.0;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Card — visual search step uses its own widget
                          if (step.gesture == _Gesture.tap)
                            Opacity(
                              opacity: cardOpacity,
                              child: _VisualSearchAnimCard(
                                imagePath: _kImages[_stepIndex],
                              ),
                            )
                          else
                            Opacity(
                              opacity: cardOpacity,
                              child: FractionalTranslation(
                                translation: _cardOffset.value,
                                child: Transform.rotate(
                                  angle: _cardRotation.value,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _MockProductCard(
                                        imagePath: _kImages[_stepIndex],
                                        productName: step.productName(l10n),
                                      ),
                                      // Stamp
                                      if (_phase == 1)
                                        Opacity(
                                          opacity: _stampOpacity.value,
                                          child: _StampBadge(
                                            color: step.stampColor,
                                            border: step.stampBorder,
                                            icon: step.stampIcon,
                                            label: step.stampLabel,
                                            gesture: step.gesture,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Tap hint for visual-search step only
                          if (_phase == 0 && step.gesture == _Gesture.tap)
                            _TapHint(scale: _arrowScale.value),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Text + button ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
                    Text(
                      step.title(l10n),
                      textAlign: TextAlign.center,
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description(l10n),
                      textAlign: TextAlign.center,
                      style: AppTypography.body1.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLast
                            ? _finish
                            : () => _goToStep(_stepIndex + 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.brandBlack
                              : AppColors.brandWhite,
                          foregroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.brandWhite
                              : AppColors.brandBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isLast ? l10n.startShopping : l10n.next,
                          style: AppTypography.button.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step dots
// ─────────────────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock product card  (matches Discover screen style)
// ─────────────────────────────────────────────────────────────────────────────

class _MockProductCard extends StatelessWidget {
  const _MockProductCard({required this.imagePath, required this.productName});
  final String imagePath;
  final String productName;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.72;
    final cardHeight = size.height * 0.50;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Image section
            Expanded(
              flex: 7,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            // Info section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fashion Brand',
                        style: AppTypography.caption.copyWith(
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$49.99',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stamp badge
// ─────────────────────────────────────────────────────────────────────────────

class _StampBadge extends StatelessWidget {
  const _StampBadge({
    required this.color,
    required this.border,
    required this.icon,
    required this.label,
    required this.gesture,
  });
  final Color color;
  final Color border;
  final IconData icon;
  final String label;
  final _Gesture gesture;

  @override
  Widget build(BuildContext context) {
    final angle = gesture == _Gesture.right
        ? -0.3
        : gesture == _Gesture.left
        ? 0.3
        : 0.0;
    final align = gesture == _Gesture.right
        ? Alignment.topLeft
        : gesture == _Gesture.left
        ? Alignment.topRight
        : Alignment.topCenter;

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 3),
              borderRadius: BorderRadius.circular(8),
              color: color.withOpacity(0.15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visual-search animated card (step 4)
// Mimics the VisualSearchLoader: scan beam + corner brackets + animated dots
// ─────────────────────────────────────────────────────────────────────────────

class _VisualSearchAnimCard extends StatefulWidget {
  const _VisualSearchAnimCard({required this.imagePath});
  final String imagePath;

  @override
  State<_VisualSearchAnimCard> createState() => _VisualSearchAnimCardState();
}

class _VisualSearchAnimCardState extends State<_VisualSearchAnimCard>
    with TickerProviderStateMixin {
  late final AnimationController _beamCtrl;
  late final Animation<double> _beamAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  late final AnimationController _dotCtrl;
  late final Animation<int> _dotAnim;

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
  }

  @override
  void dispose() {
    _beamCtrl.dispose();
    _pulseCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.72;
    final cardHeight = size.height * 0.50;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Image + scan beam (flex 7)
            Expanded(
              flex: 7,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) =>
                    Transform.scale(scale: _pulseAnim.value, child: child),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      widget.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Container(color: Colors.black.withOpacity(0.18)),
                    AnimatedBuilder(
                      animation: _beamAnim,
                      builder: (_, __) => CustomPaint(
                        painter: _TutorialScanBeamPainter(_beamAnim.value),
                      ),
                    ),
                    const CustomPaint(
                      painter: _TutorialCornerBracketsPainter(),
                    ),
                  ],
                ),
              ),
            ),

            // Info section: dots only (no text label — title shown below card)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.white,
              child: AnimatedBuilder(
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
                          color: active
                              ? AppColors.brandBlack
                              : AppColors.gray300,
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tap / camera hint
// ─────────────────────────────────────────────────────────────────────────────

class _TapHint extends StatelessWidget {
  const _TapHint({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 160),
      child: Transform.scale(
        scale: scale,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFf093fb), Color(0xFFF5576c)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66f093fb),
                blurRadius: 14,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.visualSearch,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters (private copies for the tutorial overlay)
// ─────────────────────────────────────────────────────────────────────────────

class _TutorialScanBeamPainter extends CustomPainter {
  final double progress;
  const _TutorialScanBeamPainter(this.progress);

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
  bool shouldRepaint(_TutorialScanBeamPainter old) => old.progress != progress;
}

class _TutorialCornerBracketsPainter extends CustomPainter {
  const _TutorialCornerBracketsPainter();

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
  bool shouldRepaint(_TutorialCornerBracketsPainter _) => false;
}
