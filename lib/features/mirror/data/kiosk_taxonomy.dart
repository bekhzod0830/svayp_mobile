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

/// Стили с экрана выбора (ветка «создать»). Станция LIBAS (дизайн 10.2026): по 8
/// на пол, у мужчин и женщин свои наборы — см. [kioskStylesFor]. Коды совпадают с
/// `KioskStyles` на бэкенде; старые коды (MODEST_CHIC, OFFICE_SMART, SPORTY) бэкенд
/// по-прежнему понимает — их шлют уже установленные сборки.
const List<KioskLabeled> kioskStyles = [
  KioskLabeled('CLASSIC', 'Классика', 'Klassika', 'Classic'),
  KioskLabeled('CASUAL', 'Кэжуал', 'Kundalik', 'Casual'),
  KioskLabeled('BUSINESS', 'Деловой', 'Ishbop', 'Business'),
  KioskLabeled('SPORT_CHIC', 'Спорт-шик', 'Sport-shik', 'Sport chic'),
  KioskLabeled('SMART_CASUAL', 'Смарт-кэжуал', 'Smart-kezhual', 'Smart casual'),
  KioskLabeled('STREETWEAR', 'Стритвир', 'Koʻcha uslubi', 'Streetwear'),
  KioskLabeled('MINIMAL', 'Минимализм', 'Minimalizm', 'Minimal'),
  KioskLabeled('PREPPY', 'Преппи', 'Preppi', 'Preppy'),
  KioskLabeled('MODEST', 'Модест', 'Modest', 'Modest'),
  KioskLabeled('EVENING', 'Вечерний', 'Kechki', 'Evening'),
  KioskLabeled('ROMANTIC', 'Романтический', 'Romantik', 'Romantic'),
];

/// Подписи под названием стиля на карточке.
const Map<String, KioskLabeled> kioskStyleDescriptions = {
  'CLASSIC': KioskLabeled(null, 'Элегантность вне времени', 'Vaqtdan tashqari nafislik', 'Timeless elegance'),
  'CASUAL': KioskLabeled(null, 'Комфорт на каждый день', 'Har kungi qulaylik', 'Everyday comfort'),
  'BUSINESS': KioskLabeled(null, 'Собранные образы для работы', 'Ish uchun tartibli obrazlar', 'Polished looks for work'),
  'SPORT_CHIC': KioskLabeled(null, 'Спортивные вещи в городе', 'Shahardagi sport kiyimlari', 'Sportswear for the city'),
  'SMART_CASUAL': KioskLabeled(null, 'Расслабленный офисный стиль', 'Erkin ofis uslubi', 'Relaxed office style'),
  'STREETWEAR': KioskLabeled(null, 'Оверсайз и свободные формы', 'Oversayz va erkin shakllar', 'Oversized, loose shapes'),
  'MINIMAL': KioskLabeled(null, 'Чистые линии, минимум деталей', 'Toza chiziqlar, kam detal', 'Clean lines, few details'),
  'PREPPY': KioskLabeled(null, 'Трикотаж и стиль кампуса', 'Trikotaj va kampus uslubi', 'Knitwear and campus style'),
  'MODEST': KioskLabeled(null, 'Закрытые и свободные образы', 'Yopiq va erkin obrazlar', 'Covered, relaxed looks'),
  'EVENING': KioskLabeled(null, 'Для особенных выходов', 'Maxsus tadbirlar uchun', 'For special occasions'),
  'ROMANTIC': KioskLabeled(null, 'Мягкие формы и лёгкие ткани', 'Yumshoq shakllar, yengil matolar', 'Soft shapes, light fabrics'),
};

const Map<String, List<String>> _stylesByGender = {
  'MALE': [
    'CLASSIC', 'CASUAL', 'BUSINESS', 'SPORT_CHIC', //
    'SMART_CASUAL', 'STREETWEAR', 'MINIMAL', 'PREPPY',
  ],
  'FEMALE': [
    'CLASSIC', 'CASUAL', 'MODEST', 'EVENING', //
    'BUSINESS', 'SPORT_CHIC', 'MINIMAL', 'ROMANTIC',
  ],
};

/// Восемь стилей пола в порядке карточек (две страницы по четыре). Пол не выбран —
/// женский набор.
List<KioskLabeled> kioskStylesFor(String? gender) {
  final codes = _stylesByGender[gender] ?? _stylesByGender['FEMALE']!;
  return [
    for (final code in codes) kioskStyles.firstWhere((s) => s.code == code),
  ];
}

