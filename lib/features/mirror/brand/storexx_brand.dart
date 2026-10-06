import 'dart:ui' show Color, FontWeight;

import 'mirror_brand.dart';

/// Storexx — двухэтажный мультибрендовый магазин европейских марок для всей
/// семьи (Ташкент, Амира Темура, 60; «family meets fashion»). Фирменный язык
/// магазина — мрамор с прожилками, засечный знак STORE над боксом «XX»,
/// редакционная фотография. Отсюда скин: мрамор вместо студии, рама зеркала —
/// прямоугольная витрина с двойной линией, как бокс в знаке, заголовки
/// классической антиквой Forum под римские капители логотипа, ни одного
/// цветного акцента (аудитория — 65/35 женщины/мужчины).
///
/// Две версии: основная светлая — белый мрамор, чёрные линии и кнопки;
/// тёмная — чёрный мрамор из презентации магазина, белые линии и кнопки.
/// Переключаются кнопкой на постере ([MirrorBrand.variantId]).
///
/// Логотип и кадры постера — из презентации магазина; кадры — рекламные
/// съёмки марок, которые Storexx сам показывает в своих материалах. Для
/// витрины взяты только «дорогие» кадры: пальто, костюмы, редакционная
/// съёмка; семейный снимок на белом и кадры в кедах не держат уровень
/// цен зала, кадр Marc O'Polo с Жизель несёт чужой логотип.
///
/// Камень лежит под всеми экранами киоска, не только под постером, —
/// одна стена от входа до талона.
const MirrorBrand storexxBrand = MirrorBrand(
  id: 'storexx',
  variantId: 'storexx_dark',
  name: 'Storexx',
  wordmark: 'STORE XX',
  logoAsset: _logo,
  logoHeightScale: 1.9,
  logoMonochrome: true,
  wordmarkStyle: _wordmark,
  backdropAsset: 'assets/brands/storexx/marble_light.webp',
  backdropVeil: 0.3,
  tagline: {
    'ru': 'Мрамор и витрина мировых брендов',
    'uz': 'Marmar va jahon brendlari vitrinasi',
    'en': 'Marble and a window of world brands',
  },
  languages: ['ru', 'uz', 'en'],
  defaultLang: 'ru',
  palette: MirrorPalette(
    bg: Color(0xFFF7F6F4),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF111111),
    muted: Color(0xFF76726D),
    hairline: Color(0xFFE3E0DB),
    primary: Color(0xFF111111),
    primaryDeep: Color(0xFF111111),
    primaryBright: Color(0xFF4A4744),
    onPrimary: Color(0xFFFFFFFF),
    selectedBg: Color(0xFFEDEBE7),
    accent: Color(0xFF6E6862),
    danger: Color(0xFFD93F3F),
    success: Color(0xFF2E7D52),
    // Свечения — серый прожилок: чёрный ореол выглядел бы грязной тенью.
    glow: Color(0xFFA8A39C),
  ),
  type: _type,
  shape: _shape,
  windowCover: MirrorWindowCover(
    backdropAsset: 'assets/brands/storexx/marble_light.webp',
    slides: _slides,
    kicker: _kicker,
    headline: _headline,
    marquee: _marquee,
    bg: Color(0xFFF4F3F0),
    text: Color(0xFF111111),
    textMuted: Color(0xFF6E6A65),
    frame: Color(0xFF111111),
    glow: Color(0xFF8F8A84),
    cta: Color(0xFF111111),
    onCta: Color(0xFFFFFFFF),
  ),
);

