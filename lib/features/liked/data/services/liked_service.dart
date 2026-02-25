import 'package:hive_flutter/hive_flutter.dart';
import 'package:swipe/features/liked/data/models/liked_product_model.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';

/// Liked Items Service - Manages liked/saved products with Hive persistence
class LikedService {
  static const String _boxName = 'liked_box';
  Box<LikedProductModel>? _likedBox;

  /// Initialize the liked box
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _likedBox = await Hive.openBox<LikedProductModel>(_boxName);
    } else {
      _likedBox = Hive.box<LikedProductModel>(_boxName);
    }
  }

  /// Get all liked products
  List<LikedProductModel> getLikedProducts() {
    return _likedBox?.values.toList() ?? [];
  }

  /// Get liked count
  int getLikedCount() {
    return _likedBox?.length ?? 0;
  }

  /// Check if product is liked
  bool isLiked(String productId) {
    final products = getLikedProducts();
    return products.any((p) => p.productId == productId);
  }

  /// Toggle like status
  Future<bool> toggleLike(Product product) async {
    await init();

    if (isLiked(product.id)) {
      // Remove from liked
      await removeLike(product.id);
      return false;
    } else {
      // Add to liked
      await addLike(product);
      return true;
    }
  }

  /// Add product to liked
  Future<void> addLike(Product product) async {
    await init();

    // Check if already liked
    if (isLiked(product.id)) {
      return;
    }

    // Use seller as fallback when brand is "Unknown" or empty
    String displayBrand = (product.brand == 'Unknown' || product.brand.isEmpty)
        ? (product.seller ?? product.brand)
        : product.brand;

    // If still "Unknown" or empty, use SVAYP as default
    if (displayBrand == 'Unknown' || displayBrand.isEmpty) {
      displayBrand = 'SVAYP';
    }

    final likedProduct = LikedProductModel(
      productId: product.id,
      brand: displayBrand,
      title: product.title,
      price: product.price,
      imageUrl: product.images.isNotEmpty ? product.images.first : '',
      category: product.category,
      rating: product.rating,
      isNew: product.isNew,
      discountPercentage: product.discountPercentage,
      originalPrice: product.originalPrice,
      sellerId: product.sellerId,
    );

    await _likedBox?.add(likedProduct);
  }

  /// Remove product from liked by product ID
  Future<void> removeLike(String productId) async {
    await init();

    final index =
        _likedBox?.values.toList().indexWhere(
          (p) => p.productId == productId,
        ) ??
        -1;

    if (index != -1) {
      await _likedBox?.deleteAt(index);
    }
  }

  /// Remove product from liked by index
  Future<void> removeLikeAt(int index) async {
    await init();
    await _likedBox?.deleteAt(index);
  }

  /// Clear all liked products
  Future<void> clearAllLiked() async {
    await init();
    await _likedBox?.clear();
  }

  /// Get stream of liked changes
  Stream<List<LikedProductModel>> watchLiked() {
    return _likedBox?.watch().map((_) => getLikedProducts()) ?? Stream.empty();
  }

  /// Close the box
  Future<void> close() async {
    await _likedBox?.close();
  }
}
