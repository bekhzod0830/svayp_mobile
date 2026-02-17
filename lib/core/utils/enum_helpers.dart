/// Enum helper utilities for converting between enums and strings
/// Provides consistent parsing and serialization for API communication

import '../constants/product_enums.dart';

class EnumHelpers {
  // ==================== List Conversion Helpers ====================

  /// Convert list of enum strings to List of SizeEnum
  static List<SizeEnum>? parseSizeList(List<dynamic>? jsonList) {
    if (jsonList == null) return null;
    return jsonList
        .map((e) => SizeEnum.fromString(e as String?))
        .whereType<SizeEnum>()
        .toList();
  }

  /// Convert list of SizeEnum to list of strings for JSON
  static List<String>? sizeListToJson(List<SizeEnum>? enumList) {
    return enumList?.map((e) => e.value).toList();
  }

  /// Convert list of enum strings to List of ColorEnum
  static List<ColorEnum>? parseColorList(List<dynamic>? jsonList) {
    if (jsonList == null) return null;
    return jsonList
        .map((e) => ColorEnum.fromString(e as String?))
        .whereType<ColorEnum>()
        .toList();
  }

  /// Convert list of ColorEnum to list of strings for JSON
  static List<String>? colorListToJson(List<ColorEnum>? enumList) {
    return enumList?.map((e) => e.value).toList();
  }

  /// Convert list of enum strings to List of StyleTagEnum
  static List<StyleTagEnum>? parseStyleTagList(List<dynamic>? jsonList) {
    if (jsonList == null) return null;
    return jsonList
        .map((e) => StyleTagEnum.fromString(e as String?))
        .whereType<StyleTagEnum>()
        .toList();
  }

  /// Convert list of StyleTagEnum to list of strings for JSON
  static List<String>? styleTagListToJson(List<StyleTagEnum>? enumList) {
    return enumList?.map((e) => e.value).toList();
  }

  /// Convert list of enum strings to List of OccasionEnum
  static List<OccasionEnum>? parseOccasionList(List<dynamic>? jsonList) {
    if (jsonList == null) return null;
    return jsonList
        .map((e) => OccasionEnum.fromString(e as String?))
        .whereType<OccasionEnum>()
        .toList();
  }

  /// Convert list of OccasionEnum to list of strings for JSON
  static List<String>? occasionListToJson(List<OccasionEnum>? enumList) {
    return enumList?.map((e) => e.value).toList();
  }

  /// Convert list of enum strings to List of StyleCategoryEnum
  static List<StyleCategoryEnum>? parseStyleCategoryList(
    List<dynamic>? jsonList,
  ) {
    if (jsonList == null) return null;
    return jsonList
        .map((e) => StyleCategoryEnum.fromString(e as String?))
        .whereType<StyleCategoryEnum>()
        .toList();
  }

  /// Convert list of StyleCategoryEnum to list of strings for JSON
  static List<String>? styleCategoryListToJson(
    List<StyleCategoryEnum>? enumList,
  ) {
    return enumList?.map((e) => e.value).toList();
  }

  /// Convert list of enum strings to List of PatternEnum
  static List<PatternEnum>? parsePatternList(List<dynamic>? jsonList) {
    if (jsonList == null) return null;
    return jsonList
        .map((e) => PatternEnum.fromString(e as String?))
        .whereType<PatternEnum>()
        .toList();
  }

  /// Convert list of PatternEnum to list of strings for JSON
  static List<String>? patternListToJson(List<PatternEnum>? enumList) {
    return enumList?.map((e) => e.value).toList();
  }

  /// Convert list of enum strings to List of ClothingItemEnum
  static List<ClothingItemEnum>? parseClothingItemList(
    List<dynamic>? jsonList,
  ) {
    if (jsonList == null) return null;
    return jsonList
        .map((e) => ClothingItemEnum.fromString(e as String?))
        .whereType<ClothingItemEnum>()
        .toList();
  }

  /// Convert list of ClothingItemEnum to list of strings for JSON
  static List<String>? clothingItemListToJson(
    List<ClothingItemEnum>? enumList,
  ) {
    return enumList?.map((e) => e.value).toList();
  }

  /// Convert list of enum strings to List of MaterialEnum
  static List<MaterialEnum>? parseMaterialList(List<dynamic>? jsonList) {
    if (jsonList == null) return null;
    return jsonList
        .map((e) => MaterialEnum.fromString(e as String?))
        .whereType<MaterialEnum>()
        .toList();
  }

  /// Convert list of MaterialEnum to list of strings for JSON
  static List<String>? materialListToJson(List<MaterialEnum>? enumList) {
    return enumList?.map((e) => e.value).toList();
  }

  /// Convert list of enum strings to List of SeasonEnum
  static List<SeasonEnum>? parseSeasonList(List<dynamic>? jsonList) {
    if (jsonList == null) return null;
    return jsonList
        .map((e) => SeasonEnum.fromString(e as String?))
        .whereType<SeasonEnum>()
        .toList();
  }

  /// Convert list of SeasonEnum to list of strings for JSON
  static List<String>? seasonListToJson(List<SeasonEnum>? enumList) {
    return enumList?.map((e) => e.value).toList();
  }

  /// Convert list of enum strings to List of SubcategoryEnum
  static List<SubcategoryEnum>? parseSubcategoryList(List<dynamic>? jsonList) {
    if (jsonList == null) return null;
    return jsonList
        .map((e) => SubcategoryEnum.fromString(e as String?))
        .whereType<SubcategoryEnum>()
        .toList();
  }

