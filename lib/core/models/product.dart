/// Product Model
/// Represents a product from the backend API

import '../constants/product_enums.dart';
import '../utils/enum_helpers.dart';

class Product {
  final String id;
  final String brand;
  final String title;
  final String? description;
  final CategoryEnum category;
  final List<SubcategoryEnum>? subcategory;
  final int price;
  final int? originalPrice;
  final int? discountPercentage;
  final String currency;
  final List<String> images;
  final List<SizeEnum>? sizes;
  final List<String>?
  colors; // Changed from ColorEnum to String to support hex codes
  final int? stockQuantity;
  final bool inStock;
  final List<MaterialEnum>? material;
  final List<SeasonEnum>? season;
  final FitTypeEnum? fitType;
  final LengthEnum? length;
  final SleeveLengthEnum? sleeveLength;
  final bool? hijabAppropriate;
  final CoverageLevelEnum? coverageLevel;
  final int? opacityRating;
  final bool? prayerFriendly;
  final GenderTargetEnum? genderTarget;
  final AgeGroupEnum? ageGroup;
  final List<StyleTagEnum>? styleTags;
  final List<OccasionEnum>? occasionTags;
  final String? seller;
  final String? sellerId;
  final String? countryOfOrigin;
  final bool? isNew;
  final bool? isFeatured;
  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.brand,
    required this.title,
    this.description,
    required this.category,
    this.subcategory,
    required this.price,
    this.originalPrice,
    this.discountPercentage,
    required this.currency,
    required this.images,
    this.sizes,
    this.colors,
    this.stockQuantity,
    required this.inStock,
    this.material,
    this.season,
    this.fitType,
    this.length,
    this.sleeveLength,
    this.hijabAppropriate,
    this.coverageLevel,
    this.opacityRating,
    this.prayerFriendly,
    this.genderTarget,
    this.ageGroup,
    this.styleTags,
    this.occasionTags,
    this.seller,
    this.sellerId,
    this.countryOfOrigin,
    this.isNew,
    this.isFeatured,
    this.rating,
    this.reviewCount,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to safely get string value (handles List case)
    String? safeGetString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) return value.first.toString();
      return value.toString();
    }

    // Parse category with fallback to a default value if null
    final categoryString = safeGetString(json['category']);
    final category = categoryString != null
        ? (CategoryEnum.fromString(categoryString) ?? CategoryEnum.accessories)
        : CategoryEnum.accessories;

    // Use seller name as brand fallback if brand is not provided
    final seller = safeGetString(json['seller']);
    final brand = safeGetString(json['brand']) ?? seller ?? 'Unknown';

    return Product(
      id: safeGetString(json['id']) ?? '',
      brand: brand,
      title: safeGetString(json['title']) ?? 'Untitled',
      description: safeGetString(json['description']),
      category: category,
      subcategory: EnumHelpers.parseSubcategoryList(
        json['subcategory'] as List<dynamic>?,
      ),
      price: json['price'] as int? ?? 0,
      originalPrice: json['original_price'] as int?,
      discountPercentage: json['discount_percentage'] as int?,
      currency: safeGetString(json['currency']) ?? 'UZS',
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sizes: EnumHelpers.parseSizeList(json['sizes'] as List<dynamic>?),
      colors: (json['colors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      stockQuantity: json['stock_quantity'] as int?,
      inStock: json['in_stock'] as bool? ?? true,
      material: EnumHelpers.parseMaterialList(
        json['material'] as List<dynamic>?,
      ),
      season: EnumHelpers.parseSeasonList(json['season'] as List<dynamic>?),
      fitType: FitTypeEnum.fromString(safeGetString(json['fit_type'])),
      length: LengthEnum.fromString(safeGetString(json['length'])),
      sleeveLength: SleeveLengthEnum.fromString(
        safeGetString(json['sleeve_length']),
      ),
      hijabAppropriate: json['hijab_appropriate'] as bool?,
      coverageLevel: CoverageLevelEnum.fromString(
        safeGetString(json['coverage_level']),
      ),
      opacityRating: json['opacity_rating'] as int?,
      prayerFriendly: json['prayer_friendly'] as bool?,
      genderTarget: GenderTargetEnum.fromString(
        safeGetString(json['gender_target']),
      ),
      ageGroup: AgeGroupEnum.fromString(safeGetString(json['age_group'])),
      styleTags: EnumHelpers.parseStyleTagList(
        json['style_tags'] as List<dynamic>?,
      ),
      occasionTags: EnumHelpers.parseOccasionList(
        json['occasion_tags'] as List<dynamic>?,
      ),
      seller: seller,
      sellerId:
          safeGetString(json['seller_id']) ?? safeGetString(json['sellerId']),
      countryOfOrigin: safeGetString(json['country_of_origin']),
      isNew: json['is_new'] as bool?,
      isFeatured: json['is_featured'] as bool?,
      rating: () {
        final rawRating = (json['rating'] as num?)?.toDouble();
        if (rawRating == null || rawRating.isNaN || rawRating.isInfinite) {
          return null;
        }
        return rawRating.clamp(0.0, 5.0);
      }(),
      reviewCount: json['review_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'title': title,
      'description': description,
      'category': category.value,
      'subcategory': EnumHelpers.subcategoryListToJson(subcategory),
      'price': price,
      'original_price': originalPrice,
      'discount_percentage': discountPercentage,
      'currency': currency,
      'images': images,
      'sizes': EnumHelpers.sizeListToJson(sizes),
      'colors': colors,
      'stock_quantity': stockQuantity,
      'in_stock': inStock,
      'material': EnumHelpers.materialListToJson(material),
      'season': EnumHelpers.seasonListToJson(season),
      'fit_type': fitType?.value,
      'length': length?.value,
      'sleeve_length': sleeveLength?.value,
      'hijab_appropriate': hijabAppropriate,
      'coverage_level': coverageLevel?.value,
      'opacity_rating': opacityRating,
      'prayer_friendly': prayerFriendly,
      'gender_target': genderTarget?.value,
      'age_group': ageGroup?.value,
      'style_tags': EnumHelpers.styleTagListToJson(styleTags),
      'occasion_tags': EnumHelpers.occasionListToJson(occasionTags),
      'seller': seller,
      'seller_id': sellerId,
      'country_of_origin': countryOfOrigin,
      'is_new': isNew,
      'is_featured': isFeatured,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get formatted price with currency
  String get formattedPrice {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} $currency';
  }

  /// Get discount amount if applicable
  int? get discountAmount {
    if (originalPrice != null && originalPrice! > price) {
      return originalPrice! - price;
    }
    return null;
  }

  /// Check if product has discount
  bool get hasDiscount {
    return discountAmount != null && discountAmount! > 0;
  }

  /// Get first image or placeholder
  String get mainImage {
    return images.isNotEmpty ? images.first : '';
  }

  /// Get display string for sizes
  String get sizesDisplay => EnumHelpers.sizesDisplayText(sizes);

  /// Get display string for colors
  String get colorsDisplay => EnumHelpers.colorsDisplayText(colors);

  /// Get display string for style tags
  String get styleTagsDisplay => EnumHelpers.styleTagsDisplayText(styleTags);

  /// Get display string for occasions
  String get occasionsDisplay => EnumHelpers.occasionsDisplayText(occasionTags);

  /// Get material display names
  String get materialDisplay => EnumHelpers.materialsDisplayText(material);

  /// Get season display names
  String get seasonDisplay => EnumHelpers.seasonsDisplayText(season);

  /// Get fit type display name
  String get fitTypeDisplay => fitType?.displayName ?? 'N/A';

  /// Get length display name
  String get lengthDisplay => length?.displayName ?? 'N/A';

  /// Get sleeve length display name
  String get sleeveLengthDisplay => sleeveLength?.displayName ?? 'N/A';

  /// Get coverage level display name
  String get coverageLevelDisplay => coverageLevel?.displayName ?? 'N/A';

  /// Get gender target display name
  String get genderTargetDisplay => genderTarget?.displayName ?? 'N/A';

  /// Get age group display name
  String get ageGroupDisplay => ageGroup?.displayName ?? 'N/A';

  /// Get category display name
  String get categoryDisplay => category.displayName;

  /// Get subcategory display names
  String get subcategoryDisplay =>
      EnumHelpers.subcategoriesDisplayText(subcategory);
}

/// Product List Response
class ProductListResponse {
  final List<Product> products;
  final int total;

  ProductListResponse({required this.products, required this.total});

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    // Safely parse products list, skipping any that fail
    final productsList = <Product>[];

    print('📦 ProductListResponse.fromJson - JSON keys: ${json.keys}');
    print('📦 Full JSON structure: $json');

    // Handle different response structures:
    // 1. /products/all returns: {"data": {"data": [...], "total": X}}
    // 2. /recommendations returns: {"data": [...]}
    // 3. /sellers/{id}/detail returns: {"data": {"products": [...], ...}}

    List<dynamic>? productsJson;

    final dataField = json['data'];
    print('📦 dataField type: ${dataField.runtimeType}');
    if (dataField is Map) {
      print('📦 dataField keys: ${dataField.keys}');
    } else {
      print('📦 dataField is not a Map');
    }

    if (dataField is Map<String, dynamic>) {
      // Try different possible keys for products list
      productsJson =
          dataField['data'] as List<dynamic>? ??
          dataField['products'] as List<dynamic>?;
      print(
        '📦 Looking for data/products in Map, found: ${productsJson != null}',
      );
    } else if (dataField is List<dynamic>) {
      // Structure 2: {"data": [...]}
      productsJson = dataField;
      print('📦 dataField is directly a List');
    }

    print(
      '📦 productsJson type: ${productsJson.runtimeType}, isNull: ${productsJson == null}, length: ${productsJson?.length}',
    );

    if (productsJson != null) {
      for (final productJson in productsJson) {
        try {
          final product = Product.fromJson(productJson as Map<String, dynamic>);
          productsList.add(product);
        } catch (e) {
          print('Warning: Failed to parse product: $e');
          // Skip products that fail to parse
        }
      }
    }

    // Get total from response
    final dataWrapper = dataField is Map<String, dynamic> ? dataField : null;
    int totalCount =
        dataWrapper?['total'] as int? ??
        dataWrapper?['pagination']?['total'] as int? ??
        productsList.length;

    print('📦 Parsed ${productsList.length} products, total: $totalCount');

    return ProductListResponse(products: productsList, total: totalCount);
  }
}
