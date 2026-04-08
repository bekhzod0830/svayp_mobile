import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

enum SwipeFeedbackType { liked, addedToCart, undo, pressBackToExit }

/// Pinterest-style top-of-screen pill that slides in for like / add-to-cart.
///
/// Usage:
/// ```dart
/// SwipeFeedbackBanner.show(context, SwipeFeedbackType.liked);
/// ```
class SwipeFeedbackBanner {
  static OverlayEntry? _current;

  static void show(BuildContext context, SwipeFeedbackType type) {
    // Dismiss any banner already on screen.
    _current?.remove();
    _current = null;

    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final IconData icon;
    final Color iconColor;
    final String label;

    switch (type) {
      case SwipeFeedbackType.liked:
        icon = Icons.favorite_rounded;
        iconColor = const Color(0xFFFF3B5C);
        label = l10n.addedToLiked;
        break;
      case SwipeFeedbackType.addedToCart:
        icon = Icons.shopping_bag_rounded;
        iconColor = const Color(0xFF30D158);
        label = l10n.addedToCart;
        break;
      case SwipeFeedbackType.undo:
        icon = Icons.undo_rounded;
        iconColor = const Color(0xFF0A84FF);
        label = l10n.undo;
        break;
      case SwipeFeedbackType.pressBackToExit:
        icon = Icons.logout_rounded;
        iconColor = const Color(0xFFFF9500);
        label = l10n.pressBackAgainToExit;
        break;
    }

    void dismiss() {
      _current?.remove();
      _current = null;
    }

    final entry = OverlayEntry(
      builder: (_) => _BannerWidget(
        icon: icon,
        iconColor: iconColor,
        label: label,
        isDark: isDark,
        onDone: dismiss,
      ),
    );

    _current = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BannerWidget extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isDark;
  final VoidCallback onDone;

  const _BannerWidget({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isDark,
    required this.onDone,
  });

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _slide = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );

    _ctrl.forward();

    // Auto-dismiss after 1.8 s visible time.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          if (mounted) widget.onDone();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final slideValue = _slide.value.clamp(0.0, 1.0);
        final dy = (1.0 - slideValue) * -72.0; // slides down from -72px
        return Positioned(
          top: topPadding + 12 + dy,
          left: 0,
          right: 0,
          child: Opacity(opacity: _fade.value.clamp(0.0, 1.0), child: child!),
        );
      },
      child: Center(
        child: IgnorePointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xF2141418)
                      : const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: widget.isDark
                        ? const Color(0x33FFFFFF)
                        : const Color(0x33000000),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDark
                          ? const Color(0x55000000)
                          : const Color(0x22000000),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: widget.iconColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        decoration: TextDecoration.none,
                      ),
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
