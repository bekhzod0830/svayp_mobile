import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_garments.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_listing_card.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Stage scene for the "Shop" intro slide (B2B brand catalog): a stack of
/// product cards that auto-swipe left and right, Tinder-style — exactly like
/// the Discover feed. The top card flies off, the next slides forward.
class IntroSceneShop extends StatefulWidget {
  const IntroSceneShop({super.key, required this.entrance});

  /// The slide's entrance animation; the stack pops in off it.
  final Animation<double> entrance;

  @override
  State<IntroSceneShop> createState() => _IntroSceneShopState();
}

class _IntroSceneShopState extends State<IntroSceneShop>
    with SingleTickerProviderStateMixin {
  static const double _cardWidth = 210;
  static const double _cardHeight = 300;

  /// Outer breathing room so the flying card + shadows survive FittedBox.
  static const double _margin = 40;

  /// One full cycle: the top card rests, then swipes off in [_swipeStart..1].
  static const double _swipeStart = 0.72;

  late final AnimationController _loop;
  int _index = 0;
  int _dir = 1; // +1 = swipe right, -1 = swipe left; alternates each card.
  double _lastValue = 0;

  List<IntroListing> _items(AppLocalizations l10n) => [
        IntroListing(
          asset: IntroGarments.shop[0],
          title: l10n.introShopItem1Title,
          size: l10n.introShopItem1Size,
          price: l10n.introShopItem1Price,
        ),
        IntroListing(
          asset: IntroGarments.shop[1],
          title: l10n.introShopItem2Title,
          size: l10n.introShopItem2Size,
          price: l10n.introShopItem2Price,
        ),
        IntroListing(
          asset: IntroGarments.shop[2],
          title: l10n.introShopItem3Title,
          size: l10n.introShopItem3Size,
          price: l10n.introShopItem3Price,
        ),
        IntroListing(
          asset: IntroGarments.shop[3],
          title: l10n.introShopItem4Title,
          size: l10n.introShopItem4Size,
          price: l10n.introShopItem4Price,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  void _onTick() {
    // Detect the wrap from ~1.0 back to ~0.0 → the top card has flown off, so
    // advance to the next listing and flip the swipe direction.
    if (_loop.value < _lastValue) {
      setState(() {
        _index = (_index + 1) % IntroGarments.shop.length;
        _dir = -_dir;
      });
    }
    _lastValue = _loop.value;
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  /// Swipe progress of the front card: 0 while resting, 0→1 as it flies off.
  double get _swipe {
    final v = _loop.value;
    if (v < _swipeStart) return 0;
    return Curves.easeIn.transform((v - _swipeStart) / (1 - _swipeStart));
  }

  @override
  Widget build(BuildContext context) {
    final items = _items(AppLocalizations.of(context)!);

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _cardWidth + _margin * 2,
          height: _cardHeight + _margin * 2,
          child: Entrance(
            parent: widget.entrance,
            kind: IntroEntranceKind.pop,
            delay: 0.05,
            child: Padding(
              padding: const EdgeInsets.all(_margin),
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, _) {
                  final sp = _swipe;
                  return Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      _depthCard(items, 2, sp),
                      _depthCard(items, 1, sp),
                      _frontCard(items, sp),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A card sitting [offset] positions behind the front one.
  Widget _depthCard(List<IntroListing> items, int offset, double sp) {
    final slot = offset - sp; // effective depth (eases forward as top leaves)
    final scale = 1 - 0.07 * slot;
    final dy = 12.0 * slot;
    final listing = items[(_index + offset) % items.length];
    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: (1.0 - 0.15 * slot).clamp(0.0, 1.0),
          child: IntroListingCard(listing: listing),
        ),
      ),
    );
  }

  /// The interactive top card that swipes off screen.
  Widget _frontCard(List<IntroListing> items, double sp) {
    final dx = _dir * sp * (_cardWidth * 1.9);
    final angle = _dir * sp * 20 * math.pi / 180;
    final opacity = (1 - Curves.easeIn.transform(sp)).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: opacity,
          child: IntroListingCard(
            listing: items[_index % items.length],
            showLike: true,
          ),
        ),
      ),
    );
  }
}
