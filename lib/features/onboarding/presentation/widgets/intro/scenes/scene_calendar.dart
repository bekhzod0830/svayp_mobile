import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_garments.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Stage scene for the "Календарь" intro slide (deck slide 4): a "this week"
/// label above a horizontally scrollable strip of five day cards — one per
/// weekday of the real current week — each holding a real outfit photo. The
/// strip auto-scrolls left→right and back so the whole week is showcased.
class IntroSceneCalendar extends StatefulWidget {
  const IntroSceneCalendar({super.key, required this.entrance});

  /// The slide's entrance animation; the label rise and the card fly-ins are
  /// choreographed off it.
  final Animation<double> entrance;

  @override
  State<IntroSceneCalendar> createState() => _IntroSceneCalendarState();
}

class _IntroSceneCalendarState extends State<IntroSceneCalendar>
    with SingleTickerProviderStateMixin {
  /// Deck stagger delays d1..d5 for the five day cards.
  static const List<double> _delays = [0.05, 0.12, 0.19, 0.26, 0.33];

  /// A styled outfit (a set of items) per weekday.
  static const List<List<String>> _outfits = [
    [IntroGarments.top, IntroGarments.skirt],
    [IntroGarments.dress, IntroGarments.bag],
    [IntroGarments.romol, IntroGarments.skirt],
    [IntroGarments.top, IntroGarments.bag],
    [IntroGarments.dress, IntroGarments.romol],
  ];

  final ScrollController _scroll = ScrollController();
  late final AnimationController _auto;

  @override
  void initState() {
    super.initState();
    // Slow left→right→left sweep across the week (deck: auto-scroll).
    _auto = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..addListener(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _auto.stop();
    } else if (!_auto.isAnimating) {
      _auto.repeat(reverse: true);
    }
  }

  void _tick() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    _scroll.jumpTo(Curves.easeInOut.transform(_auto.value) * max);
  }

  @override
  void dispose() {
    _auto.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    // Monday of the real current week (weekday: Mon=1 … Sun=7).
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Entrance(
            parent: widget.entrance,
            kind: IntroEntranceKind.rise,
            delay: 0.05,
            child: Text(
              l10n.introThisWeek,
              style: IntroPalette.label(
                size: 12,
                weight: FontWeight.w700,
                color: IntroPalette.gray,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          // The stage container clips at its rounded edges; keeping the strip
          // unclipped lets the card shadows breathe.
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(26, 4, 26, 12),
          child: Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Entrance(
                  parent: widget.entrance,
                  kind: IntroEntranceKind.flyR,
                  delay: _delays[i],
                  child: _DayCard(
                    date: DateTime(monday.year, monday.month, monday.day + i),
                    locale: locale,
                    outfit: _outfits[i],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A single white day card: weekday + date labels above a styled outfit set.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.locale,
    required this.outfit,
  });

  final DateTime date;
  final String locale;
  final List<String> outfit;

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final weekday = _capitalize(DateFormat.E(locale).format(date));
    final dateLine = DateFormat.MMMMd(locale).format(date);

    return Container(
      width: 118,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IntroPalette.bg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          // Deck: 0 12px 24px -14px rgba(20,17,24,.24).
          BoxShadow(
            color: Color(0x3D141118),
            offset: Offset(0, 12),
            blurRadius: 24,
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weekday, style: IntroPalette.label(size: 13)),
          const SizedBox(height: 4),
          Text(
            dateLine,
            style: IntroPalette.label(
              size: 10,
              weight: FontWeight.w500,
              color: IntroPalette.gray,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 92,
            width: double.infinity,
            decoration: BoxDecoration(
              color: IntroPalette.chipBg,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: _OutfitSet(assets: outfit),
          ),
        ],
      ),
    );
  }
}

/// Two transparent garment cutouts overlapped like a curated flat-lay,
/// representing the day's full look.
class _OutfitSet extends StatelessWidget {
  const _OutfitSet({required this.assets});

  final List<String> assets;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: const Alignment(-0.55, -0.35),
          child: FractionallySizedBox(
            widthFactor: 0.6,
            heightFactor: 0.72,
            child: GarmentImage(asset: assets[0], fit: BoxFit.contain),
          ),
        ),
        Align(
          alignment: const Alignment(0.6, 0.5),
          child: FractionallySizedBox(
            widthFactor: 0.58,
            heightFactor: 0.68,
            child: GarmentImage(asset: assets[1], fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}
