import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// The style-preferences prompt, rendered as a card *inside* the swipe deck.
///
/// Replaces the pink gradient banner that used to sit above the deck. That
/// banner had the exact shape people have trained themselves to skip — a
/// full-bleed coloured strip pinned above the content — so it was ignored no
/// matter what it said. Here the ask sits in the swipe path wearing the same
/// geometry as a product card: it can't be scrolled past, and answering is one
/// tap on a photo rather than a trip into an unbounded funnel.
///
/// The question is literally the funnel's first step (covered / uncovered), so
/// a tap here isn't a teaser — it's an answer, and the flow resumes at step 2.
class PersonalizeQuestionCard extends StatefulWidget {
  /// Whether to show the covered/uncovered photo choice. False for users the
  /// question doesn't apply to — they get a plain CTA into the same flow.
  final bool showStyleChoice;

  /// One of 'covered' / 'uncovered', tapped directly on the card.
  final ValueChanged<String> onAnswer;

  /// CTA for the [showStyleChoice] == false variant — opens the flow at step 1.
  final VoidCallback onStart;

  /// «Keyinroq», or the card being flung off the deck.
  final VoidCallback onDismiss;

  const PersonalizeQuestionCard({
    super.key,
    required this.showStyleChoice,
    required this.onAnswer,
    required this.onStart,
    required this.onDismiss,
  });

  @override
  State<PersonalizeQuestionCard> createState() =>
      _PersonalizeQuestionCardState();
}

class _PersonalizeQuestionCardState extends State<PersonalizeQuestionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Offset> _offsetAnimation = const AlwaysStoppedAnimation(
    Offset.zero,
  );

  /// Entry animation — the card should feel dealt onto the deck, not spawned.
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _leaving = false;

  static const double _dismissThreshold = 110.0;
  static const double _velocityThreshold = 800.0;

  @override
  void dispose() {
    _controller.dispose();
    _entry.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails _) {
    if (_leaving) return;
    _isDragging = true;
    _controller.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() => _dragOffset += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final flung =
        _dragOffset.dx.abs() > _dismissThreshold ||
        velocity.abs() > _velocityThreshold;

    if (flung) {
      _flyAway(_dragOffset.dx.isNegative ? -1 : 1);
    } else {
      _springBack();
    }
  }

  void _springBack() {
    _offsetAnimation =
        Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        )..addListener(() {
          setState(() => _dragOffset = _offsetAnimation.value);
        });
    _controller.forward(from: 0);
  }

  /// Swiping the card off the deck means "not now" — same as «Keyinroq».
  void _flyAway(int direction) {
    if (_leaving) return;
    _leaving = true;
    HapticFeedback.lightImpact();

    final screenWidth = MediaQuery.of(context).size.width;
    _offsetAnimation =
        Tween<Offset>(
          begin: _dragOffset,
          end: Offset(direction * (screenWidth + 200), _dragOffset.dy),
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        )..addListener(() {
          setState(() => _dragOffset = _offsetAnimation.value);
        });

    _controller.forward(from: 0).whenComplete(widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardWidth = ResponsiveUtils.getCardWidth(context);
    final cardHeight = ResponsiveUtils.getCardHeight(context);
    final isShort = MediaQuery.of(context).size.height < 700;

    // Mirrors the product card's drag feel: tilt toward the fling direction.
    final rotation = (_dragOffset.dx / 1000).clamp(-0.12, 0.12);

    return AnimatedBuilder(
      animation: _entry,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_entry.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
          ),
        );
      },
      child: RepaintBoundary(
        child: Transform(
          transform: Matrix4.identity()
            ..translate(_dragOffset.dx, _dragOffset.dy)
            ..rotateZ(rotation * math.pi / 2),
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 64,
                      offset: Offset(0, 24),
                    ),
                    BoxShadow(
                      color: Color(0x28000000),
                      blurRadius: 36,
                      offset: Offset(0, 16),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    color: isDark ? const Color(0xFF121214) : Colors.white,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      isShort ? 18 : 24,
                      20,
                      isShort ? 10 : 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEyebrow(l10n, isDark),
                        SizedBox(height: isShort ? 10 : 14),
                        Text(
                          widget.showStyleChoice
                              ? l10n.personalizeCardTitle
                              : l10n.personalizeBannerTitle,
                          style: TextStyle(
                            fontSize: isShort ? 22 : 25,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.showStyleChoice
                              ? l10n.personalizeCardSubtitle
                              : l10n.personalizeBannerSubtitle,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0x99FFFFFF)
                                : const Color(0x8A000000),
                          ),
                        ),
                        SizedBox(height: isShort ? 14 : 20),
                        Expanded(
                          child: widget.showStyleChoice
                              ? _buildChoices(l10n)
                              : _buildGenericCta(l10n, isDark),
                        ),
                        SizedBox(height: isShort ? 6 : 10),
                        Center(
                          child: TextButton(
                            onPressed: _leaving ? null : widget.onDismiss,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(88, 40),
                              foregroundColor: isDark
                                  ? const Color(0x99FFFFFF)
                                  : const Color(0x8A000000),
                            ),
                            child: Text(
                              l10n.personalizeCardLater,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bounds the commitment up front — the old banner's "answer a few quick
  /// questions" hid how long the flow was, which is its own reason to skip.
  Widget _buildEyebrow(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x26F370A7) : const Color(0x14F370A7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l10n.personalizeCardEyebrow,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Color(0xFFE0409A),
        ),
      ),
    );
  }

  Widget _buildChoices(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _ChoiceTile(
            label: l10n.covered,
            imagePath: 'lib/img/style_preference/covered.png',
            onTap: _leaving ? null : () => widget.onAnswer('covered'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ChoiceTile(
            label: l10n.uncovered,
            imagePath: 'lib/img/style_preference/uncovered.png',
            onTap: _leaving ? null : () => widget.onAnswer('uncovered'),
          ),
        ),
      ],
    );
  }

  Widget _buildGenericCta(AppLocalizations l10n, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _leaving ? null : widget.onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: Text(
              l10n.personalizeCardStart,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

/// One tappable answer — a photo the size of half the card, so the choice reads
/// as part of the deck rather than as a form control.
class _ChoiceTile extends StatefulWidget {
  final String label;
  final String imagePath;
  final VoidCallback? onTap;

  const _ChoiceTile({
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<_ChoiceTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  widget.imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                // Scrim so the label stays readable over any photo.
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 88,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xB3000000)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }
}
