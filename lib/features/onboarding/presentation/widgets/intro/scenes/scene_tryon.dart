import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_garments.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Result variants cycled on the try-on slide: on a mannequin, on the user's
/// own photo, and on the user's photo in a modest (covered) look.
const List<String> _tryOnResults = [
  IntroGarments.tryOnMannequin,
  IntroGarments.tryOnPhoto,
  IntroGarments.tryOnPhotoCovered,
];

/// Stage scene for the "Try on" intro slide (deck slide 3): a small "before"
/// garment card (the flat product photo) and a large "result" card that cycles
/// mannequin → own photo → own photo (covered), each revealed over the last by
/// a right→left wipe, crowned by an "AI ✦" badge. The variant is driven by
/// [mode] (shared with the toggle below the text) and auto-cycles every ~2.6s.
class IntroSceneTryOn extends StatefulWidget {
  const IntroSceneTryOn({
    super.key,
    required this.entrance,
    required this.mode,
    required this.active,
  });

  final Animation<double> entrance;

  /// Shared with [IntroTryOnToggle]: index into [_tryOnResults]
  /// (0 = mannequin, 1 = own photo, 2 = own photo covered).
  final ValueNotifier<int> mode;

  /// Whether this slide is the visible page (gates the auto-cycle timer).
  final bool active;

  @override
  State<IntroSceneTryOn> createState() => _IntroSceneTryOnState();
}

class _IntroSceneTryOnState extends State<IntroSceneTryOn>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _wipe;
  late final Animation<double> _wipeT;
  // The two layers of the result card: [_prev] beneath, [_current] wiped over.
  late int _current = widget.mode.value;
  late int _prev = widget.mode.value;

  @override
  void initState() {
    super.initState();
    _wipe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0, // current fully shown
    );
    _wipeT = CurvedAnimation(parent: _wipe, curve: const Cubic(0.7, 0, 0.2, 1));
    widget.mode.addListener(_applyMode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  @override
  void didUpdateWidget(IntroSceneTryOn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      oldWidget.mode.removeListener(_applyMode);
      widget.mode.addListener(_applyMode);
      _applyMode();
    }
    if (oldWidget.active != widget.active) _syncTimer();
  }

  void _syncTimer() {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.active && !reduced) {
      _timer ??= Timer.periodic(
        const Duration(milliseconds: 2600),
        (_) => widget.mode.value =
            (widget.mode.value + 1) % _tryOnResults.length,
      );
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _applyMode() {
    if (widget.mode.value == _current) return;
    setState(() {
      _prev = _current;
      _current = widget.mode.value;
    });
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _wipe.value = 1.0;
    } else {
      _wipe.forward(from: 0.0); // reveal the new result over the previous one
    }
  }

  @override
  void dispose() {
    widget.mode.removeListener(_applyMode);
    _timer?.cancel();
    _wipe.dispose();
    super.dispose();
  }

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
              // "Before" flat garment card. Pushed down so the top overlay
              // (Skip / back / language) never covers the composition.
              Positioned(
                left: 30,
                top: 214,
                child: Entrance(
                  parent: widget.entrance,
                  kind: IntroEntranceKind.flyL,
                  delay: 0.19,
                  child: _buildBeforeCard(),
                ),
              ),
              // Connector arrow: "this garment → tried on you".
              Positioned(
                left: 150,
                top: 268,
                child: Entrance(
                  parent: widget.entrance,
                  kind: IntroEntranceKind.pop,
                  delay: 0.42,
                  child: const _ConnectorArrow(),
                ),
              ),
              // "Result" card with the mannequin/photo wipe.
              Positioned(
                top: 138,
                right: 30,
                child: Entrance(
                  parent: widget.entrance,
                  kind: IntroEntranceKind.pop,
                  delay: 0.26,
                  child: _buildResultCard(),
                ),
              ),
              // "AI ✦" badge on the result card's upper-left edge.
              Positioned(
                top: 138,
                right: 158,
                child: Entrance(
                  parent: widget.entrance,
                  kind: IntroEntranceKind.badgePop,
                  delay: 0.5,
                  duration: 0.6,
                  child: _buildAiBadge(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeforeCard() {
    return Container(
      width: 116,
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: IntroPalette.ink.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: -16,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(IntroGarments.tryOnFlat, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: 168,
      height: 224,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: IntroPalette.ink.withValues(alpha: 0.34),
            blurRadius: 44,
            spreadRadius: -16,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Previous result, beneath.
          Image.asset(_tryOnResults[_prev], fit: BoxFit.cover),
          // New result revealed by a right→left wipe.
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _wipeT,
              builder: (context, child) => ClipRect(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: _wipeT.value,
                  child: child,
                ),
              ),
              child: SizedBox(
                width: 168,
                height: 224,
                child: Image.asset(_tryOnResults[_current], fit: BoxFit.cover),
              ),
            ),
          ),
          // Sweeping highlight across the card.
          const Positioned.fill(
            child: Gleam(
              durationMs: 3400,
              travelFraction: 0.6,
              widthFraction: 0.4,
              opacity: 0.55,
              initialDelayMs: 1000,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: IntroPalette.pink.withValues(alpha: 0.5),
            blurRadius: 22,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) =>
                IntroPalette.pinkGradient.createShader(bounds),
            child: Text(
              'AI',
              style: IntroPalette.label(
                size: 12,
                weight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            '✦',
            style: TextStyle(color: IntroPalette.pink, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// A small gem-gradient circle with a right arrow, sitting between the "before"
/// garment card and the "result" card to convey "this item → tried on you".
class _ConnectorArrow extends StatelessWidget {
  const _ConnectorArrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: IntroPalette.diamondGradient,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: IntroPalette.gem.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

/// The mannequin / own-photo segmented toggle, rendered below the stage (above
/// the "Примерка" text). Shares [mode] with [IntroSceneTryOn].
class IntroTryOnToggle extends StatelessWidget {
  const IntroTryOnToggle({
    super.key,
    required this.entrance,
    required this.mode,
  });

  final Animation<double> entrance;
  final ValueNotifier<int> mode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Entrance(
      parent: entrance,
      kind: IntroEntranceKind.rise,
      delay: 0.05,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ValueListenableBuilder<int>(
          valueListenable: mode,
          // index 0 = mannequin, 1/2 = own photo (regular / covered)
          builder: (context, index, _) => Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: IntroPalette.chipBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Segment(
                  label: l10n.introTryOnMannequin,
                  selected: index == 0,
                  onTap: () => mode.value = 0,
                ),
                const SizedBox(width: 4),
                _Segment(
                  label: l10n.introTryOnPhoto,
                  selected: index >= 1,
                  onTap: () => mode.value = 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? null : Colors.transparent,
          gradient: selected ? IntroPalette.pinkGradient : null,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: IntroPalette.pink.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          style: IntroPalette.label(
            size: 13,
            weight: FontWeight.w700,
            color: selected ? Colors.white : IntroPalette.gray,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
