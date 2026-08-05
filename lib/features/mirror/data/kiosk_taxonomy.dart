/// Словари киоска: коды уходят на бэкенд, подписи показываются человеку.
/// Портировано из `swipe-web/lib/kiosk-i18n.ts` (KIOSK_STYLES / KIOSK_SHAPES /
/// KIOSK_CATEGORIES). Не в ARB сознательно: это бэкенд-enum'ы с зависящими от
/// пола списками, а киоск говорит только на RU/UZ.
library;

class KioskLabeled {
  final String? code;
  final String ru;
  final String uz;

  const KioskLabeled(this.code, this.ru, this.uz);

  String label(String langCode) => langCode == 'uz' ? uz : ru;
}

/// Стили с экрана выбора (ветка «создать»).
const List<KioskLabeled> kioskStyles = [
  KioskLabeled('CLASSIC', 'Классика', 'Klassika'),
  KioskLabeled('CASUAL', 'Кэжуал', 'Kundalik'),
  KioskLabeled('MODEST_CHIC', 'Модест', 'Modest'),
  KioskLabeled('EVENING', 'Вечерний', 'Kechki'),
  KioskLabeled('OFFICE_SMART', 'Деловой', 'Ishbop'),
  KioskLabeled('SPORTY', 'Спорт-шик', 'Sport-shik'),
];

/// Фильтры каталога. `code == null` — «Все»; остальные совпадают с enum
/// Category на бэкенде. Бельё и домашнее не выносим: в образ они не идут.
const List<KioskLabeled> kioskCategories = [
  KioskLabeled(null, 'Все', 'Hammasi'),
  KioskLabeled('TOPWEAR', 'Верх', 'Yuqori'),
  KioskLabeled('BOTTOMWEAR', 'Низ', 'Pastki'),
  KioskLabeled('DRESSES', 'Платья', 'Koʻylaklar'),
  KioskLabeled('TWO_PIECE_SET', 'Комплекты', 'Toʻplamlar'),
  KioskLabeled('OUTERWEAR', 'Верхняя', 'Ustki kiyim'),
  KioskLabeled('FOOTWEAR', 'Обувь', 'Poyabzal'),
  KioskLabeled('ACCESSORIES', 'Аксессуары', 'Aksessuarlar'),
];

/// Типы фигуры по полу. Вариант «не знаю» (UNKNOWN) добавляется на экране
/// всегда, отдельно от этих списков.
const Map<String, List<KioskLabeled>> kioskShapes = {
  'FEMALE': [
    KioskLabeled('HOURGLASS', 'Песочные часы', 'Qum soati'),
    KioskLabeled('PEAR', 'Груша', 'Nok'),
    KioskLabeled('APPLE', 'Яблоко', 'Olma'),
    KioskLabeled('RECTANGLE', 'Прямоугольник', 'Toʻgʻri toʻrtburchak'),
    KioskLabeled('INVERTED_TRIANGLE', 'Перевёрнутый', 'Teskari uchburchak'),
  ],
  'MALE': [
    KioskLabeled('RECTANGLE', 'Прямоугольник', 'Toʻgʻri toʻrtburchak'),
    KioskLabeled('INVERTED_TRIANGLE', 'Треугольник', 'Uchburchak'),
    KioskLabeled('TRIANGLE', 'Прямой', 'Toʻgʻri'),
    KioskLabeled('OVAL', 'Овал', 'Oval'),
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

/// Цена как на ценниках в зале: «1 250 000 сум» / «1 250 000 soʻm».
/// Рукописная группировка по 3 разряда — intl.NumberFormat зависит от локали
/// и не гарантирует ровно такой вид.
String kioskMoney(int value, String langCode) {
  final digits = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  final sign = value < 0 ? '−' : '';
  final unit = langCode == 'uz' ? 'soʻm' : 'сум';
  return '$sign$buf $unit';
}
