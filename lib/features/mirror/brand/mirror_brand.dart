import 'dart:ui' show Color, FontWeight, Offset;

import '../data/kiosk_taxonomy.dart';

/// Палитра бренда киоска. Киоск всегда светлый, поэтому здесь нет пары
/// «светлая/тёмная» и нет lerp — только константы одного оформления.
class MirrorPalette {
  const MirrorPalette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.hairline,
    required this.primary,
    required this.primaryDeep,
    required this.primaryBright,
    required this.onPrimary,
    required this.selectedBg,
    required this.accent,
    required this.danger,
    required this.success,
    this.primaryGradient,
  });

  /// Фон страницы.
  final Color bg;

  /// Карточки, чипы, шиты.
  final Color surface;

  /// Основной текст.
  final Color ink;

  /// Вторичный текст.
  final Color muted;

  /// Рамки, разделители, «пустой» прогресс.
  final Color hairline;

  /// Кнопки, выбор, прогресс, кольцо камеры.
  final Color primary;

  /// Крупные заголовки, блок кода продавца.
  final Color primaryDeep;

  /// Кикеры и мелкий (<16 px) акцентный текст — контрастнее [primary]
  /// на светлом фоне.
  final Color primaryBright;

  /// Текст на [primary].
  final Color onPrimary;

  /// Заливка выбранной карточки.
  final Color selectedBg;

  /// Мягкие подсказки, линейки, точки. Как текст — только от 16 px.
  final Color accent;

  /// Жёсткие ошибки и точка «live».
  final Color danger;

  /// «В наличии».
  final Color success;

  /// Градиент главной кнопки (сверху-слева → снизу-справа). null — кнопка
  /// сплошная цветом [primary].
  final List<Color>? primaryGradient;
}

/// Типографика бренда: акцидентный шрифт для заголовков и интерфейсный —
/// для всего остального.
class MirrorType {
  const MirrorType({
    required this.displayFamily,
    required this.uiFamily,
    this.displayWeight = 600,
    this.headlineWeight = 500,
    this.displayTracking = -0.01,
    this.displayHeight = 1.05,
    this.kickerUppercase = true,
    this.ctaUppercase = true,
    this.displayVariable = true,
    this.fallbackFamilies = const ['GolosText'],
  });

  /// Семейство заголовков (переменный шрифт: вес задаётся осью `wght`).
  final String displayFamily;

  /// Семейство интерфейсного текста.
  final String uiFamily;

  /// Значение оси `wght` для display-стиля.
  final double displayWeight;

  /// Значение оси `wght` для headline-стиля.
  final double headlineWeight;

  /// Трекинг заголовков в долях em (отрицательный — плотнее).
  final double displayTracking;

  /// Межстрочный интервал заголовков.
  final double displayHeight;

  /// Кикеры и подписи-ярлыки капсом.
  final bool kickerUppercase;

  /// Подписи CTA капсом с разрядкой.
  final bool ctaUppercase;

  /// [displayFamily] — переменный шрифт (вес через ось `wght`). false —
  /// обычное семейство из статичных начертаний: вес берётся через
  /// fontWeight, округлённый до сотни.
  final bool displayVariable;

  /// Запасные семейства для глифов, которых нет в [displayFamily]
  /// (например, узбекское ʻ U+02BB).
  final List<String> fallbackFamilies;
}

/// Радиусы бренда.
class MirrorShape {
  const MirrorShape({
    required this.button,
    required this.card,
    required this.chip,
    required this.image,
  });

  final double button;
  final double card;
  final double chip;
  final double image;
}

/// Как набирать текстовый знак бренда, пока нет файла логотипа.
class MirrorWordmarkStyle {
  const MirrorWordmarkStyle({
    this.family,
    this.weight = FontWeight.w700,
    this.tracking = 0.07,
    this.accentIndex,
    this.accentColor,
  });

  /// Семейство шрифта; null — системный шрифт (так знак LIBΛS набран на
  /// экране входа приложения).
  final String? family;
  final FontWeight weight;

