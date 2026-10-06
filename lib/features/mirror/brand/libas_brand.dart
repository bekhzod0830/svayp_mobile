import 'dart:ui' show Color, FontWeight;

import 'mirror_brand.dart';

/// LIBAS: монохромный стиль для покупателей любого пола — чёрный, белый и
/// нейтральные серые. Цвет бренда остаётся только в «Λ» знака: розовые
/// кнопки и выбор читались как «только для женщин», а бронзовые акценты — как
/// шаблонная «премиальность». Golos Text ExtraBold в заголовках, скруглённые
/// формы.
///
/// Постер — видео с примерочным зеркалом в арке (см. [MirrorVideoCover]).
const MirrorBrand libasBrand = MirrorBrand(
  id: 'libas',
  name: 'LIBAS',
  wordmark: 'LIBΛS',
  // Знак набран ровно как на экране входа: системный шрифт w700, плотный
  // трекинг, «Λ» — фирменным цветом. Это единственный цветной элемент скина.
  wordmarkStyle: MirrorWordmarkStyle(
    weight: FontWeight.w700,
    tracking: -1 / 48,
    accentIndex: 3,
    accentColor: Color(0xFFF370A7),
  ),
  tagline: {
    'ru': 'Чёрно-белая классика и видео в зеркале',
    'uz': 'Qora-oq klassika va oynadagi video',
    'en': 'Black-and-white classic and a video in the mirror',
  },
  languages: ['ru', 'uz', 'en'],
  defaultLang: 'ru',
  palette: MirrorPalette(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5),
    ink: Color(0xFF121212),
    muted: Color(0xFF878787),
    hairline: Color(0xFFE8E8E8),
    primary: Color(0xFF121212),
    primaryDeep: Color(0xFF121212),
    primaryBright: Color(0xFF121212),
    onPrimary: Color(0xFFFFFFFF),
    selectedBg: Color(0xFFEFEFEF),
    accent: Color(0xFF555555),
    danger: Color(0xFFD93F3F),
    success: Color(0xFF2E7D52),
    primaryGradient: [Color(0xFF333333), Color(0xFF121212)],
    // Свечения — нейтральный светло-серый: чёрный ореол выглядел бы грязной
    // тенью.
    glow: Color(0xFFBDBDBD),
  ),
  type: MirrorType(
    displayFamily: 'GolosText',
    uiFamily: 'GolosText',
    displayVariable: false,
    displayWeight: 800,
    headlineWeight: 800,
    displayTracking: -0.025,
    displayHeight: 1.08,
    kickerUppercase: true,
    ctaUppercase: false,
    // У Golos Text нет узбекского «ʻ» — берём его из серифа.
    fallbackFamilies: ['PlayfairDisplay'],
  ),
  shape: MirrorShape(button: 999, card: 20, chip: 999, image: 14),
  videoCover: MirrorVideoCover(
    asset: 'lib/video/kiosk_poster/poster_video.mp4',
    aspect: 688 / 1024,
    posterAsset: 'assets/brands/libas/cover_poster.webp',
    // Верх кадра срезан: там водяной знак генератора видео.
    zoom: 1.1,
    bgTop: Color(0xFFFFFFFF),
    bgBottom: Color(0xFFF0F0F0),
    glow: Color(0xFFBDBDBD),
    rim: Color(0xFFD6D6D6),
    text: Color(0xFF121212),
    textMuted: Color(0xFF878787),
    cta: Color(0xFF121212),
    onCta: Color(0xFFFFFFFF),
    ctaGradient: [Color(0xFF333333), Color(0xFF121212)],
  ),
);
