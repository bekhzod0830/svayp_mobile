import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';

/// Typography System
/// Following the design system specifications
class AppTypography {
  AppTypography._();

  // Font Family
  static const String primaryFontFamily = 'SF Pro Display'; // iOS
  static const String androidFontFamily = 'Roboto'; // Android

  // Display Styles
  static const TextStyle display1 = TextStyle(
    fontSize: 40,
    height: 1.2, // 48px line height
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    letterSpacing: -0.5,
  );

  static const TextStyle display2 = TextStyle(
    fontSize: 32,
    height: 1.25, // 40px line height
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    letterSpacing: -0.5,
  );

  // Heading Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    height: 1.29, // 36px line height
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    letterSpacing: -0.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    height: 1.33, // 32px line height
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    height: 1.4, // 28px line height
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    letterSpacing: -0.2,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    height: 1.33, // 24px line height
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    letterSpacing: -0.2,
  );

  // Body Styles
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    height: 1.5, // 24px line height
    fontWeight: FontWeight.w400,
    color: AppColors.gray900,
    letterSpacing: 0,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    height: 1.43, // 20px line height
    fontWeight: FontWeight.w400,
    color: AppColors.gray700,
    letterSpacing: 0,
  );

  // Caption Style
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.33, // 16px line height
    fontWeight: FontWeight.w400,
    color: AppColors.gray600,
    letterSpacing: 0.2,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    height: 1.5, // 24px line height
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Link Text
  static const TextStyle link = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
    decoration: TextDecoration.underline,
    letterSpacing: 0,
  );

  // Helper method to get text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}