  /// Трекинг в долях кегля.
  final double tracking;

  /// Буква знака, выделенная цветом [accentColor] (у LIBΛS — «Λ»).
  final int? accentIndex;
  final Color? accentColor;
}

/// Постер с видео: ролик играет внутри арочного «зеркала» на светлой сцене,
/// вокруг — искры, подсветка рамки дышит. Цвета — отдельные от палитры
/// киоска, как и у [MirrorCoverHero].
class MirrorVideoCover {
  const MirrorVideoCover({
    required this.asset,
    required this.aspect,
    required this.bgTop,
    required this.bgBottom,
    required this.glow,
    required this.rim,
    required this.text,
    required this.textMuted,
    required this.cta,
    required this.onCta,
    this.posterAsset,
    this.zoom = 1.0,
    this.headlineAccent,
    this.ctaGradient,
  });

  /// Видео-ассет.
  final String asset;

  /// Ширина / высота кадра ролика.
  final double aspect;

  /// Первый кадр ролика картинкой: виден, пока плеер поднимается, чтобы
  /// зеркало не мигало пустотой.
  final String? posterAsset;

  /// Увеличение кадра от нижнего края. Больше 1 срезает верх ролика —
  /// например, водяной знак в углу.
  final double zoom;

  /// Фон сцены: вертикальный градиент.
  final Color bgTop;
  final Color bgBottom;

  /// Мягкое свечение за зеркалом и искры.
  final Color glow;

  /// Подсветка рамки зеркала.
  final Color rim;

  final Color text;
  final Color textMuted;

  /// Цвет второй строки заголовка; null — как [text].
  final Color? headlineAccent;

  final Color cta;
  final Color onCta;

  /// Градиент кнопки; null — сплошной [cta].
  final List<Color>? ctaGradient;
}

/// Вещь на постере: карточка с фото и подписью, от которой тонкая линия
/// ведёт к этой же вещи на модели. Координаты — в долях бокса модели
/// (0,0 — левый верх её картинки; карточка обычно лежит вне 0..1), поэтому
/// композиция масштабируется вместе с моделью на любом экране.
class MirrorCoverPiece {
  const MirrorCoverPiece({
    required this.asset,
    required this.label,
    required this.card,
    required this.target,
    required this.fromLeft,
    this.anchor = 0.5,
  });

  final String asset;

  /// Подпись по языку покупателя.
  final Map<String, String> label;

  /// Центр карточки.
  final Offset card;

  /// Точка на модели, в которую упирается линия.
  final Offset target;

  /// Карточка слева от модели (влетает слева, линия выходит из правого края).
  final bool fromLeft;

  /// Высота выхода линии из карточки в долях её высоты: 0 — верх, 1 — низ.
  final double anchor;

  String labelFor(String lang, String fallbackLang) =>
      label[lang] ?? label[fallbackLang] ?? '';
}

/// Герой постера: модель в образе бренда на студийной сцене. Цвета сцены —
/// отдельные от палитры киоска: это «фотостудия», она темнее и приглушённее.
class MirrorCoverHero {
  const MirrorCoverHero({
    required this.modelAsset,
    required this.modelAspect,
    required this.pieces,
    required this.wall,
    required this.wallLight,
    required this.wallDeep,
    required this.floor,
    required this.podium,
    required this.podiumTop,
    required this.ring,
    required this.glass,
    required this.card,
    required this.onCard,
    required this.text,
    required this.textMuted,
    required this.cta,
    required this.onCta,
  });

  /// Вырезанная модель на прозрачном фоне.
  final String modelAsset;

  /// Ширина / высота картинки модели.
  final double modelAspect;

  final List<MirrorCoverPiece> pieces;

  final Color wall;
  final Color wallLight;
  final Color wallDeep;
  final Color floor;
  final Color podium;
  final Color podiumTop;

