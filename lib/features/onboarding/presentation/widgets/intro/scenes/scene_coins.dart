import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_diamond.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Stage scene for intro slide 6 "Алмазы — чтобы творить": a single hero
/// brand-gem diamond over a soft glow, with two accent diamonds behind it
/// and a few ambient sparkles.
class IntroSceneCoins extends StatelessWidget {
  const IntroSceneCoins({super.key, required this.entrance});

  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Center(child: _Glow(size: 230, opacity: 0.24)),
        const Center(child: _Glow(size: 140, opacity: 0.30)),
        Center(
          child: Entrance(
            parent: entrance,
            kind: IntroEntranceKind.coinDrop,
            delay: 0.05,
            child: const _DiamondHero(),
          ),
        ),
        const Align(
          alignment: Alignment(-0.5, -0.5),
          child: Twinkle(color: IntroPalette.gem, size: 15),
        ),
        const Align(
          alignment: Alignment(0.52, 0.5),
          child: Twinkle(color: IntroPalette.gem, size: 12, delaySeconds: 0.6),
        ),
        const Align(
          alignment: Alignment(0.6, -0.55),
          child: Twinkle(color: IntroPalette.pink, size: 11, delaySeconds: 0.3),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                IntroPalette.gem.withValues(alpha: opacity),
                IntroPalette.gem.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
      ),
    );
  }
}

/// One hero diamond (92px, gleaming) with a smaller diamond tucked behind on
/// each side, all gently bobbing.
class _DiamondHero extends StatelessWidget {
  const _DiamondHero();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 176,
      height: 116,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            top: 42,
            child: Floaty(variant: 2, child: IntroDiamond(size: 50)),
          ),
          Positioned(
            right: 8,
            top: 48,
            child: Floaty(variant: 3, child: IntroDiamond(size: 42)),
          ),
          Align(
            child: Floaty(child: IntroDiamond(size: 92, withGleam: true)),
          ),
        ],
      ),
    );
  }
}

/// A simple, non-numeric note under the slide-6 subtitle: some actions use
/// diamonds, adding your own clothes is always free. Deliberately avoids
/// per-action prices — it just introduces the currency.
class IntroCoinPriceRows extends StatelessWidget {
  const IntroCoinPriceRows({super.key, required this.entrance});

  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.topCenter,
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Entrance(
              parent: entrance,
              kind: IntroEntranceKind.rise,
              delay: 0.26,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14141118),
                      offset: Offset(0, 10),
                      blurRadius: 26,
                      spreadRadius: -14,
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFEDEAF1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NoteRow(
                      label: l10n.introDiamondUses,
                      trailing: const IntroDiamond(size: 20),
                    ),
                    const _Divider(),
                    _NoteRow(
                      label: l10n.introDiamondFreeLabel,
                      trailing: _FreeBadge(text: l10n.introCoinFree),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFF1EEF4));
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: IntroPalette.label(weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

/// Green "free" pill.
class _FreeBadge extends StatelessWidget {
  const _FreeBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: IntroPalette.freeGreenBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: IntroPalette.label(size: 12, color: IntroPalette.freeGreen),
      ),
    );
  }
}