/// Тёмная версия: чёрный мрамор из презентации магазина.
const MirrorBrand storexxDarkBrand = MirrorBrand(
  id: 'storexx_dark',
  baseId: 'storexx',
  variantId: 'storexx',
  name: 'Storexx',
  wordmark: 'STORE XX',
  logoAsset: _logo,
  logoHeightScale: 1.9,
  logoMonochrome: true,
  wordmarkStyle: _wordmark,
  backdropAsset: 'assets/brands/storexx/marble.webp',
  backdropVeil: 0.58,
  tagline: {
    'ru': 'Чёрный мрамор и витрина мировых брендов',
    'uz': 'Qora marmar va jahon brendlari vitrinasi',
    'en': 'Black marble and a window of world brands',
  },
  languages: ['ru', 'uz', 'en'],
  defaultLang: 'ru',
  palette: MirrorPalette(
    bg: Color(0xFF0F0F0F),
    surface: Color(0xFF1B1B1B),
    ink: Color(0xFFF4F2EE),
    muted: Color(0xFF9C9893),
    hairline: Color(0xFF2E2E2E),
    // Действие — белое на чёрном: кнопки, выбор, рама, бейджи.
    primary: Color(0xFFF4F2EE),
    primaryDeep: Color(0xFFFFFFFF),
    // Мелкие подписи (кикеры) — светло-серый прожилок, не чистый белый.
    primaryBright: Color(0xFFBFB9B2),
    onPrimary: Color(0xFF0F0F0F),
    selectedBg: Color(0xFF262626),
    accent: Color(0xFFBDB3AA),
    danger: Color(0xFFE5484D),
    success: Color(0xFF6FBF8A),
    glow: Color(0xFFBDB3AA),
  ),
  type: _type,
  shape: _shape,
  windowCover: MirrorWindowCover(
    backdropAsset: 'assets/brands/storexx/marble.webp',
    slides: _slides,
    kicker: _kicker,
    headline: _headline,
    marquee: _marquee,
    bg: Color(0xFF0B0B0B),
    text: Color(0xFFF4F2EE),
    textMuted: Color(0xFF9C9893),
    frame: Color(0xFFF4F2EE),
    glow: Color(0xFFBDB3AA),
    cta: Color(0xFFF4F2EE),
    onCta: Color(0xFF0F0F0F),
  ),
);

const _logo = 'assets/brands/storexx/logo.png';

// Запасной словесный знак, если файл логотипа недоступен.
const _wordmark = MirrorWordmarkStyle(
  family: 'Forum',
  weight: FontWeight.w400,
  tracking: 0.14,
);

const _type = MirrorType(
  displayFamily: 'Forum',
  uiFamily: 'GolosText',
  displayWeight: 400,
  headlineWeight: 400,
  displayTracking: 0.01,
  displayHeight: 1.05,
  kickerUppercase: true,
  ctaUppercase: true,
  // У Forum нет узбекского «ʻ» — берём его из Playfair Display.
  fallbackFamilies: ['PlayfairDisplay'],
);

const _shape = MirrorShape(
  button: 2,
  card: 6,
  chip: 2,
  image: 4,
  mirror: MirrorArchShape.window,
);

// Пальто кэмел · редакционная съёмка · два пальто · пальто на улице ·
// синие костюмы. Все кадры 2:3 под пропорцию витрины.
const _slides = [
  'assets/brands/storexx/window_1.webp',
  'assets/brands/storexx/window_2.webp',
  'assets/brands/storexx/window_3.webp',
  'assets/brands/storexx/window_4.webp',
  'assets/brands/storexx/window_5.webp',
];

const _kicker = {
  'ru': '#ВИРТУАЛЬНАЯ ПРИМЕРКА',
  'uz': '#VIRTUAL KIYIB KOʻRISH',
  'en': '#VIRTUAL FITTING',
};

const _headline = {
  'ru': 'Ваш образ\nиз мировых брендов',
  'uz': 'Jahon brendlaridan\nsizning obrazingiz',
  'en': 'Your look\nfrom world brands',
};

// Марки одежды с сайта storexx.uz плюс BOSS и Boggi со второго этажа
// (по презентации 2026 года).
const _marquee = [
  'BOSS',
  'Boggi Milano',
  'Marc O’Polo',
  'Karl Lagerfeld',
  'Mexx',
  'Digel',
  'Jack & Jones',
  'Selected',
  'Only',
  'Vero Moda',
  'Motivi',
  'Colin’s',
  'Name It',
  'Only & Sons',
  'Pieces',
  'Y.A.S',
];
