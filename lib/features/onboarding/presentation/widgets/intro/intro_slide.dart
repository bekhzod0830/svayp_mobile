import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

/// ── Entrance animations ──────────────────────────────────────────────────
///
/// Each slide owns one 1200ms entrance controller (restarted every time the
/// page becomes active). Individual elements animate on a sub-interval of it,
/// reproducing the deck's staggered delay classes d1=.05s … d8=.54s.
enum IntroEntranceKind {
  /// Fade in while rising 24px (deck `rise`).
  rise,

  /// Rise 46px with a slight scale-up from .94 (deck `riseCard`).
  riseCard,

  /// Fly in from the left with a -6° tilt (deck `flyL`).
  flyL,

  /// Fly in from the right with a +6° tilt (deck `flyR`).
  flyR,

  /// Scale from .5 with overshoot (deck `pop`).
  pop,

  /// Coin drop: falls from above with rotation and overshoot (deck `coinDrop`).
  coinDrop,

  /// Badge pop: scale from .3 with a stronger overshoot (deck `badgePop`).
  badgePop,
}

/// Animates [child] on a sub-interval of the slide's entrance controller.
/// [delay] and [duration] are in seconds on the deck's timeline (total 1.2s).
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.parent,
    required this.kind,
    required this.child,
    this.delay = 0.0,
    this.duration = 0.6,
  });

  final Animation<double> parent;
  final IntroEntranceKind kind;
  final double delay;
  final double duration;
  final Widget child;

  static const double _timeline = 1.2;

  @override
  Widget build(BuildContext context) {
    final begin = (delay / _timeline).clamp(0.0, 1.0);
    final end = ((delay + duration) / _timeline).clamp(0.0, 1.0);
    final t = CurvedAnimation(
      parent: parent,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) {
        final v = t.value;
        double opacity;
        double dx = 0, dy = 0, scale = 1, angle = 0;
        switch (kind) {
          case IntroEntranceKind.rise:
            opacity = v;
            dy = 24 * (1 - v);
          case IntroEntranceKind.riseCard:
            opacity = v;
            dy = 46 * (1 - v);
            scale = 0.94 + 0.06 * v;
          case IntroEntranceKind.flyL:
            opacity = v;
            dx = -40 * (1 - v);
            angle = -6 * (1 - v) * math.pi / 180;
          case IntroEntranceKind.flyR:
            opacity = v;
            dx = 40 * (1 - v);
            angle = 6 * (1 - v) * math.pi / 180;
          case IntroEntranceKind.pop:
            opacity = (v / 0.7).clamp(0.0, 1.0);
            scale = v < 0.7
                ? 0.5 + 0.6 * (v / 0.7) // .5 → 1.1
                : 1.1 - 0.1 * ((v - 0.7) / 0.3); // 1.1 → 1
          case IntroEntranceKind.coinDrop:
            opacity = (v / 0.7).clamp(0.0, 1.0);
            if (v < 0.7) {
              final k = v / 0.7;
              dy = -44 + 49 * k; // -44 → +5
              scale = 0.4 + 0.66 * k; // .4 → 1.06
              angle = (-25 + 30 * k) * math.pi / 180; // -25° → +5°
            } else {
              final k = (v - 0.7) / 0.3;
              dy = 5 * (1 - k);
              scale = 1.06 - 0.06 * k;
              angle = 5 * (1 - k) * math.pi / 180;
            }
          case IntroEntranceKind.badgePop:
            opacity = (v / 0.7).clamp(0.0, 1.0);
            dy = 6 * (1 - v);
            scale = v < 0.7
                ? 0.3 + 0.82 * (v / 0.7) // .3 → 1.12
                : 1.12 - 0.12 * ((v - 0.7) / 0.3); // 1.12 → 1
        }
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// ── Ambient loops ────────────────────────────────────────────────────────
///
/// These own their controllers and rely on the surrounding [TickerMode]
/// (the carousel disables tickers on inactive pages) so they cost nothing
/// while off-screen. Honors MediaQuery.disableAnimations.

bool _reducedMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Gentle vertical bobbing (deck `floaty`): 0 → -8px.
/// Variants match the deck: 1 = 4.6s, 2 = 5.4s (+.4s phase), 3 = 4s (+.8s).
class Floaty extends StatefulWidget {
  const Floaty({super.key, required this.child, this.variant = 1});

  final Widget child;
  final int variant;

  @override
  State<Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    final (duration, phase) = switch (widget.variant) {
      2 => (const Duration(milliseconds: 5400), 0.4 / 5.4),
      3 => (const Duration(milliseconds: 4000), 0.8 / 4.0),
      _ => (const Duration(milliseconds: 4600), 0.0),
    };
    _c = AnimationController(vsync: this, duration: duration)..value = phase;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
    );
  }
}

