import 'package:flutter/material.dart';

/// App Colors - Monochrome Theme
/// Following the design system specifications
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color brandBlack = Color(0xFF000000);
  static const Color brandWhite = Color(0xFFFFFFFF);

  // Grayscale Palette
  static const Color black = Color(0xFF000000);
  static const Color gray900 = Color(0xFF1A1A1A);
  static const Color gray800 = Color(0xFF2D2D2D);
  static const Color gray700 = Color(0xFF4A4A4A);
  static const Color gray600 = Color(0xFF6B6B6B);
  static const Color gray500 = Color(0xFF9B9B9B);
  static const Color gray400 = Color(0xFFB8B8B8);
  static const Color gray300 = Color(0xFFD1D1D1);
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic Colors - Light Theme
  // Backgrounds
  static const Color mainBackground = white;
  static const Color pageBackground = gray50;
  static const Color cardBackground = white;
  static const Color overlayBackground = Color(
    0x80000000,
  ); // rgba(0, 0, 0, 0.5)

  // Text
  static const Color primaryText = black;
  static const Color secondaryText = gray700;
  static const Color tertiaryText = gray500;
  static const Color invertedText = white;
  static const Color placeholderText = gray600;
  static const Color disabledText = gray400;

  // Borders & Dividers
  static const Color strongBorder = black;
  static const Color standardBorder = gray300;
  static const Color lightBorder = gray200;
  static const Color divider = gray100;

  // Interactive Elements
  static const Color buttonDefault = black;
  static const Color buttonHover = gray800;
  static const Color buttonActive = black;
  static const Color buttonDisabled = gray300;
  static const Color buttonTextDisabled = gray500;

  // Status Colors (using black with icons)
  static const Color success = black;
  static const Color error = black;
  static const Color warning = gray700;
  static const Color info = black;

  // Overlay Colors for Swipe Actions
  static const Color likeOverlay = Color(0xE6000000); // Black with 90% opacity
  static const Color dislikeOverlay = Color(0xE6000000);
  static const Color superLikeOverlay = Color(0xE6000000);

  // Shadow Colors
  static Color shadow8 = black.withValues(alpha: 0.08);
  static Color shadow12 = black.withValues(alpha: 0.12);
  static Color shadow16 = black.withValues(alpha: 0.16);
  static Color shadow24 = black.withValues(alpha: 0.24);

  // Dark Theme Colors - Apple Style
  // Backgrounds
  static const Color darkMainBackground = Color(0xFF000000); // Pure black
  static const Color darkPageBackground = Color(0xFF000000); // Pure black
  static const Color darkCardBackground = Color(0xFF1C1C1E); // Elevated surface
  static const Color darkOverlayBackground = Color(0x80000000);

  // Text
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFAAAAAA);
  static const Color darkTertiaryText = Color(0xFF707070);
  static const Color darkInvertedText = Color(0xFF000000);
  static const Color darkPlaceholderText = Color(0xFF6B6B6B);
  static const Color darkDisabledText = Color(0xFF4A4A4A);

  // Borders & Dividers
  static const Color darkStrongBorder = Color(0xFF3A3A3C);
  static const Color darkStandardBorder = Color(0xFF2C2C2E);
  static const Color darkLightBorder = Color(0xFF1C1C1E);
  static const Color darkDivider = Color(0xFF2C2C2E);

  // Interactive Elements
  static const Color darkButtonDefault = Color(0xFFFFFFFF);
  static const Color darkButtonHover = Color(0xFFE5E5E7);
  static const Color darkButtonActive = Color(0xFFFFFFFF);
  static const Color darkButtonDisabled = Color(0xFF3A3A3C);
  static const Color darkButtonTextDisabled = Color(0xFF6B6B6B);

  // Shadow Colors for Dark Theme
  static Color darkShadow8 = white.withValues(alpha: 0.08);
  static Color darkShadow12 = white.withValues(alpha: 0.12);
  static Color darkShadow16 = white.withValues(alpha: 0.16);
  static Color darkShadow24 = white.withValues(alpha: 0.24);
}