const Map<String, String> _styleSlug = {
  'CLASSIC': 'classic',
  'CASUAL': 'casual',
  'BUSINESS': 'business',
  'SPORT_CHIC': 'sport_chic',
  'SMART_CASUAL': 'smart_casual',
  'STREETWEAR': 'streetwear',
  'MINIMAL': 'minimal',
  'PREPPY': 'preppy',
  'MODEST': 'modest',
  'EVENING': 'evening',
  'ROMANTIC': 'romantic',
};

/// Фото стиля из комплекта станции: `men_classic`, `women_romantic`, …
String? kioskStylePhoto(String? gender, String? code) {
  final slug = _styleSlug[code];
  if (slug == null) return null;
  final who = gender == 'MALE' ? 'men' : 'women';
  return 'assets/mirror/station/photos/${who}_$slug.webp';
}

/// Фото карточки гардероба (мужской / женский).
String kioskGenderPhoto(String gender) =>
    'assets/mirror/station/photos/gender_${gender == 'MALE' ? 'men' : 'women'}.webp';

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

/// Типы фигуры по полу — по четыре, как в дизайне станции. Вариант «не знаю»
/// — отдельная кнопка «Не знаю свой тип фигуры» (код [kioskShapeUnknown]).
const Map<String, List<KioskLabeled>> kioskShapes = {
  'FEMALE': [
    KioskLabeled('HOURGLASS', 'Песочные часы', 'Qum soati', 'Hourglass'),
    KioskLabeled('PEAR', 'Груша', 'Nok', 'Pear'),
    KioskLabeled('APPLE', 'Яблоко', 'Olma', 'Apple'),
    KioskLabeled('RECTANGLE', 'Прямоугольник', 'Toʻgʻri toʻrtburchak', 'Rectangle'),
  ],
  'MALE': [
    KioskLabeled('RECTANGLE', 'Прямоугольник', 'Toʻgʻri toʻrtburchak', 'Rectangle'),
    KioskLabeled('INVERTED_TRIANGLE', 'Перевёрнутый треугольник', 'Teskari uchburchak', 'Inverted triangle'),
    KioskLabeled('TRIANGLE', 'Треугольник', 'Uchburchak', 'Triangle'),
    KioskLabeled('OVAL', 'Овал', 'Oval', 'Oval'),
  ],
};

/// Подписи под названием фигуры.
const Map<String, KioskLabeled> kioskShapeDescriptions = {
  'HOURGLASS': KioskLabeled(null, 'Выраженная талия', 'Aniq bel', 'Defined waist'),
  'PEAR': KioskLabeled(null, 'Бёдра шире плеч', 'Son yelkadan keng', 'Hips wider than shoulders'),
  'APPLE': KioskLabeled(null, 'Мягкая, округлая талия', 'Yumshoq, dumaloq bel', 'Soft, rounded waist'),
  'RECTANGLE': KioskLabeled(null, 'Плечи, талия и бёдра близки', 'Yelka, bel va son yaqin', 'Shoulders, waist and hips alike'),
  'INVERTED_TRIANGLE': KioskLabeled(null, 'Плечи заметно шире бёдер', 'Yelka sondan ancha keng', 'Shoulders much wider than hips'),
  'TRIANGLE': KioskLabeled(null, 'Бёдра шире плеч', 'Son yelkadan keng', 'Hips wider than shoulders'),
  'OVAL': KioskLabeled(null, 'Объём сосредоточен в талии', 'Hajm belda', 'Volume around the waist'),
};

/// Код «не знаю» для типа фигуры: кнопка «Не знаю свой тип фигуры».
const String kioskShapeUnknown = 'UNKNOWN';

const Map<String, String> _shapeSlug = {
  'HOURGLASS': 'hourglass',
  'PEAR': 'pear',
  'APPLE': 'apple',
  'RECTANGLE': 'rectangle',
  'INVERTED_TRIANGLE': 'inverted',
  'TRIANGLE': 'triangle',
  'OVAL': 'oval',
};

/// Силуэт фигуры из комплекта станции.
String? kioskShapeFigure(String? gender, String? code) {
  final slug = _shapeSlug[code];
  if (slug == null) return null;
  final who = gender == 'MALE' ? 'men' : 'women';
  return 'assets/mirror/station/figures/${who}_$slug.webp';
}

/// Силуэты женских фигур старых экранов (бренд-скины без дизайна станции).
const Map<String, String> kioskFemaleShapeAssets = {
  'HOURGLASS': 'lib/img/body_type/Hourglass.png',
  'PEAR': 'lib/img/body_type/Triangle.png',
  'APPLE': 'lib/img/body_type/Oval.png',
  'RECTANGLE': 'lib/img/body_type/Rectangle.png',
  'INVERTED_TRIANGLE': 'lib/img/body_type/Heart.png',
};

