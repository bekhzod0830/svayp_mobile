import 'package:hive/hive.dart';

part 'liked_product_model.g.dart';

/// Liked Product Model for Hive Persistence
/// Stores minimal product info for liked/saved items
@HiveType(typeId: 1)
class LikedProductModel extends HiveObject {
  @HiveField(0)
  late String productId;

  @HiveField(1)
  late String brand;

  @HiveField(2)
  late String title;

  @HiveField(3)
  late int price;

  @HiveField(4)
  late String imageUrl;

  @HiveField(5)
  late String category;

  @HiveField(6)
  late double rating;

  @HiveField(7)
  late DateTime likedAt;

  @HiveField(8)
  late bool isNew;

  @HiveField(9)
  int? discountPercentage;

  @HiveField(10)
  int? originalPrice;

  @HiveField(11)
  String? sellerId;

  @HiveField(12)
  String currency;

  @HiveField(13)
  Map<String, String>? titleLocalized;

  @HiveField(14)
  Map<String, String>? descriptionLocalized;

  LikedProductModel({
    required this.productId,
    required this.brand,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.rating = 0.0,
    DateTime? likedAt,
    this.isNew = false,
    this.discountPercentage,
    this.originalPrice,
    this.sellerId,
    this.currency = 'UZS',
    this.titleLocalized,
    this.descriptionLocalized,
  }) : likedAt = likedAt ?? DateTime.now();

  /// Get localized title, falling back to plain title
  String localizedTitle(String languageCode) {
    if (titleLocalized == null) return title;
    return titleLocalized![languageCode] ?? titleLocalized!['en'] ?? title;
  }

  /// Get localized description
  String localizedDescription(String languageCode) {
    if (descriptionLocalized == null) return '';
    return descriptionLocalized![languageCode] ??
        descriptionLocalized!['en'] ??
        '';
  }

  @override
  String toString() {
    return 'LikedProductModel(productId: $productId, title: $title, brand: $brand)';
  }
}
