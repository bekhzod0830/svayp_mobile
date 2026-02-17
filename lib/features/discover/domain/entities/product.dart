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
  final List<String> sizes; // Available sizes
  final List<String> colors; // Available colors
  final String? seller; // Seller/retailer name
  final bool isNew; // New arrival badge
  final bool isFeatured; // Featured product
  final int? discountPercentage; // Discount if any
  final int? originalPrice; // Original price before discount
  final String? fitMatch; // AI fit indicator text
  final String? styleMatch; // AI style match text
  final bool inStock;
  final String? productUrl; // External link to product

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
    this.sizes = const [],
    this.colors = const [],
    this.seller,
    this.isNew = false,
    this.isFeatured = false,
    this.discountPercentage,
    this.originalPrice,
    this.fitMatch,
    this.styleMatch,
    this.inStock = true,
    this.productUrl,
  });

  /// Create Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
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
      sizes:
          (json['sizes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      colors:
          (json['colors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      seller: json['seller'] as String?,
      isNew: json['is_new'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      discountPercentage: json['discount_percentage'] as int?,
      originalPrice: json['original_price'] as int?,
      fitMatch: json['fit_match'] as String?,
      styleMatch: json['style_match'] as String?,
      inStock: json['in_stock'] as bool? ?? true,
      productUrl: json['product_url'] as String?,
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
      'sizes': sizes,
      'colors': colors,
      'seller': seller,
      'is_new': isNew,
      'is_featured': isFeatured,
      'discount_percentage': discountPercentage,
      'original_price': originalPrice,
      'fit_match': fitMatch,
      'style_match': styleMatch,
      'in_stock': inStock,
      'product_url': productUrl,
    };
  }

  /// Get formatted price in UZS
  String get formattedPrice {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS';
  }

  /// Get discount price if available
  String? get formattedDiscountPrice {
    if (originalPrice != null) {
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
    List<String>? sizes,
    List<String>? colors,
    String? seller,
    bool? isNew,
    bool? isFeatured,
    int? discountPercentage,
    int? originalPrice,
    String? fitMatch,
    String? styleMatch,
    bool? inStock,
    String? productUrl,
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
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      seller: seller ?? this.seller,
      isNew: isNew ?? this.isNew,
      isFeatured: isFeatured ?? this.isFeatured,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      originalPrice: originalPrice ?? this.originalPrice,
      fitMatch: fitMatch ?? this.fitMatch,
      styleMatch: styleMatch ?? this.styleMatch,
      inStock: inStock ?? this.inStock,
      productUrl: productUrl ?? this.productUrl,
    );
  }
}
