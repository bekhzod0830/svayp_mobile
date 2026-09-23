/// Словари киоска: коды уходят на бэкенд, подписи показываются человеку.
/// Портировано из `swipe-web/lib/kiosk-i18n.ts` (KIOSK_STYLES / KIOSK_SHAPES /
/// KIOSK_CATEGORIES). Не в ARB сознательно: это бэкенд-enum'ы с зависящими от
/// пола списками. Языки покупателя — RU, UZ и EN.
library;

class KioskLabeled {
  final String? code;
  final String ru;
  final String uz;

  /// Английская подпись; без неё — русская.
  final String? en;

  const KioskLabeled(this.code, this.ru, this.uz, [this.en]);

  String label(String langCode) => switch (langCode) {
        'uz' => uz,
        'en' => en ?? ru,
        _ => ru,
      };
}

/// Стили с экрана выбора (ветка «создать»).
const List<KioskLabeled> kioskStyles = [
  KioskLabeled('CLASSIC', 'Классика', 'Klassika', 'Classic'),
  KioskLabeled('CASUAL', 'Кэжуал', 'Kundalik', 'Casual'),
  KioskLabeled('MODEST_CHIC', 'Модест', 'Modest', 'Modest'),
  KioskLabeled('EVENING', 'Вечерний', 'Kechki', 'Evening'),
  KioskLabeled('OFFICE_SMART', 'Деловой', 'Ishbop', 'Office'),
  KioskLabeled('SPORTY', 'Спорт-шик', 'Sport-shik', 'Sport chic'),
];

/// Фильтры каталога. `code == null` — «Все»; остальные совпадают с enum
/// Category на бэкенде. Бельё и домашнее не выносим: в образ они не идут.
const List<KioskLabeled> kioskCategories = [
  KioskLabeled(null, 'Все', 'Hammasi', 'All'),
  KioskLabeled('TOPWEAR', 'Верх', 'Yuqori', 'Tops'),
  KioskLabeled('BOTTOMWEAR', 'Низ', 'Pastki', 'Bottoms'),
  KioskLabeled('DRESSES', 'Платья', 'Koʻylaklar', 'Dresses'),
  KioskLabeled('TWO_PIECE_SET', 'Комплекты', 'Toʻplamlar', 'Sets'),
  KioskLabeled('OUTERWEAR', 'Верхняя', 'Ustki kiyim', 'Outerwear'),
  KioskLabeled('FOOTWEAR', 'Обувь', 'Poyabzal', 'Shoes'),
  KioskLabeled('ACCESSORIES', 'Аксессуары', 'Aksessuarlar', 'Accessories'),
];

/// Типы фигуры по полу. Вариант «не знаю» (UNKNOWN) добавляется на экране
/// всегда, отдельно от этих списков.
const Map<String, List<KioskLabeled>> kioskShapes = {
  'FEMALE': [
    KioskLabeled('HOURGLASS', 'Песочные часы', 'Qum soati', 'Hourglass'),
    KioskLabeled('PEAR', 'Груша', 'Nok', 'Pear'),
    KioskLabeled('APPLE', 'Яблоко', 'Olma', 'Apple'),
    KioskLabeled('RECTANGLE', 'Прямоугольник', 'Toʻgʻri toʻrtburchak', 'Rectangle'),
    KioskLabeled('INVERTED_TRIANGLE', 'Перевёрнутый', 'Teskari uchburchak', 'Inverted triangle'),
  ],
  'MALE': [
    KioskLabeled('RECTANGLE', 'Прямоугольник', 'Toʻgʻri toʻrtburchak', 'Rectangle'),
    KioskLabeled(
      'INVERTED_TRIANGLE',
      'Перевёрнутый треугольник',
      'Teskari uchburchak',
      'Inverted triangle',
    ),
    KioskLabeled('TRIANGLE', 'Треугольник', 'Uchburchak', 'Triangle'),
    KioskLabeled('OVAL', 'Овал', 'Oval', 'Oval'),
  ],
};

/// Код «не знаю» для типа фигуры.
const String kioskShapeUnknown = 'UNKNOWN';

/// Силуэты женских фигур из уже забандленных ассетов; мужские — текстовые
/// карточки (паритет с веб-киоском).
const Map<String, String> kioskFemaleShapeAssets = {
  'HOURGLASS': 'lib/img/body_type/Hourglass.png',
  'PEAR': 'lib/img/body_type/Triangle.png',
  'APPLE': 'lib/img/body_type/Oval.png',
  'RECTANGLE': 'lib/img/body_type/Rectangle.png',
  'INVERTED_TRIANGLE': 'lib/img/body_type/Heart.png',
};

/// Слот вещи в образе — та же логика, что на бэкенде, огрублённая до
/// категорий. Общая для демо-сборки образа и «образов момента» на постере.
String kioskSlotOf(String? category) {
  switch (category) {
    case 'TOPWEAR':
      return 'TOP';
    case 'BOTTOMWEAR':
      return 'BOTTOM';
    case 'DRESSES':
    case 'ONE_PIECE':
    case 'TWO_PIECE_SET':
      return 'FULL';
    case 'FOOTWEAR':
      return 'SHOES';
    default:
      return 'OTHER';
  }
}

/// Цена как на ценниках в зале: «1 250 000 сум» / «1 250 000 soʻm».
/// Рукописная группировка по 3 разряда — intl.NumberFormat зависит от локали
/// и не гарантирует ровно такой вид.
String kioskMoney(int value, String langCode) {
  final unit = switch (langCode) {
    'uz' => 'soʻm',
    'en' => 'UZS',
    _ => 'сум',
  };
  return '${kioskMoneyShort(value)} $unit';
}

/// Сумма без валюты, с разбивкой по тысячам — для тесных ярлыков, где
/// валюта уже видна рядом (итог образа).
String kioskMoneyShort(int value) {
  final digits = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  final sign = value < 0 ? '−' : '';
  return '$sign$buf';
}

/// Размер для покупателя: «EU_39–EU_40» → «EU 39–40», «S_M» → «S M».
/// Бэкенд отдаёт коды размеров с подчёркиваниями; на экране они выглядят
/// как ошибка и растягивают строку.
String kioskSizeLabel(String raw) {
  final clean = raw.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final range = RegExp(r'^([A-Za-z]+) (\S+?)\s*[–-]\s*\1 (\S+)$')
      .firstMatch(clean);
  if (range != null) return '${range[1]} ${range[2]}–${range[3]}';
  return clean;
}
