import 'package:flutter/material.dart';

/// Visual constants for the pre-auth intro carousel, lifted verbatim from the
/// "LIBAS Онбординг" design deck. The carousel is brand marketing and is
/// always rendered light, regardless of the app theme — do not swap these for
/// AppColors tokens.
class IntroPalette {
  IntroPalette._();

  // ── Core colors ────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFFFFFFF);
  static const Color lavender = Color(0xFFE9E7EE);
  static const Color pink = Color(0xFFE32B86);
  static const Color pinkLight = Color(0xFFF65BA5);
  static const Color ink = Color(0xFF141118);
  static const Color gray = Color(0xFF8A8690);
  static const Color dotInactive = Color(0xFFDAD4E0);
  static const Color chipBg = Color(0xFFF4F3F6);
  static const Color amber = Color(0xFFE0A337);
  static const Color goldText = Color(0xFF8A5A16);
  static const Color goldBg = Color(0xFFFBF3E2);
  static const Color goldBorder = Color(0xFFF0DFB8);
  static const Color freeGreen = Color(0xFF2E7D52);
  static const Color freeGreenBg = Color(0xFFE7F3EC);

  // ── Brand diamond (the in-app currency), brand pink #F370A7 ──────────────
  static const Color gem = Color(0xFFF370A7);
  static const Color gemLight = Color(0xFFF9A9CB);
  static const Color gemDeep = Color(0xFFC94E86);
  static const Color gemText = Color(0xFFB03A72);
  static const Color gemChipBg = Color(0xFFFDEBF3);
  static const Color gemChipBorder = Color(0xFFF8D3E4);

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// Primary CTA / active-dot gradient (deck: 135deg #F65BA5 → #E32B86).
  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pinkLight, pink],
  );

  /// Gift-number gradient (deck: 160deg #F4C662 → #E0A337 55% → #C6871F).
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF4C662), Color(0xFFE0A337), Color(0xFFC6871F)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Gem-diamond gradient (light table → brand gem → deep pavilion).
  static const LinearGradient diamondGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gemLight, gem, gemDeep],
    stops: [0.0, 0.5, 1.0],
  );

  // Stage backgrounds (deck: 170deg — nearly vertical).
  static const LinearGradient stagePink = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDEDF4), Color(0xFFF8E2EE)],
  );
  static const LinearGradient stagePinkDeep = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDEDF4), Color(0xFFF7E1ED)],
  );
  static const LinearGradient stageNeutral = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5F3F8), Color(0xFFEFEDF4)],
  );
  static const LinearGradient stageGold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBF3E2), Color(0xFFF8ECCF)],
  );
  static const LinearGradient stageGoldWarm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBF3E2), Color(0xFFF7EACB)],
  );
  // Light-pink stages for the diamond / gift slides.
  static const LinearGradient stageGem = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDEDF5), Color(0xFFF8E1EC)],
  );
  static const LinearGradient stageGemWarm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFCEAF2), Color(0xFFF6DCE8)],
  );

  // ── Typography (bundled Golos Text) ────────────────────────────────────────
  static const String fontFamily = 'GolosText';

  /// Small uppercase section label above the headline.
  static const TextStyle kicker = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.4, // .2em of 12px
    color: pink,
    height: 1.0,
  );

  static TextStyle headline({double size = 32}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: size * -0.025,
        color: ink,
        height: 1.1,
      );

  static TextStyle subtitle({double size = 16}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: gray,
        height: 1.5,
      );

  /// Bold label used on cards/chips inside scenes.
  static TextStyle label({
    double size = 14,
    FontWeight weight = FontWeight.w800,
    Color color = ink,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.0,
      );
}
