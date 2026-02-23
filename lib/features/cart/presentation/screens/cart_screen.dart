import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/cart/data/models/cart_item_model.dart';
import 'package:swipe/features/cart/data/services/cart_service.dart';
import 'package:swipe/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';

/// Cart Screen - Shopping cart with checkout
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final ProductApiService _apiService = ProductApiService();
  List<CartItemModel> _cartItems = [];
  Map<int, String> _cartItemIds = {}; // Map index to cart item ID from API
  bool _isLoading = true;
  double _subtotal = 0.0;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get auth token
      final apiClient = getIt<ApiClient>();
      final token = apiClient.getToken();

      if (token != null && token.isNotEmpty) {
        // Fetch cart from API
        print('📡 Fetching cart from API...');
        final cartData = await _apiService.getCart(token: token);

        final items = cartData['items'] as List<dynamic>;
        final summary = cartData['summary'] as Map<String, dynamic>;

        _subtotal = (summary['subtotal'] as num).toDouble();
        _totalItems = summary['total_items'] as int;

        // Convert API items to CartItemModel and store their IDs
        _cartItemIds.clear();
        _cartItems = items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final product = item['product'] as Map<String, dynamic>;

          // Store the cart item ID for deletion
          _cartItemIds[index] = item['id'] as String;

          return CartItemModel(
            productId: product['id'] as String,
            brand: product['brand'] as String,
            title: product['title'] as String,
            price: product['price'] as int,
            imageUrl: (product['images'] as List).isNotEmpty
                ? product['images'][0] as String
                : '',
            quantity: item['quantity'] as int,
            selectedSize: item['selected_size'] as String,
            selectedColor: item['selected_color'] as String?,
            category: '', // Not provided in API response
            addedAt: DateTime.parse(item['created_at'] as String),
          );
        }).toList();

        print('✅ Loaded ${_cartItems.length} items from API');
      } else {
        // Not authenticated, use local cache
        await _cartService.init();
        _cartItems = _cartService.getCartItems();
        _subtotal = _cartService.getSubtotal();
        _totalItems = _cartItems.fold(0, (sum, item) => sum + item.quantity);
      }
    } catch (e) {
      print('❌ Error loading cart: $e');
      // Fallback to local cache
      await _cartService.init();
      _cartItems = _cartService.getCartItems();
      _subtotal = _cartService.getSubtotal();
      _totalItems = _cartItems.fold(0, (sum, item) => sum + item.quantity);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateQuantity(int index, int delta) async {
    final newQuantity = _cartItems[index].quantity + delta;
    if (newQuantity > 0 && newQuantity <= 10) {
      try {
        // Get auth token
        final apiClient = getIt<ApiClient>();
        final token = apiClient.getToken();

        if (token != null &&
            token.isNotEmpty &&
            _cartItemIds.containsKey(index)) {
          // Update via API
          final cartItemId = _cartItemIds[index]!;
          await _apiService.updateCartItem(
            itemId: cartItemId,
            quantity: newQuantity,
            token: token,
          );
          print('✅ Updated cart item quantity via API');
        } else {
          // Update local cache
          await _cartService.updateQuantity(index, newQuantity);
        }
      } catch (e) {
        print('❌ Error updating quantity: $e');
        // Fallback to local cache
        await _cartService.updateQuantity(index, newQuantity);
      }

      await _loadCart();
    }
  }

  Future<void> _removeItem(int index) async {
    final item = _cartItems[index];

    try {
      // Get auth token
      final apiClient = getIt<ApiClient>();
      final token = apiClient.getToken();

      if (token != null &&
          token.isNotEmpty &&
          _cartItemIds.containsKey(index)) {
        // Delete from API
        final cartItemId = _cartItemIds[index]!;
        await _apiService.deleteCartItem(itemId: cartItemId, token: token);
        print('✅ Deleted cart item from API');
      } else {
        // Delete from local cache
        await _cartService.removeItem(index);
      }
    } catch (e) {
      print('❌ Error removing item: $e');
      // Fallback to local cache
      await _cartService.removeItem(index);
    }

    await _loadCart();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${item.title}'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // TODO: Implement undo functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Undo not yet implemented'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearCart() async {
    try {
      // Get auth token
      final apiClient = getIt<ApiClient>();
      final token = apiClient.getToken();

      if (token != null && token.isNotEmpty) {
        // Clear from API
        await _apiService.clearCart(token: token);
        print('✅ Cleared cart via API');
      } else {
        // Clear from local cache
        await _cartService.clearCart();
      }
    } catch (e) {
      print('❌ Error clearing cart: $e');
      // Fallback to local cache
      await _cartService.clearCart();
    }

    await _loadCart();
  }

  double get subtotal => _subtotal;
  double get _shipping => 0.0; // TODO: Get from API
  double get _total => _subtotal + _shipping;

  Future<void> _proceedToCheckout() async {
    // Navigate to checkout screen
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CheckoutScreen()));

    // Reload cart if coming back from checkout
    if (result == true || mounted) {
      await _loadCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        title: Text(
          l10n.cart,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: Text(
                l10n.clearCart,
                style: AppTypography.body2.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
            )
          : _cartItems.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return _CartItemCard(
                        item: item,
                        onQuantityChanged: (delta) =>
                            _updateQuantity(index, delta),
                        onRemove: () => _removeItem(index),
                      );
                    },
                  ),
                ),

                // Order Summary
                _buildOrderSummary(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.cartEmpty,
              style: AppTypography.heading3.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.startShoppingNow,
              style: AppTypography.body1.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate back to main screen and switch to Discovery tab
                Navigator.of(context).popUntil((route) => route.isFirst);
                MainScreen.globalKey.currentState?.navigateToTab(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.white : AppColors.black,
                foregroundColor: isDark ? AppColors.black : AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.startShoppingNow),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.subtotal,
                    style: AppTypography.body1.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray700,
                    ),
                  ),
                  Text(
                    '${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Shipping
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.delivery,
                    style: AppTypography.body1.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray700,
                    ),
                  ),
                  Text(
                    _shipping == 0
                        ? l10n.free.toUpperCase()
                        : '${_shipping.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _shipping == 0
                          ? Colors.green
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.total,
                    style: AppTypography.heading4.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${_total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
                    style: AppTypography.heading4.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.black,
                    foregroundColor: isDark ? AppColors.black : AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l10n.proceedToCheckout,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.black : AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cart Item Card Widget
class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : AppColors.black).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: isDark ? AppColors.darkMainBackground : Colors.white,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  cacheManager: ImageCacheManager.instance,
                  placeholder: (context, url) => Container(
                    color: isDark
                        ? AppColors.darkTertiaryText
                        : AppColors.gray100,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: isDark ? AppColors.white : AppColors.black,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.brand,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.size}: ${item.selectedSize}${item.selectedColor != null ? ' • ${l10n.color}: ${item.selectedColor}' : ''}',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} UZS',
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray300,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            _QuantityButton(
                              icon: Icons.remove,
                              onPressed: () => onQuantityChanged(-1),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: AppTypography.body2.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            _QuantityButton(
                              icon: Icons.add,
                              onPressed: () => onQuantityChanged(1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              icon: Icon(
                Icons.close,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quantity Button Widget
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: theme.colorScheme.onSurface),
      ),
    );
  }
}
