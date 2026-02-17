import 'package:flutter/material.dart';
import 'package:swipe/core/utils/responsive_utils.dart';

/// Responsive wrapper for onboarding screens
/// Handles padding, max width constraints, and responsive sizing
class ResponsiveOnboardingLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets? customPadding;
  final double? maxWidth;

  const ResponsiveOnboardingLayout({
    super.key,
    required this.child,
    this.customPadding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final defaultMaxWidth = ResponsiveUtils.responsive<double>(
      context: context,
      mobile: double.infinity,
      tablet: 600,
      desktop: 800,
    );

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth ?? defaultMaxWidth),
        padding:
            customPadding ??
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
        child: child,
      ),
    );
  }
}

/// Responsive grid for selection screens (with multiple choice options)
class ResponsiveSelectionGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double? childAspectRatio;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;

  const ResponsiveSelectionGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.childAspectRatio,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final columnCount = ResponsiveUtils.responsive<int>(
      context: context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: crossAxisSpacing ?? 16,
        mainAxisSpacing: mainAxisSpacing ?? 16,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Responsive text scaling for onboarding screens
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final scaledStyle = style.copyWith(
      fontSize: (style.fontSize ?? 14) * fontScale,
    );

    return Text(
      text,
      style: scaledStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
