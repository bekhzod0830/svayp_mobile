import 'dart:ui' show Color;

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
  heroVideoAsset: null,
  languages: ['ru', 'uz'],
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
  // Нейтральные фразы: зарегистрированные слоганы Lacoste не используем без
  // текста от партнёра.
  coverPhrases: {
    'ru': [
      'Увидьте себя в новом образе.',
      'Ваш образ — за 30 секунд.',
      'Собрано из того, что есть в зале.',
    ],
    'uz': [
      'Oʻzingizni yangi uslubda koʻring.',
      'Uslubingiz — 30 soniyada.',
      'Zaldagi kiyimlardan yigʻilgan.',
    ],
  },
  styleLabels: {
    'CLASSIC': {'ru': 'Классика', 'uz': 'Klassika'},
    'CASUAL': {'ru': 'Уикенд', 'uz': 'Dam olish'},
    'OFFICE_SMART': {'ru': 'Смарт', 'uz': 'Smart'},
    'SPORTY': {'ru': 'Спорт · Теннис', 'uz': 'Sport · Tennis'},
  },
  hiddenStyles: {'MODEST_CHIC', 'EVENING'},
  categoryLabels: {
    'TOPWEAR': {'ru': 'Поло и верх', 'uz': 'Polo va yuqori kiyim'},
    'BOTTOMWEAR': {'ru': 'Брюки и шорты', 'uz': 'Shim va shortilar'},
    'OUTERWEAR': {'ru': 'Куртки и пальто', 'uz': 'Kurtka va paltolar'},
  },
);