/// Twinkling ✦ sparkle (deck `twinkle`): opacity .15↔1, scale .5↔1, 2.2s.
class Twinkle extends StatefulWidget {
  const Twinkle({
    super.key,
    this.color = IntroPalette.pink,
    this.size = 14,
    this.delaySeconds = 0.0,
  });

  final Color color;
  final double size;
  final double delaySeconds;

  @override
  State<Twinkle> createState() => _TwinkleState();
}

class _TwinkleState extends State<Twinkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..value = (widget.delaySeconds / 2.2) % 1.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotion(context)) {
      _c
        ..stop()
        ..value = 1.0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Opacity(
          opacity: 0.15 + 0.85 * t,
          child: Transform.scale(
            scale: 0.5 + 0.5 * t,
            child: Text(
              '✦',
              style: TextStyle(color: widget.color, fontSize: widget.size),
            ),
          ),
        );
      },
    );
  }
}

/// Sweeping light highlight (deck `shine`/`sweep`). Place inside a clipped
/// Stack (Positioned.fill) — it draws a skewed white bar travelling across.
class Gleam extends StatefulWidget {
  const Gleam({
    super.key,
    this.durationMs = 3800,
    this.travelFraction = 0.55,
    this.widthFraction = 0.45,
    this.opacity = 0.85,
    this.initialDelayMs = 0,
  });

  /// Full loop length; the bar travels during the first [travelFraction] of
  /// it and rests off-screen for the remainder.
  final int durationMs;
  final double travelFraction;
  final double widthFraction;
  final double opacity;
  final int initialDelayMs;

  @override
  State<Gleam> createState() => _GleamState();
}

