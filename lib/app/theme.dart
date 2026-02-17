import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';

/// App Theme Configuration
class AppTheme {
  AppTheme._();

  /// Light Theme (Primary Theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandBlack,
        onPrimary: AppColors.brandWhite,
        secondary: AppColors.gray800,
        onSecondary: AppColors.brandWhite,
        surface: AppColors.white,
        onSurface: AppColors.black,
        error: AppColors.error,
        onError: AppColors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.pageBackground,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.heading4,
        iconTheme: IconThemeData(color: AppColors.black, size: 24),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.black,
        unselectedItemColor: AppColors.gray600,
        selectedLabelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: AppTypography.caption.copyWith(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Card
      // Card
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shadowColor: AppColors.shadow8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.standardBorder,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.standardBorder,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.black, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray300, width: 1.5),
        ),
        labelStyle: AppTypography.body2,
        hintStyle: AppTypography.body2.copyWith(
          color: AppColors.placeholderText,
        ),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonDefault,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.buttonTextDisabled,
          elevation: 4,
          shadowColor: AppColors.shadow12,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Fully rounded
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.black,
          disabledForegroundColor: AppColors.buttonTextDisabled,
          side: const BorderSide(color: AppColors.black, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.black,
          disabledForegroundColor: AppColors.buttonTextDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTypography.button.copyWith(fontWeight: FontWeight.w500),
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.black,
          disabledForegroundColor: AppColors.buttonDisabled,
          minimumSize: const Size(44, 44),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Dialog
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 16,
        shadowColor: AppColors.shadow16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTypography.heading3,
        contentTextStyle: AppTypography.body1,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.white,
        elevation: 16,
        shadowColor: AppColors.shadow16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray100,
        deleteIconColor: AppColors.black,
        disabledColor: AppColors.gray200,
        selectedColor: AppColors.black,
        secondarySelectedColor: AppColors.gray800,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTypography.body2,
        secondaryLabelStyle: AppTypography.body2,
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.black,
        linearTrackColor: AppColors.gray200,
        circularTrackColor: AppColors.gray200,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTypography.display1,
        displayMedium: AppTypography.display2,
        headlineLarge: AppTypography.heading1,
        headlineMedium: AppTypography.heading2,
        headlineSmall: AppTypography.heading3,
        titleLarge: AppTypography.heading4,
        bodyLarge: AppTypography.body1,
        bodyMedium: AppTypography.body2,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.button,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.black, size: 24),
    );
  }

  /// Dark Theme (Optional - Phase 2)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme - Apple Style Dark Mode
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkButtonDefault,
        onPrimary: AppColors.darkInvertedText,
        secondary: AppColors.gray300,
        onSecondary: AppColors.darkInvertedText,
        surface: AppColors.darkCardBackground,
        onSurface: AppColors.darkPrimaryText,
        error: AppColors.white,
        onError: AppColors.black,
        brightness: Brightness.dark,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.darkMainBackground,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkMainBackground,
        foregroundColor: AppColors.darkPrimaryText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.heading4,
        iconTheme: IconThemeData(color: AppColors.darkPrimaryText, size: 24),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCardBackground,
        selectedItemColor: AppColors.darkPrimaryText,
        unselectedItemColor: AppColors.darkSecondaryText,
        selectedLabelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: AppTypography.caption.copyWith(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.darkCardBackground,
        elevation: 2,
        shadowColor: AppColors.darkShadow8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.darkStandardBorder,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.darkStandardBorder,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.darkPrimaryText,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.white, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.white, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.darkButtonDisabled,
            width: 1.5,
          ),
        ),
        labelStyle: AppTypography.body2.copyWith(
          color: AppColors.darkSecondaryText,
        ),
        hintStyle: AppTypography.body2.copyWith(
          color: AppColors.darkPlaceholderText,
        ),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.white),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkButtonDefault,
          foregroundColor: AppColors.darkInvertedText,
          disabledBackgroundColor: AppColors.darkButtonDisabled,
          disabledForegroundColor: AppColors.darkButtonTextDisabled,
          elevation: 4,
          shadowColor: AppColors.darkShadow12,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimaryText,
          disabledForegroundColor: AppColors.darkButtonTextDisabled,
          side: const BorderSide(color: AppColors.darkPrimaryText, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimaryText,
          disabledForegroundColor: AppColors.darkButtonTextDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTypography.button.copyWith(fontWeight: FontWeight.w500),
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.darkPrimaryText,
          disabledForegroundColor: AppColors.darkButtonDisabled,
          minimumSize: const Size(44, 44),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCardBackground,
        elevation: 16,
        shadowColor: AppColors.darkShadow16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTypography.heading3.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        contentTextStyle: AppTypography.body1.copyWith(
          color: AppColors.darkSecondaryText,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkCardBackground,
        elevation: 16,
        shadowColor: AppColors.darkShadow16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkStandardBorder,
        deleteIconColor: AppColors.darkPrimaryText,
        disabledColor: AppColors.darkButtonDisabled,
        selectedColor: AppColors.darkPrimaryText,
        secondarySelectedColor: AppColors.gray300,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTypography.body2.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        secondaryLabelStyle: AppTypography.body2.copyWith(
          color: AppColors.darkInvertedText,
        ),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.darkPrimaryText,
        linearTrackColor: AppColors.darkStandardBorder,
        circularTrackColor: AppColors.darkStandardBorder,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.display1.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        displayMedium: AppTypography.display2.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        headlineLarge: AppTypography.heading1.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        headlineMedium: AppTypography.heading2.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        headlineSmall: AppTypography.heading3.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        titleLarge: AppTypography.heading4.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        bodyLarge: AppTypography.body1.copyWith(
          color: AppColors.darkSecondaryText,
        ),
        bodyMedium: AppTypography.body2.copyWith(
          color: AppColors.darkSecondaryText,
        ),
        bodySmall: AppTypography.caption.copyWith(
          color: AppColors.darkTertiaryText,
        ),
        labelLarge: AppTypography.button.copyWith(
          color: AppColors.darkPrimaryText,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.darkPrimaryText,
        size: 24,
      ),
    );
  }
}
