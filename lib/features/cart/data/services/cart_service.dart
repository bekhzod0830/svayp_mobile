import 'package:hive_flutter/hive_flutter.dart';
import 'package:swipe/features/cart/data/models/cart_item_model.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';

/// Cart Service - Manages shopping cart with Hive persistence
class CartService {
  static const String _boxName = 'cart_box';
  Box<CartItemModel>? _cartBox;

  /// Initialize the cart box
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _cartBox = await Hive.openBox<CartItemModel>(_boxName);
    } else {
      _cartBox = Hive.box<CartItemModel>(_boxName);
    }
  }

  /// Get all cart items
  List<CartItemModel> getCartItems() {
    return _cartBox?.values.toList() ?? [];
  }

  /// Get cart item count
  int getCartCount() {
    return _cartBox?.length ?? 0;
  }

  /// Get total cart items quantity
  int getTotalQuantity() {
    final items = getCartItems();
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Add product to cart
  Future<void> addToCart(
    Product product, {
    required String selectedSize,
    String? selectedColor,
    int quantity = 1,
  }) async {
    await init();

    // Check if item already exists with same size and color
    final existingItemIndex =
        _cartBox?.values.toList().indexWhere(
          (item) =>
              item.productId == product.id &&
              item.selectedSize == selectedSize &&
              item.selectedColor == selectedColor,
        ) ??
        -1;

    if (existingItemIndex != -1) {
      // Update quantity of existing item
      final existingItem = _cartBox?.getAt(existingItemIndex);
      if (existingItem != null) {
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        );
        await _cartBox?.putAt(existingItemIndex, updatedItem);
      }
    } else {
      // Add new item
      final cartItem = CartItemModel.fromProduct(
        product,
        selectedSize: selectedSize,
        selectedColor: selectedColor,
        quantity: quantity,
      );
      await _cartBox?.add(cartItem);
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(int index, int quantity) async {
    await init();

    if (quantity <= 0) {
      await removeItem(index);
      return;
    }

    final item = _cartBox?.getAt(index);
    if (item != null) {
      final updatedItem = item.copyWith(quantity: quantity);
      await _cartBox?.putAt(index, updatedItem);
    }
  }

  /// Remove item from cart
  Future<void> removeItem(int index) async {
    await init();
    await _cartBox?.deleteAt(index);
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    await init();
    await _cartBox?.clear();
  }

  /// Calculate subtotal
  double getSubtotal() {
    final items = getCartItems();
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Calculate shipping cost
  double getShippingCost() {
    final subtotal = getSubtotal();
    // Free shipping over 500,000 UZS
    return subtotal >= 500000 ? 0 : 30000;
  }

  /// Calculate total
  double getTotal() {
    return getSubtotal() + getShippingCost();
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    final items = getCartItems();
    return items.any((item) => item.productId == productId);
  }

  /// Get stream of cart changes
  Stream<List<CartItemModel>> watchCart() {
    return _cartBox?.watch().map((_) => getCartItems()) ?? Stream.empty();
  }

  /// Close the box
  Future<void> close() async {
    await _cartBox?.close();
  }
}
