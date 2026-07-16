import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

/// Shared input styling so the registration/auth flow matches the intro
/// carousel: soft lavender-grey fill, no hard border, brand-pink focus ring,
/// Golos Text throughout.
class IntroInputs {
  IntroInputs._();

  /// Text entered into fields.
  static const TextStyle field = TextStyle(
    fontFamily: IntroPalette.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: IntroPalette.ink,
  );

  /// Field labels above inputs.
  static const TextStyle label = TextStyle(
    fontFamily: IntroPalette.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: IntroPalette.ink,
  );

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: width == 0
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );

  static InputDecoration decoration({
    String? hint,
    String? errorText,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: IntroPalette.fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: IntroPalette.gray,
      ),
      errorText: errorText,
      errorStyle: const TextStyle(
        fontFamily: IntroPalette.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: IntroPalette.chipBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints,
      suffixIcon: suffixIcon,
      border: _border(Colors.transparent, 0),
      enabledBorder: _border(Colors.transparent, 0),
      focusedBorder: _border(IntroPalette.gem, 1.8),
      errorBorder: _border(const Color(0xFFE5484D), 1.5),
      focusedErrorBorder: _border(const Color(0xFFE5484D), 1.8),
    );
  }
}
