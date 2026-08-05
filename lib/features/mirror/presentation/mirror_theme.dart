import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

/// Дизайн-токены Magic Mirror: редакционный «дрескод»-язык поверх IntroPalette.
/// Киоск всегда светлый (постер — чернильный, внутренние экраны — белые);
/// тёмная тема приложения сюда не протекает. Розовый — только для кикеров,
/// выбора и CTA; всё остальное — чёрное на белом.
class MirrorTheme {
  MirrorTheme._();

  static const Color ink = IntroPalette.ink;
  static const Color pink = IntroPalette.pink;
  static const Color gray = IntroPalette.gray;
  static const Color hairline = Color(0xFFEFEDF3);
  static const Color surface = Color(0xFFF8F7FA);
  static const Color lavender = Color(0xFFF1EEF5);
  static const Color selectedBg = IntroPalette.gemChipBg;
  static const Color freeGreen = IntroPalette.freeGreen;

  /// Единый масштаб киоска: телефон ≈ 1.0, портретный iPad ≈ 2.0.
  /// Никакого веб-скейла под 1080×1920 — только относительные размеры.
  static double scale(BuildContext context) =>
      (MediaQuery.sizeOf(context).shortestSide / 400).clamp(1.0, 2.0);

  /// Сетка каталога/стилей: 2 колонки на телефоне, 3 на планшете.
  static int gridColumns(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900 ? 3 : 2;

  static TextStyle kicker(double s, {Color color = pink}) => TextStyle(
        fontFamily: IntroPalette.fontFamily,
        fontSize: 12 * s,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.4 * s,
        color: color,
        height: 1.0,
      );

  static TextStyle headline(double size, {Color color = ink}) => TextStyle(
        fontFamily: IntroPalette.fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: size * -0.025,
        color: color,
        height: 1.08,
      );

  static TextStyle subtitle(double size, {Color color = gray}) => TextStyle(
        fontFamily: IntroPalette.fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      );

  static TextStyle label(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color color = ink,
  }) =>
      TextStyle(
        fontFamily: IntroPalette.fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.1,
      );
}

/// Лёгкий каскадный вход: подъём + проявление. Свой, а не intro-`Entrance`,
/// чтобы экранам киоска не требовался общий entrance-контроллер.
/// Уважает MediaQuery.disableAnimations.
class MirrorFadeIn extends StatelessWidget {
  const MirrorFadeIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.durationMs = 450,
    this.rise = 18,
  });

  final Widget child;
  final int delayMs;
  final int durationMs;
  final double rise;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: delayMs + durationMs),
      curve: Interval(
        delayMs / (delayMs + durationMs),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, rise * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