class _GleamState extends State<Gleam> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    // Negative phase ≈ initial delay: start the loop partway before travel.
    if (widget.initialDelayMs > 0) {
      _c.value =
          1.0 - (widget.initialDelayMs / widget.durationMs).clamp(0.0, 0.99);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotion(context)) {
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
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final barW = w * widget.widthFraction;
            return AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                final k = (t / widget.travelFraction).clamp(0.0, 1.0);
                // Deck: translateX(-160%) → translateX(360%) of the bar width.
                final x = (-1.6 + 5.2 * Curves.easeInOut.transform(k)) * barW;
                if (k >= 1.0) return const SizedBox.expand();
                return Stack(
                  children: [
                    Positioned(
                      left: x,
                      top: 0,
                      bottom: 0,
                      width: barW,
                      child: Transform(
                        transform: Matrix4.skewX(-18 * math.pi / 180),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: widget.opacity),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// ── Slide shell ──────────────────────────────────────────────────────────
///
/// Stage area with a bottom-rounded gradient + kicker/headline/subtitle text
/// block, all entrance-staggered. Scenes receive the entrance animation and
/// compose [Entrance]/[Floaty]/[Twinkle]/[Gleam] freely.
class IntroSlide extends StatefulWidget {
  const IntroSlide({
    super.key,
    required this.active,
    required this.stageGradient,
    required this.title,
    required this.subtitle,
    required this.stageBuilder,
    this.kicker,
    this.stageFlex = 57,
    this.titleSize = 32,
    this.subtitleSize = 16,
    this.centerText = false,
    this.subtitleHighlight,
    this.aboveTextBuilder,
    this.belowTextBuilder,
  });

  final bool active;
  final Gradient stageGradient;
  final String? kicker;
  final String title;
  final String subtitle;
  final double titleSize;
  final double subtitleSize;

  /// If set and present in [subtitle], that substring is emphasized in green
  /// (used to reassure "adding clothes is free").
  final String? subtitleHighlight;

  /// Percentage of the slide height taken by the stage (deck: 57, coins: 42).
  final int stageFlex;

  /// Center the text block (gift slide).
  final bool centerText;

  final Widget Function(BuildContext context, Animation<double> entrance)
      stageBuilder;

  /// Optional content between the stage and the kicker (e.g. the try-on
  /// mannequin/photo toggle).
  final Widget Function(BuildContext context, Animation<double> entrance)?
      aboveTextBuilder;

  /// Optional extra content under the subtitle (price rows, balance chip).
  final Widget Function(BuildContext context, Animation<double> entrance)?
      belowTextBuilder;

  @override
  State<IntroSlide> createState() => IntroSlideState();
}

class IntroSlideState extends State<IntroSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController entrance;

  @override
  void initState() {
    super.initState();
    entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Inactive slides render settled (deck: only dimmed, not empty) so the
    // neighbor peeked at mid-drag isn't blank; the entrance replays on arrival.
    if (widget.active) {
      entrance.forward();
    } else {
      entrance.value = 1.0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotion(context)) entrance.value = 1.0;
  }

  @override
  void didUpdateWidget(IntroSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      if (_reducedMotion(context)) {
        entrance.value = 1.0;
      } else {
        entrance.forward(from: 0);
      }
    } else if (!widget.active && oldWidget.active) {
      entrance.value = 1.0;
    }
  }

  @override
  void dispose() {
    entrance.dispose();
    super.dispose();
  }

  /// Subtitle text, optionally emphasizing [IntroSlide.subtitleHighlight] in
  /// green + bold to reassure users (e.g. "…is always free!").
  Widget _buildSubtitle(double scale) {
    final base = IntroPalette.subtitle(size: widget.subtitleSize * scale);
    final align = widget.centerText ? TextAlign.center : TextAlign.start;
    final hl = widget.subtitleHighlight;
    final idx = hl == null ? -1 : widget.subtitle.indexOf(hl);
    if (hl == null || idx < 0) {
      return Text(widget.subtitle, textAlign: align, style: base);
    }
    final green = base.copyWith(
      color: IntroPalette.freeGreen,
      fontWeight: FontWeight.w800,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (idx > 0) TextSpan(text: widget.subtitle.substring(0, idx)),
          TextSpan(text: hl, style: green),
          TextSpan(text: widget.subtitle.substring(idx + hl.length)),
        ],
      ),
      textAlign: align,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Small-phone adjustment: scale type down slightly under 700dp height.
    final compact = MediaQuery.sizeOf(context).height < 700;
    final scale = compact ? 0.88 : 1.0;
    final crossAlign =
        widget.centerText ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return ColoredBox(
      color: IntroPalette.bg,
      child: Column(
        children: [
          Expanded(
            flex: widget.stageFlex,
            child: AnimatedOpacity(
              // Deck: inactive stages sit at half opacity and brighten on
              // arrival (.stagewrap opacity transition).
              duration: const Duration(milliseconds: 450),
              opacity: widget.active ? 1.0 : 0.5,
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: widget.stageGradient,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(36),
                  ),
                ),
                child: widget.stageBuilder(context, entrance),
              ),
            ),
          ),
          Expanded(
            flex: 100 - widget.stageFlex,
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, compact ? 16 : 20, 28, 0),
              child: Column(
                crossAxisAlignment: crossAlign,
                children: [
                  if (widget.aboveTextBuilder != null) ...[
                    widget.aboveTextBuilder!(context, entrance),
                    SizedBox(height: compact ? 14 : 18),
                  ],
                  if (widget.kicker != null) ...[
                    Entrance(
                      parent: entrance,
                      kind: IntroEntranceKind.rise,
                      delay: 0.05,
                      child: Text(
                        widget.kicker!.toUpperCase(),
                        style: IntroPalette.kicker,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Entrance(
                    parent: entrance,
                    kind: IntroEntranceKind.rise,
                    delay: 0.12,
                    child: Text(
                      widget.title,
                      textAlign:
                          widget.centerText ? TextAlign.center : TextAlign.start,
                      style: IntroPalette.headline(
                        size: widget.titleSize * scale,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Entrance(
                    parent: entrance,
                    kind: IntroEntranceKind.rise,
                    delay: 0.19,
                    child: _buildSubtitle(scale),
                  ),
                  if (widget.belowTextBuilder != null) ...[
                    SizedBox(height: compact ? 12 : 16),
                    Expanded(child: widget.belowTextBuilder!(context, entrance)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
