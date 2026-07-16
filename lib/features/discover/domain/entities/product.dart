/// Product Model - Represents a fashion product in the app
class Product {
  final String id;
  final String brand;
  final String title;
  final String description;
  final int price; // Price in UZS
  final List<String> images; // Multiple product images
  final double rating; // 0.0 to 5.0
  final int reviewCount;
  final String category; // e.g., "Dress", "Shoes", "Accessories"
  final List<String>? subcategory; // Subcategories
  final List<String> sizes; // Available sizes
  final List<String> colors; // Available colors
  final Map<String, String>? colorImageMap; // Color to image URL mapping
  final List<String>? material; // Materials
  final List<String>? season; // Seasons
  final String currency; // Currency code (e.g., "UZS")
  final String? seller; // Seller/retailer name
  final String? sellerId; // Seller UUID
  final bool isNew; // New arrival badge
  final bool isFeatured; // Featured product
  final int? discountPercentage; // Discount if any
  final int? originalPrice; // Original price before discount
  final String? fitMatch; // AI fit indicator text
  final String? styleMatch; // AI style match text
  final bool inStock;
  /// true = товар предобработан бэкфиллом (есть каноничная вещь) → доступна примерка.
  final bool catalogReady;
  final String? productUrl; // External link to product
  final String? countryOfOrigin; // Country where product is made
  final Map<String, String> titleLocalized;
  final Map<String, String> descriptionLocalized;

  Product({
    required this.id,
    required this.brand,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.category,
    this.subcategory,
    this.sizes = const [],
    this.colors = const [],
    this.colorImageMap,
    this.material,
    this.season,
    this.currency = 'UZS',
    this.seller,
    this.sellerId,
    this.isNew = false,
    this.isFeatured = false,
    this.discountPercentage,
    this.originalPrice,
    this.fitMatch,
    this.styleMatch,
    this.inStock = true,
    this.catalogReady = false,
    this.productUrl,
    this.countryOfOrigin,
    this.titleLocalized = const {},
    this.descriptionLocalized = const {},
  });

  /// Create Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse color variants to create color-to-image mapping
    Map<String, String>? colorImageMap;
    final colorVariants = json['color_variants'] as List<dynamic>?;
    if (colorVariants != null && colorVariants.isNotEmpty) {
      colorImageMap = {};
      for (final variant in colorVariants) {
        final variantMap = variant as Map<String, dynamic>;
        final color = variantMap['color'] as String?;
        final image = variantMap['image'] as String?;
        if (color != null && image != null) {
          colorImageMap[color] = image;
        }
      }
    }

    return Product(
      id: json['id'] as String,
      brand: json['brand'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      price: json['price'] as int,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      category: json['category'] as String,
      subcategory: (json['subcategory'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sizes:
          (json['sizes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      colors:
          (json['colors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      colorImageMap: colorImageMap,
      material: (json['material'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      season: (json['season'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      currency: json['currency'] as String? ?? 'UZS',
      seller: json['seller'] as String?,
      sellerId: json['seller_id'] as String? ?? json['sellerId'] as String?,
      isNew: json['is_new'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      catalogReady: json['catalog_ready'] as bool? ?? false,
      discountPercentage: json['discount_percentage'] as int?,
      originalPrice: json['original_price'] as int?,
      fitMatch: json['fit_match'] as String?,
      styleMatch: json['style_match'] as String?,
      inStock: json['in_stock'] as bool? ?? true,
      productUrl: json['product_url'] as String?,
      countryOfOrigin: json['country_of_origin'] as String?,
      titleLocalized:
          (json['title_localized'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      descriptionLocalized:
          (json['description_localized'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
    );
  }

  /// Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'title': title,
      'description': description,
      'price': price,
      'images': images,
      'rating': rating,
      'review_count': reviewCount,
      'category': category,
      'subcategory': subcategory,
      'sizes': sizes,
      'colors': colors,
      'material': material,
      'season': season,
      'currency': currency,
      'seller': seller,
      'seller_id': sellerId,
      'is_new': isNew,
      'is_featured': isFeatured,
      'discount_percentage': discountPercentage,
      'original_price': originalPrice,
      'fit_match': fitMatch,
      'style_match': styleMatch,
      'in_stock': inStock,
      'product_url': productUrl,
      'country_of_origin': countryOfOrigin,
      'title_localized': titleLocalized,
      'description_localized': descriptionLocalized,
    };
  }

  /// Get localized title or fall back to [title]
  String localizedTitle(String languageCode) {
    return titleLocalized[languageCode] ?? titleLocalized['en'] ?? title;
  }

  /// Get localized description or fall back to [description]
  String localizedDescription(String languageCode) {
    return descriptionLocalized[languageCode] ??
        descriptionLocalized['en'] ??
        description;
  }

  /// Get formatted price with correct currency symbol
  String get formattedPrice {
    if (currency == 'USD') {
      return '\$$price';
    }
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS';
  }

  /// Get formatted original/discount price with correct currency symbol
  String? get formattedDiscountPrice {
    if (originalPrice != null) {
      if (currency == 'USD') {
        return '\$$originalPrice';
      }
      return '${originalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS';
    }
    return null;
  }

  /// Get formatted rating
  String get formattedRating {
    return rating.toStringAsFixed(1);
  }

  /// Check if product has discount
  bool get hasDiscount {
    return discountPercentage != null && discountPercentage! > 0;
  }

  /// Copy with method for immutability
  Product copyWith({
    String? id,
    String? brand,
    String? title,
    String? description,
    int? price,
    List<String>? images,
    double? rating,
    int? reviewCount,
    String? category,
    List<String>? subcategory,
    List<String>? sizes,
    List<String>? colors,
    Map<String, String>? colorImageMap,
    List<String>? material,
    List<String>? season,
    String? currency,
    String? seller,
    String? sellerId,
    bool? isNew,
    bool? isFeatured,
    int? discountPercentage,
    int? originalPrice,
    String? fitMatch,
    String? styleMatch,
    bool? inStock,
    String? productUrl,
    String? countryOfOrigin,
    Map<String, String>? titleLocalized,
    Map<String, String>? descriptionLocalized,
  }) {
    return Product(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      colorImageMap: colorImageMap ?? this.colorImageMap,
      material: material ?? this.material,
      season: season ?? this.season,
      currency: currency ?? this.currency,
      seller: seller ?? this.seller,
      sellerId: sellerId ?? this.sellerId,
      isNew: isNew ?? this.isNew,
      isFeatured: isFeatured ?? this.isFeatured,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      originalPrice: originalPrice ?? this.originalPrice,
      fitMatch: fitMatch ?? this.fitMatch,
      styleMatch: styleMatch ?? this.styleMatch,
      inStock: inStock ?? this.inStock,
      productUrl: productUrl ?? this.productUrl,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      titleLocalized: titleLocalized ?? this.titleLocalized,
      descriptionLocalized: descriptionLocalized ?? this.descriptionLocalized,
    );
  }
}