  /// Convert list of SubcategoryEnum to list of strings for JSON
  static List<String>? subcategoryListToJson(List<SubcategoryEnum>? enumList) {
    return enumList?.map((e) => e.value).toList();
  }

  // ==================== Display Helpers ====================

  /// Get comma-separated display names from size list
  static String sizesDisplayText(List<SizeEnum>? sizes) {
    if (sizes == null || sizes.isEmpty) return 'N/A';
    return sizes.map((s) => s.displayName).join(', ');
  }

  /// Get comma-separated display names from color list
  static String colorsDisplayText(List<ColorEnum>? colors) {
    if (colors == null || colors.isEmpty) return 'N/A';
    return colors.map((c) => c.displayName).join(', ');
  }

  /// Get comma-separated display names from style tag list
  static String styleTagsDisplayText(List<StyleTagEnum>? tags) {
    if (tags == null || tags.isEmpty) return 'N/A';
    return tags.map((t) => t.displayName).join(', ');
  }

  /// Get comma-separated display names from occasion list
  static String occasionsDisplayText(List<OccasionEnum>? occasions) {
    if (occasions == null || occasions.isEmpty) return 'N/A';
    return occasions.map((o) => o.displayName).join(', ');
  }

  /// Get comma-separated display names from material list
  static String materialsDisplayText(List<MaterialEnum>? materials) {
    if (materials == null || materials.isEmpty) return 'N/A';
    return materials.map((m) => m.displayName).join(', ');
  }

  /// Get comma-separated display names from season list
  static String seasonsDisplayText(List<SeasonEnum>? seasons) {
    if (seasons == null || seasons.isEmpty) return 'N/A';
    return seasons.map((s) => s.displayName).join(', ');
  }

  /// Get comma-separated display names from subcategory list
  static String subcategoriesDisplayText(List<SubcategoryEnum>? subcategories) {
    if (subcategories == null || subcategories.isEmpty) return 'N/A';
    return subcategories.map((s) => s.displayName).join(', ');
  }

  // ==================== Validation Helpers ====================

  /// Check if a string is a valid size enum value
  static bool isValidSize(String? value) {
    return SizeEnum.fromString(value) != null;
  }

  /// Check if a string is a valid color enum value
  static bool isValidColor(String? value) {
    return ColorEnum.fromString(value) != null;
  }

  /// Check if a string is a valid material enum value
  static bool isValidMaterial(String? value) {
    return MaterialEnum.fromString(value) != null;
  }

  // ==================== Search/Filter Helpers ====================

  /// Filter sizes by search query
  static List<SizeEnum> filterSizes(String query) {
    if (query.isEmpty) return SizeEnum.values;
    final lowerQuery = query.toLowerCase();
    return SizeEnum.values
        .where(
          (size) =>
              size.value.contains(lowerQuery) ||
              size.displayName.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// Filter colors by search query
  static List<ColorEnum> filterColors(String query) {
    if (query.isEmpty) return ColorEnum.values;
    final lowerQuery = query.toLowerCase();
    return ColorEnum.values
        .where(
          (color) =>
              color.value.contains(lowerQuery) ||
              color.displayName.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// Get all standard clothing sizes (XS-XXXL)
  static List<SizeEnum> get standardSizes => [
    SizeEnum.xxs,
    SizeEnum.xs,
    SizeEnum.s,
    SizeEnum.m,
    SizeEnum.l,
    SizeEnum.xl,
    SizeEnum.xxl,
    SizeEnum.xxxl,
  ];

  /// Get all numeric sizes for pants
  static List<SizeEnum> get numericSizes => [
    SizeEnum.size24,
    SizeEnum.size25,
    SizeEnum.size26,
    SizeEnum.size27,
    SizeEnum.size28,
    SizeEnum.size29,
    SizeEnum.size30,
    SizeEnum.size31,
    SizeEnum.size32,
    SizeEnum.size34,
    SizeEnum.size36,
    SizeEnum.size38,
    SizeEnum.size40,
    SizeEnum.size42,
    SizeEnum.size44,
    SizeEnum.size46,
    SizeEnum.size48,
  ];

  /// Get all children sizes
  static List<SizeEnum> get childrenSizes => [
    SizeEnum.size2t,
    SizeEnum.size3t,
    SizeEnum.size4t,
    SizeEnum.size5t,
    SizeEnum.size6,
    SizeEnum.size7,
    SizeEnum.size8,
    SizeEnum.size10,
    SizeEnum.size12,
    SizeEnum.size14,
    SizeEnum.size16,
  ];

  /// Get basic colors (most commonly used)
  static List<ColorEnum> get basicColors => [
    ColorEnum.black,
    ColorEnum.white,
    ColorEnum.gray,
    ColorEnum.navy,
    ColorEnum.blue,
    ColorEnum.red,
    ColorEnum.pink,
    ColorEnum.green,
    ColorEnum.brown,
    ColorEnum.beige,
  ];

  /// Get all solid colors (excluding patterns)
  static List<ColorEnum> get solidColors => ColorEnum.values
      .where(
        (color) =>
            color != ColorEnum.multiColor &&
            color != ColorEnum.floral &&
            color != ColorEnum.printed,
      )
      .toList();
}
