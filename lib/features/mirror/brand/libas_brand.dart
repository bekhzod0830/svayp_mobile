import 'dart:ui' show Color, FontWeight;

import 'mirror_brand.dart';

/// LIBAS: собственный стиль приложения — белый фон, чернильный текст,
/// фирменный розовый для выбора и CTA (градиентная пилюля, как в онбординге),
/// Golos Text ExtraBold в заголовках, скруглённые формы. Значения — из
/// `IntroPalette` (дек «LIBAS Онбординг»), продублированы здесь, чтобы бренд
/// киоска оставался константой без зависимостей от онбординга.
///
/// Постер — видео с примерочным зеркалом в арке (см. [MirrorVideoCover]).
const MirrorBrand libasBrand = MirrorBrand(
  id: 'libas',
  name: 'LIBAS',
  wordmark: 'LIBΛS',
  // Знак набран ровно как на экране входа: системный шрифт w700, плотный
  // трекинг, розовая «Λ».
  wordmarkStyle: MirrorWordmarkStyle(
    weight: FontWeight.w700,
    tracking: -1 / 48,
    accentIndex: 3,
    accentColor: Color(0xFFF370A7),
  ),
  tagline: {
    'ru': 'Фирменный розовый и видео в зеркале',
    'uz': 'Firma pushti rangi va oynadagi video',
    'en': 'Signature pink and a video in the mirror',
  },
  languages: ['ru', 'uz', 'en'],
  defaultLang: 'ru',
  palette: MirrorPalette(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF8F7FA),
    ink: Color(0xFF141118),
    muted: Color(0xFF8A8690),
    hairline: Color(0xFFEFEDF3),
    primary: Color(0xFFE32B86),
    primaryDeep: Color(0xFF141118),
    // Розовый мельче 16 px — темнее основного, чтобы читался на белом.
    primaryBright: Color(0xFFC81E74),
    onPrimary: Color(0xFFFFFFFF),
    selectedBg: Color(0xFFFDEBF3),
    accent: Color(0xFF8A5A16),
    danger: Color(0xFFE5484D),
    success: Color(0xFF2E7D52),
    primaryGradient: [Color(0xFFF65BA5), Color(0xFFE32B86)],
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
    bgTop: Color(0xFFFFFAFC),
    bgBottom: Color(0xFFF8E2EE),
    glow: Color(0xFFF370A7),
    rim: Color(0xFFF65BA5),
    text: Color(0xFF141118),
    textMuted: Color(0xFF8A8690),
    headlineAccent: Color(0xFFE32B86),
    cta: Color(0xFFE32B86),
    onCta: Color(0xFFFFFFFF),
    ctaGradient: [Color(0xFFF65BA5), Color(0xFFE32B86)],
  ),
);
