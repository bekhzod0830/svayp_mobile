import 'dart:ui' show Color, Offset;

import 'mirror_brand.dart';

/// Lacoste: наследный серифный заголовок, три фирменных зелёных, фон
/// «farine» (кремовый первого блейзера Рене Лакоста), глиняный акцент
/// («clay» — грунт кортов), красный язычок крокодила — только точкой.
/// Углы почти прямые, кикеры капсом с разрядкой, много воздуха.
///
/// Логотип — товарный знак партнёра: файл кладётся в `assets/brands/lacoste/`
/// только с его ведома; до этого знак рисуется серифом как текст.
const MirrorBrand lacosteBrand = MirrorBrand(
  id: 'lacoste',
  name: 'Lacoste',
  wordmark: 'LACOSTE',
  logoAsset: null,
  // Словесный знак Lacoste — гротеск, не сериф.
  wordmarkStyle: MirrorWordmarkStyle(family: 'GolosText', tracking: 0.07),
  tagline: {
    'ru': 'Зелёная студия и модель в образе',
    'uz': 'Yashil studiya va obrazdagi model',
    'en': 'Green studio and a styled model',
  },
  languages: ['ru', 'uz', 'en'],
  defaultLang: 'ru',
  palette: MirrorPalette(
    bg: Color(0xFFF4EFE6),
    surface: Color(0xFFFBF8F2),
    ink: Color(0xFF111111),
    muted: Color(0xFF5C5C5C),
    hairline: Color(0xFFE4DED2),
    primary: Color(0xFF004526),
    primaryDeep: Color(0xFF003B20),
    primaryBright: Color(0xFF00693E),
    onPrimary: Color(0xFFF4EFE6),
    selectedBg: Color(0xFFE8EFE9),
    accent: Color(0xFFC4623A),
    danger: Color(0xFFDB0026),
    success: Color(0xFF004526),
  ),
  type: MirrorType(
    displayFamily: 'PlayfairDisplay',
    uiFamily: 'GolosText',
    displayWeight: 600,
    headlineWeight: 500,
    displayTracking: -0.01,
    displayHeight: 1.05,
    kickerUppercase: true,
    ctaUppercase: true,
  ),
  shape: MirrorShape(button: 4, card: 10, chip: 4, image: 6),
  // Постер по макету: модель в поло и плиссированной юбке на зелёной
  // студийной сцене, две карточки вещей с линиями к ним. Координаты сняты с
  // макета 941×1672 и пересчитаны в доли бокса модели (399×1022).
  coverHero: MirrorCoverHero(
    modelAsset: 'assets/brands/lacoste/cover_model.webp',
    modelAspect: 399 / 1022,
    pieces: [
      MirrorCoverPiece(
        asset: 'assets/brands/lacoste/cover_polo.webp',
        label: {'ru': 'Поло', 'uz': 'Polo', 'en': 'Polo'},
        card: Offset(-0.361, 0.229),
        target: Offset(0.105, 0.2495),
        fromLeft: true,
      ),
      MirrorCoverPiece(
        asset: 'assets/brands/lacoste/cover_skirt.webp',
        label: {'ru': 'Юбка', 'uz': 'Yubka', 'en': 'Skirt'},
        card: Offset(1.2155, 0.4843),
        target: Offset(0.714, 0.489),
        fromLeft: false,
        // На макете линия выходит из верхней трети карточки и спускается
        // к юбке дугой.
        anchor: 0.38,
      ),
    ],
    wall: Color(0xFF1A3724),
    wallLight: Color(0xFF2B4632),
    wallDeep: Color(0xFF11291B),
    floor: Color(0xFF2C4733),
    podium: Color(0xFF4E6A4C),
    podiumTop: Color(0xFF687957),
    ring: Color(0xFF8D9C76),
    glass: Color(0xFF334B3A),
    card: Color(0xFFE6DECE),
    onCard: Color(0xFF1B2A20),
    text: Color(0xFFEFE4D1),
    textMuted: Color(0xFF9BA49B),
    cta: Color(0xFFDAF69E),
    onCta: Color(0xFF10261A),
  ),
  styleLabels: {
    'CLASSIC': {'ru': 'Классика', 'uz': 'Klassika', 'en': 'Classic'},
    'CASUAL': {'ru': 'Уикенд', 'uz': 'Dam olish', 'en': 'Weekend'},
    'OFFICE_SMART': {'ru': 'Смарт', 'uz': 'Smart', 'en': 'Smart'},
    'SPORTY': {'ru': 'Спорт · Теннис', 'uz': 'Sport · Tennis', 'en': 'Sport · Tennis'},
  },
  hiddenStyles: {'MODEST_CHIC', 'EVENING'},
  categoryLabels: {
    'TOPWEAR': {
      'ru': 'Поло и верх',
      'uz': 'Polo va yuqori kiyim',
      'en': 'Polos and tops',
    },
    'BOTTOMWEAR': {
      'ru': 'Брюки и шорты',
      'uz': 'Shim va shortilar',
      'en': 'Trousers and shorts',
    },
    'OUTERWEAR': {
      'ru': 'Куртки и пальто',
      'uz': 'Kurtka va paltolar',
      'en': 'Jackets and coats',
    },
  },
);
