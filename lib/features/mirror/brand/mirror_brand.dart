import 'dart:ui' show Color;

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
    this.heroVideoAsset,
    this.languages = const ['ru', 'uz'],
    this.defaultLang = 'ru',
    this.coverPhrases = const {},
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

  /// Видео-герой постера. null — постер собирает «живые образы» из каталога.
  final String? heroVideoAsset;

  /// Языки покупателя в порядке переключателя.
  final List<String> languages;

  /// Язык по умолчанию — им же сбрасывается сессия.
  final String defaultLang;

  /// Фразы заголовка постера по языку.
  final Map<String, List<String>> coverPhrases;

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
    return byLang?[lang] ?? byLang?[defaultLang] ?? item.label(lang);
  }

  /// Фразы постера для языка покупателя с откатом на [defaultLang].
  List<String> phrasesFor(String lang) =>
      coverPhrases[lang] ?? coverPhrases[defaultLang] ?? const [];

  /// Подпись сегмента переключателя языка.
  static String langLabel(String code) {
    switch (code) {
      case 'ru':
        return 'РУ';
      case 'uz':
        return 'OʻZ';
      case 'en':
        return 'EN';
      default:
        return code.toUpperCase();
    }
  }
}
