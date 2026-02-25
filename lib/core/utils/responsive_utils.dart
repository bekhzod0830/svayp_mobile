/// Responsive Utility for adapting UI to different screen sizes
/// Handles phone, tablet, and desktop layouts

import 'package:flutter/material.dart';

class ResponsiveUtils {
  /// Device type breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if device is mobile (phone)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive value based on device type
  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Get card width for swipeable cards (optimized for readability)
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth * 0.88; // 88% on mobile
    } else if (isTablet(context)) {
      return 500; // Fixed width on tablet for better readability
    } else {
      return 600; // Slightly wider on desktop
    }
  }

  /// Get card height for swipeable cards
  static double getCardHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (isMobile(context)) {
      // More conservative heights to prevent overflow
      if (screenHeight < 700) {
        // Small screens (iPhone SE, etc.) - 58% with max 380px
        return (screenHeight * 0.58).clamp(0, 380);
      } else if (screenHeight < 800) {
        // Medium screens - 62% with max 500px
        return (screenHeight * 0.62).clamp(0, 500);
      } else {
        // Large screens - 65% with max 550px
        return (screenHeight * 0.65).clamp(0, 550);
      }
    } else {
      // Tablet/Desktop - 70% with max 600px
      return (screenHeight * 0.70).clamp(0, 600);
    }
  }

  /// Get horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return 16;
    } else if (isTablet(context)) {
      return 32;
    } else {
      return 48;
    }
  }

  /// Get grid column count for shop/liked screens
  static int getGridColumnCount(BuildContext context) {
    if (isMobile(context)) {
      return 2; // 2 columns on mobile
    } else if (isTablet(context)) {
      return 3; // 3 columns on tablet
    } else {
      return 4; // 4 columns on desktop
    }
  }

  /// Get font size scale based on device
  static double getFontSizeScale(BuildContext context) {
    if (isTablet(context)) {
      return 1.1; // 10% larger on tablet
    } else if (isDesktop(context)) {
      return 1.2; // 20% larger on desktop
    }
    return 1.0; // Normal size on mobile
  }

  /// Get icon size scale based on device
  static double getIconSizeScale(BuildContext context) {
    if (isTablet(context)) {
      return 1.2; // 20% larger on tablet
    } else if (isDesktop(context)) {
      return 1.3; // 30% larger on desktop
    }
    return 1.0; // Normal size on mobile
  }

  /// Center content with max width on large screens
  static Widget centerWithMaxWidth({
    required Widget child,
    double maxWidth = 1200,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Get bottom navigation bar height
  static double getBottomNavHeight(BuildContext context) {
    if (isTablet(context)) {
      return 72; // Taller on tablet
    }
    return 60; // Standard height on mobile
  }

  /// Get app bar height
  static double getAppBarHeight(BuildContext context) {
    if (isTablet(context)) {
      return 64; // Taller on tablet
    }
    return 56; // Standard height on mobile
  }
}
