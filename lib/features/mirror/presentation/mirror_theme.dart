import 'package:flutter/material.dart';

import '../brand/mirror_brands.dart';

export '../brand/mirror_brands.dart'
    show MirrorBrand, MirrorBrandScope, kMirrorBrand;

/// Дизайн-токены Magic Mirror, собранные из активного бренда.
///
/// Читать через [MirrorTheme.of]. Имена полей сохранены от прежней
/// статической версии (`MirrorTheme.ink` → `t.ink`), розовый стал
/// [primary], серый — [muted]. Киоск всегда светлый: тёмная тема приложения
/// продавца сюда не протекает.
class MirrorTheme {
  const MirrorTheme(this.brand);

  final MirrorBrand brand;

  static MirrorTheme of(BuildContext context) =>
      MirrorTheme(MirrorBrandScope.of(context));

  // ── Цвета ──────────────────────────────────────────────────────────────────
  Color get bg => brand.palette.bg;
  Color get surface => brand.palette.surface;
  Color get ink => brand.palette.ink;
  Color get muted => brand.palette.muted;
  Color get hairline => brand.palette.hairline;
  Color get primary => brand.palette.primary;
  Color get primaryDeep => brand.palette.primaryDeep;
  Color get primaryBright => brand.palette.primaryBright;
  Color get onPrimary => brand.palette.onPrimary;
  Color get selectedBg => brand.palette.selectedBg;
  Color get accent => brand.palette.accent;
  Color get danger => brand.palette.danger;
  Color get success => brand.palette.success;

  /// Дуотон для полноцветных иллюстраций (силуэт примерки нарисован розовым):
  /// яркость пикселя раскладывается между [primaryDeep] и светлым оттенком
  /// [primary], объём и тени сохраняются, альфа не трогается.
  ColorFilter get figureDuotone {
    final dark = primaryDeep;
    final light = Color.lerp(primary, const Color(0xFFFFFFFF), 0.86)!;
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final kr = light.r - dark.r;
    final kg = light.g - dark.g;
    final kb = light.b - dark.b;
    return ColorFilter.matrix(<double>[
      lr * kr, lg * kr, lb * kr, 0, dark.r * 255, //
      lr * kg, lg * kg, lb * kg, 0, dark.g * 255, //
      lr * kb, lg * kb, lb * kb, 0, dark.b * 255, //
      0, 0, 0, 1, 0,
    ]);
  }

  // ── Радиусы ────────────────────────────────────────────────────────────────
  double get rButton => brand.shape.button;
  double get rCard => brand.shape.card;
  double get rChip => brand.shape.chip;
  double get rImage => brand.shape.image;

  /// Единый масштаб киоска: телефон ≈ 1.0, портретный iPad ≈ 2.0.
  /// Никакого веб-скейла под 1080×1920 — только относительные размеры.
  static double scale(BuildContext context) =>
      (MediaQuery.sizeOf(context).shortestSide / 400).clamp(1.0, 2.0);

  /// Сетка каталога/стилей: 2 колонки на телефоне, 3 на планшете.
  static int gridColumns(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900 ? 3 : 2;

  // ── Типографика ────────────────────────────────────────────────────────────

  String get _ui => brand.type.uiFamily;

  /// Крупный акцидентный заголовок серифом бренда. Вес задаётся осью `wght`
  /// переменного шрифта; fontWeight остаётся w400, иначе движок дорисует
  /// «фальшивый» болд поверх единственного файла.
  TextStyle display(double size, {Color? color}) => TextStyle(
        fontFamily: brand.type.displayFamily,
        fontFamilyFallback: brand.type.fallbackFamilies,
        fontWeight: FontWeight.w400,
        fontVariations: [FontVariation('wght', brand.type.displayWeight)],
        fontSize: size,
        letterSpacing: size * brand.type.displayTracking,
        height: brand.type.displayHeight,
        color: color ?? primaryDeep,
      );

  /// Заголовок экрана — тот же сериф, легче и чернилами.
  TextStyle headline(double size, {Color? color}) => TextStyle(
        fontFamily: brand.type.displayFamily,
        fontFamilyFallback: brand.type.fallbackFamilies,
        fontWeight: FontWeight.w400,
        fontVariations: [FontVariation('wght', brand.type.headlineWeight)],
        fontSize: size,
        letterSpacing: size * brand.type.displayTracking,
        height: 1.1,
        color: color ?? ink,
      );

  /// Кикер — мелкая подпись над заголовком, капсом с разрядкой.
  /// Цвет по умолчанию — [primaryBright]: он контрастнее на светлом фоне
  /// в мелком кегле.
  TextStyle kicker(double s, {Color? color}) => TextStyle(
        fontFamily: _ui,
        fontSize: 12 * s,
        fontWeight: FontWeight.w700,
        letterSpacing: 12 * s * 0.18,
        color: color ?? primaryBright,
        height: 1.0,
      );

  TextStyle subtitle(double size, {Color? color}) => TextStyle(
        fontFamily: _ui,
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? muted,
        height: 1.5,
      );

  TextStyle label(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: _ui,
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
        height: 1.1,
      );

  /// Подпись CTA: с разрядкой, если бренд ставит кнопки капсом.
  TextStyle cta(double size, {Color? color}) => TextStyle(
        fontFamily: _ui,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: brand.type.ctaUppercase ? size * 0.06 : 0,
        color: color ?? onPrimary,
        height: 1.1,
      );

  /// Цена: табличные цифры, чтобы суммы в списке стояли ровно.
  TextStyle price(double size, {Color? color}) => TextStyle(
        fontFamily: _ui,
        fontSize: size,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? ink,
        height: 1.1,
      );

  /// Технический код (причина сбоя) — нарочно невзрачный.
  TextStyle mono(double size, {Color? color}) => TextStyle(
        fontFamily: 'Courier',
        fontSize: size,
        color: color ?? muted,
        height: 1.3,
      );

  /// Регистр текста по правилам бренда.
  String kickerCase(String text) =>
      brand.type.kickerUppercase ? text.toUpperCase() : text;

  String ctaCase(String text) =>
      brand.type.ctaUppercase ? text.toUpperCase() : text;
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