  /// Обод овального зеркала за моделью и его стекло.
  final Color ring;
  final Color glass;

  /// Карточки вещей и текст на них.
  final Color card;
  final Color onCard;

  /// Текст на сцене.
  final Color text;
  final Color textMuted;

  /// Главная кнопка постера.
  final Color cta;
  final Color onCta;
}

/// Оформление киоска под конкретный бренд: палитра, типографика, радиусы,
/// знак, языки покупателя, фразы постера и подписи справочников.
///
/// Коды стилей/категорий — enum'ы бэкенда и остаются как есть; бренд может
/// только переименовать подпись или скрыть стиль, который ему не подходит.
class MirrorBrand {
  const MirrorBrand({
    required this.id,
    required this.name,
    required this.palette,
    required this.type,
    required this.shape,
    required this.wordmark,
    this.logoAsset,
    this.wordmarkStyle,
    this.tagline = const {},
    this.videoCover,
    this.coverHero,
    this.languages = const ['ru', 'uz'],
    this.defaultLang = 'ru',
    this.styleLabels = const {},
    this.categoryLabels = const {},
    this.hiddenStyles = const {},
  });

  final String id;
  final String name;
  final MirrorPalette palette;
  final MirrorType type;
  final MirrorShape shape;

  /// Текстовый знак — запасной вариант, когда [logoAsset] не задан, и
  /// подпись для accessibility.
  final String wordmark;

  /// Файл логотипа (`.svg`, `.png`, `.webp`) или null — тогда рисуем
  /// [wordmark] акцидентным шрифтом.
  final String? logoAsset;

  /// Набор текстового знака; null — акцидентный шрифт бренда с разрядкой.
  final MirrorWordmarkStyle? wordmarkStyle;

  /// Короткое описание оформления для экрана выбора: язык → текст.
  final Map<String, String> tagline;

  /// Постер с видео в арочном зеркале. Если задан, заменяет студийную сцену
  /// [coverHero].
  final MirrorVideoCover? videoCover;

  /// Студийная сцена постера с моделью и вещами. null — только фон и текст.
  final MirrorCoverHero? coverHero;

  /// Языки покупателя в порядке переключателя.
  final List<String> languages;

  /// Язык по умолчанию — им же сбрасывается сессия.
  final String defaultLang;

  /// Переименования стилей: код → язык → подпись.
  final Map<String, Map<String, String>> styleLabels;

  /// Переименования категорий: код → язык → подпись.
  final Map<String, Map<String, String>> categoryLabels;

  /// Стили, которых нет у бренда.
  final Set<String> hiddenStyles;

  /// Стили экрана выбора: справочник минус скрытые. Если бренд скрыл всё,
  /// показываем полный список — пустой экран выбора хуже лишней плитки.
  List<KioskLabeled> get styles {
    final visible =
        kioskStyles.where((s) => !hiddenStyles.contains(s.code)).toList();
    return visible.isEmpty ? kioskStyles : visible;
  }

  String taglineFor(String lang) =>
      tagline[lang] ?? tagline[defaultLang] ?? tagline['ru'] ?? '';

  String styleLabel(KioskLabeled style, String lang) =>
      _labelFor(styleLabels, style, lang);

  String categoryLabel(KioskLabeled category, String lang) =>
      _labelFor(categoryLabels, category, lang);

  String _labelFor(
    Map<String, Map<String, String>> overrides,
    KioskLabeled item,
    String lang,
  ) {
    final code = item.code;
    final byLang = code == null ? null : overrides[code];
    // Переименование бренда на языке покупателя, иначе — подпись справочника
    // на том же языке (не русское переименование для английского экрана).
    return byLang?[lang] ?? item.label(lang);
  }

  /// Подпись сегмента переключателя языка.
  static String langLabel(String code) {
    switch (code) {
      case 'ru':
        return 'РУ';
      case 'uz':
        return 'UZ';
      case 'en':
        return 'EN';
      default:
        return code.toUpperCase();
    }
  }
}
