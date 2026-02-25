import 'package:flutter/material.dart';

/// A Column widget that automatically prevents overflow by making content scrollable
/// when it doesn't fit in the available space.
///
/// This widget wraps children in a Column and automatically adds scrolling
/// capability if the content height exceeds available space.
///
/// Example usage:
/// ```dart
/// OverflowSafeColumn(
///   children: [
///     Header(),
///     Content(),
///     Footer(),
///   ],
/// )
/// ```
class OverflowSafeColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const OverflowSafeColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: physics ?? const ClampingScrollPhysics(),
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: crossAxisAlignment,
                mainAxisAlignment: mainAxisAlignment,
                mainAxisSize: mainAxisSize,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A safe area aware bottom action bar that respects device safe areas
/// and prevents overflow issues.
///
/// Automatically adds proper padding for devices with notches, home indicators, etc.
///
/// Example usage:
/// ```dart
/// SafeBottomActionBar(
///   children: [
///     ActionButton1(),
///     ActionButton2(),
///   ],
/// )
/// ```
class SafeBottomActionBar extends StatelessWidget {
  final List<Widget> children;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double? minBottomPadding;
  final double? topPadding;

  const SafeBottomActionBar({
    super.key,
    required this.children,
    this.backgroundColor,
    this.padding,
    this.boxShadow,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.minBottomPadding = 12,
    this.topPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);

    return Container(
      padding:
          padding ??
          EdgeInsets.only(
            left: 16,
            right: 16,
            top: topPadding ?? 12,
            bottom: bottomSafeArea > 0
                ? bottomSafeArea + (minBottomPadding ?? 8)
                : (minBottomPadding ?? 12),
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
      ),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
}

/// A flexible screen layout that prevents overflow by intelligently
/// distributing space between header, content, and footer.
///
/// The content area will expand to fill available space, and the footer
/// is guaranteed to always be visible without causing overflow.
///
/// Example usage:
/// ```dart
/// FlexibleScreenLayout(
///   header: AppBar(),
///   content: MainContent(),
///   footer: ActionButtons(),
/// )
/// ```
class FlexibleScreenLayout extends StatelessWidget {
  final Widget? header;
  final Widget content;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const FlexibleScreenLayout({
    super.key,
    this.header,
    required this.content,
    this.footer,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            if (header != null) header!,
            Expanded(
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: content,
              ),
            ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}

/// A card stack layout that prevents overflow by dynamically
/// adjusting to available screen space.
///
/// Useful for swipeable card interfaces like Tinder or discovery feeds.
///
/// Example usage:
/// ```dart
/// CardStackLayout(
///   cards: Stack(
///     children: cardWidgets,
///   ),
///   actions: ActionButtonsRow(),
/// )
/// ```
class CardStackLayout extends StatelessWidget {
  final Widget cards;
  final Widget actions;
  final EdgeInsetsGeometry? padding;

  const CardStackLayout({
    super.key,
    required this.cards,
    required this.actions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Card area takes available space
            Expanded(
              child: Center(
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: cards,
                ),
              ),
            ),
            // Actions always visible at bottom
            actions,
          ],
        );
      },
    );
  }
}

/// A responsive spacer that adjusts its size based on available space
/// and screen size to prevent overflow.
///
/// Example usage:
/// ```dart
/// Column(
///   children: [
///     Widget1(),
///     ResponsiveSpacer(minHeight: 8, maxHeight: 24),
///     Widget2(),
///   ],
/// )
/// ```
class ResponsiveSpacer extends StatelessWidget {
  final double minHeight;
  final double maxHeight;
  final double preferredHeight;

  const ResponsiveSpacer({
    super.key,
    this.minHeight = 4,
    this.maxHeight = 24,
    this.preferredHeight = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;

        // Use smaller spacing on small screens
        double height = preferredHeight;
        if (screenHeight < 700) {
          height = minHeight;
        } else if (screenHeight > 900) {
          height = maxHeight;
        }

        return SizedBox(height: height);
      },
    );
  }
}

/// Extension on BuildContext to easily check if content might overflow
extension OverflowCheckExtension on BuildContext {
  /// Returns true if the screen is considered "small" and might be prone to overflow
  bool get isSmallScreen {
    final height = MediaQuery.of(this).size.height;
    return height < 700; // iPhone SE and smaller
  }

  /// Returns the safe bottom padding (for home indicator, notch, etc.)
  double get safeBottomPadding {
    return MediaQuery.of(this).padding.bottom;
  }

  /// Returns appropriate spacing based on screen size
  double getAdaptiveSpacing({
    double small = 8,
    double medium = 16,
    double large = 24,
  }) {
    final height = MediaQuery.of(this).size.height;
    if (height < 700) return small;
    if (height < 900) return medium;
    return large;
  }
}
