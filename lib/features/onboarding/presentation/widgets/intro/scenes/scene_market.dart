import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_garments.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_listing_card.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Stage scene for the "Market" intro slide (C2C second-hand): a two-column
/// marketplace feed whose cards scroll upward continuously — a "feed", not a
/// swipe deck (that's the Shop slide).
class IntroSceneMarket extends StatelessWidget {
  const IntroSceneMarket({super.key, required this.entrance});

  /// The slide's entrance animation; the feed fades/pops in off it.
  final Animation<double> entrance;

  static const double _canvasW = 392;
  static const double _canvasH = 460;
  static const double _colWidth = 170;

  List<IntroListing> _items(AppLocalizations l10n) => [
        IntroListing(
          asset: IntroGarments.market[0],
          title: l10n.introMarketItem1Title,
          size: l10n.introMarketItem1Size,
          price: l10n.introMarketItem1Price,
        ),
        IntroListing(
          asset: IntroGarments.market[1],
          title: l10n.introMarketItem2Title,
          size: l10n.introMarketItem2Size,
          price: l10n.introMarketItem2Price,
        ),
        IntroListing(
          asset: IntroGarments.market[2],
          title: l10n.introMarketItem3Title,
          size: l10n.introMarketItem3Size,
          price: l10n.introMarketItem3Price,
        ),
        IntroListing(
          asset: IntroGarments.market[3],
          title: l10n.introMarketItem4Title,
          size: l10n.introMarketItem4Size,
          price: l10n.introMarketItem4Price,
        ),
        IntroListing(
          asset: IntroGarments.market[4],
          title: l10n.introMarketItem5Title,
          size: l10n.introMarketItem5Size,
          price: l10n.introMarketItem5Price,
        ),
        IntroListing(
          asset: IntroGarments.market[5],
          title: l10n.introMarketItem6Title,
          size: l10n.introMarketItem6Size,
          price: l10n.introMarketItem6Price,
        ),
        IntroListing(
          asset: IntroGarments.market[6],
          title: l10n.introMarketItem7Title,
          size: l10n.introMarketItem7Size,
          price: l10n.introMarketItem7Price,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _items(AppLocalizations.of(context)!);
    // Split the 7 listings across the two columns so nothing repeats between
    // them (column A: first 4, column B: last 3).
    final colA = items.take(4).toList();
    final colB = items.skip(4).toList();

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _canvasW,
          height: _canvasH,
          child: Entrance(
            parent: entrance,
            kind: IntroEntranceKind.pop,
            delay: 0.05,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MarqueeColumn(
                    width: _colWidth,
                    height: _canvasH,
                    items: colA,
                    durationSeconds: 9,
                    startOffset: 0.0,
                  ),
                  const Spacer(),
                  _MarqueeColumn(
                    width: _colWidth,
                    height: _canvasH,
                    items: colB,
                    durationSeconds: 11,
                    startOffset: 0.45,
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

/// One vertically-looping column of listing cards. The card list is rendered
/// twice and translated upward so the loop is seamless.
class _MarqueeColumn extends StatefulWidget {
  const _MarqueeColumn({
    required this.width,
    required this.height,
    required this.items,
    required this.durationSeconds,
    required this.startOffset,
  });

  final double width;
  final double height;
  final List<IntroListing> items;
  final int durationSeconds;
  final double startOffset;

  @override
  State<_MarqueeColumn> createState() => _MarqueeColumnState();
}

class _MarqueeColumnState extends State<_MarqueeColumn>
    with SingleTickerProviderStateMixin {
  static const double _cardHeight = 236;
  static const double _gap = 16;

  late final AnimationController _c;

  double get _contentHeight => widget.items.length * (_cardHeight + _gap);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..value = widget.startOffset % 1.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      for (final item in widget.items)
        Padding(
          padding: const EdgeInsets.only(bottom: _gap),
          child: SizedBox(
            height: _cardHeight,
            child: IntroListingCard(listing: item, compact: true),
          ),
        ),
    ];

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: _contentHeight * 2,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final dy = -((_c.value + widget.startOffset) % 1.0) *
                  _contentHeight;
              return Transform.translate(
                offset: Offset(0, dy),
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [...cards, ...cards],
            ),
          ),
        ),
      ),
    );
  }
}
