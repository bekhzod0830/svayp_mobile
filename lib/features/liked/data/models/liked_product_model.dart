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
  }) : likedAt = likedAt ?? DateTime.now();

  @override
  String toString() {
    return 'LikedProductModel(productId: $productId, title: $title, brand: $brand)';
  }
}