/// Бренды шага «Где вы любите покупать?» и кнопки «Другой бренд». Коды совпадают
/// с `KioskBrands` на бэкенде; [kioskAnyBrand] — «Любой бренд».
class KioskShopBrand {
  final String code;
  final String name;
  final String logo;

  const KioskShopBrand(this.code, this.name, this.logo);
}

const String kioskAnyBrand = 'ANY';

const List<KioskShopBrand> kioskShopBrands = [
  KioskShopBrand('BOGGI_MILANO', 'BOGGI MILANO', 'assets/mirror/brands_logos/boggi_milano.png'),
  KioskShopBrand('COLINS', "Colin's", 'assets/mirror/brands_logos/colins.png'),
  KioskShopBrand('JACK_JONES', 'Jack & Jones', 'assets/mirror/brands_logos/jack_jones.png'),
  KioskShopBrand('DIGEL', 'DIGEL', 'assets/mirror/brands_logos/digel.png'),
  KioskShopBrand('MARC_O_POLO', "Marc O'Polo", 'assets/mirror/brands_logos/marc_o_polo.png'),
  KioskShopBrand('MEXX', 'Mexx', 'assets/mirror/brands_logos/mexx.png'),
  KioskShopBrand('MOTIVI', 'Motivi', 'assets/mirror/brands_logos/motivi.png'),
  KioskShopBrand('ONLY', 'ONLY', 'assets/mirror/brands_logos/only.png'),
  KioskShopBrand('NAME_IT', 'name it', 'assets/mirror/brands_logos/name_it.png'),
  KioskShopBrand('SELECTED', 'SELECTED', 'assets/mirror/brands_logos/selected.png'),
  KioskShopBrand('VERO_MODA', 'VERO MODA', 'assets/mirror/brands_logos/vero_moda.png'),
  KioskShopBrand('YAS', 'Y.A.S', 'assets/mirror/brands_logos/yas.png'),
];

/// Цвета экрана «Какие цвета не показывать?». Коды совпадают с семействами цвета
/// на бэкенде (`KioskRefine.COLOR_FAMILIES`).
class KioskColorChoice {
  final String code;
  final KioskLabeled label;
  final int argb;

  const KioskColorChoice(this.code, this.label, this.argb);
}

const List<KioskColorChoice> kioskColors = [
  KioskColorChoice('red', KioskLabeled(null, 'Красные', 'Qizil', 'Red'), 0xFFC62828),
  KioskColorChoice('pink', KioskLabeled(null, 'Розовые', 'Pushti', 'Pink'), 0xFFF48FB1),
  KioskColorChoice('khaki', KioskLabeled(null, 'Хаки', 'Xaki', 'Khaki'), 0xFFA39B6E),
  KioskColorChoice('yellow', KioskLabeled(null, 'Жёлтые', 'Sariq', 'Yellow'), 0xFFF2C94C),
  KioskColorChoice('green', KioskLabeled(null, 'Зелёные', 'Yashil', 'Green'), 0xFF2E7D32),
  KioskColorChoice('blue', KioskLabeled(null, 'Синие', 'Koʻk', 'Blue'), 0xFF1E6FD9),
  KioskColorChoice('navy', KioskLabeled(null, 'Тёмно-синие', 'Toʻq koʻk', 'Navy'), 0xFF1B2A4A),
  KioskColorChoice('purple', KioskLabeled(null, 'Фиолетовые', 'Binafsha', 'Purple'), 0xFF6A3FA0),
  KioskColorChoice('brown', KioskLabeled(null, 'Коричневые', 'Jigarrang', 'Brown'), 0xFF6D4C33),
  KioskColorChoice('grey', KioskLabeled(null, 'Серые', 'Kulrang', 'Grey'), 0xFF9E9E9E),
  KioskColorChoice('white', KioskLabeled(null, 'Белый', 'Oq', 'White'), 0xFFFFFFFF),
  KioskColorChoice('black', KioskLabeled(null, 'Чёрный', 'Qora', 'Black'), 0xFF141414),
];

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
  final range = RegExp(
    r'^([A-Za-z]+) (\S+?)\s*[–-]\s*\1 (\S+)$',
  ).firstMatch(clean);
  if (range != null) return '${range[1]} ${range[2]}–${range[3]}';
  return clean;
}
