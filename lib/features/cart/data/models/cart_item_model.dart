import 'package:hive/hive.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';

part 'cart_item_model.g.dart';

/// Cart Item Model for Hive Persistence
/// Represents a product in the shopping cart with quantity and selections
@HiveType(typeId: 0)
class CartItemModel extends HiveObject {
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
  late int quantity;

  @HiveField(6)
  late String selectedSize;

  @HiveField(7)
  String? selectedColor;

  @HiveField(8)
  late String category;

  @HiveField(9)
  late DateTime addedAt;

  @HiveField(10)
  late String currency; // Currency code (e.g., "UZS", "USD")

  @HiveField(11)
  Map<String, String>? titleLocalized;

  @HiveField(12)
  Map<String, String>? descriptionLocalized;

  CartItemModel({
    required this.productId,
    required this.brand,
    required this.title,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    required this.selectedSize,
    this.selectedColor,
    required this.category,
    this.currency = 'UZS',
    this.titleLocalized,
    this.descriptionLocalized,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Create from Product entity
  factory CartItemModel.fromProduct(
    Product product, {
    required String selectedSize,
    String? selectedColor,
    int quantity = 1,
  }) {
    return CartItemModel(
      productId: product.id,
      brand: product.brand,
      title: product.title,
      price: product.price,
      imageUrl: product.images.isNotEmpty ? product.images.first : '',
      quantity: quantity,
      selectedSize: selectedSize,
      selectedColor: selectedColor,
      category: product.category,
      currency: product.currency,
      titleLocalized: product.titleLocalized,
      descriptionLocalized: product.descriptionLocalized,
    );
  }

  /// Get localized title based on language code
  String localizedTitle(String languageCode) {
    if (titleLocalized == null) return title;
    return titleLocalized![languageCode] ?? titleLocalized!['en'] ?? title;
  }

  /// Get localized description based on language code
  String localizedDescription(String languageCode) {
    if (descriptionLocalized == null) return '';
    return descriptionLocalized![languageCode] ??
        descriptionLocalized!['en'] ??
        '';
  }

  /// Calculate total price for this item
  double get totalPrice => price.toDouble() * quantity;

  /// Create a copy with updated fields
  CartItemModel copyWith({
    String? productId,
    String? brand,
    String? title,
    int? price,
    String? imageUrl,
    int? quantity,
    String? selectedSize,
    String? selectedColor,
    String? category,
    String? currency,
    Map<String, String>? titleLocalized,
    Map<String, String>? descriptionLocalized,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      brand: brand ?? this.brand,
      title: title ?? this.title,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      titleLocalized: titleLocalized ?? this.titleLocalized,
      descriptionLocalized: descriptionLocalized ?? this.descriptionLocalized,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'CartItemModel(productId: $productId, title: $title, quantity: $quantity, size: $selectedSize)';
  }
}
