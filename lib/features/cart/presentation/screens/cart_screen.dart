import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/cart/data/models/cart_item_model.dart';
import 'package:swipe/features/cart/data/services/cart_service.dart';
import 'package:swipe/core/services/badge_notifier.dart';
import 'package:swipe/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';

/// Helper function to format size label by removing SIZE_ prefix
String _formatSizeLabel(String size) {
  // Remove SIZE_ prefix if present (e.g., "SIZE_46" -> "46")
  if (size.toUpperCase().startsWith('SIZE_')) {
    return size.substring(5);
  }
  return size;
}

/// Helper function to format cart item price using the currency field from the API
String _formatCartItemPrice(CartItemModel item) {
  final currency = item.currency;

  if (currency == 'USD') {
    return '\$${item.price.toStringAsFixed(2)}';
  }
  return '${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
}

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
  Map<String, String> _cartItemIds =
      {}; // Map productId to cart item ID from API
  bool _isLoading = false; // Start with false, show cached data immediately
  double _subtotal = 0.0;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _openProductDetail(CartItemModel item) async {
    if (!mounted) return;
    // Capture navigator/messenger before any async gap to avoid stale context
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => const ColoredBox(
          color: Color(0x66000000),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    try {
      final token = getIt<ApiClient>().getToken();
      final api_models.Product apiProduct = await _apiService.getProductById(
        item.productId,
        token: token,
      );

      String displayBrand =
          (apiProduct.brand == 'Unknown' || apiProduct.brand.isEmpty)
          ? (apiProduct.seller ?? apiProduct.brand)
          : apiProduct.brand;
      if (displayBrand == 'Unknown' || displayBrand.isEmpty) {
        displayBrand = 'SVAYP';
      }

      final product = Product(
        id: apiProduct.id,
        brand: displayBrand,
        title: apiProduct.title,
        description: apiProduct.description ?? '',
        price: apiProduct.price,
        images: apiProduct.images.isNotEmpty
            ? apiProduct.images
            : (item.imageUrl.isNotEmpty ? [item.imageUrl] : []),
        category:
            apiProduct.originalCategoryString ?? apiProduct.category.value,
        subcategory: apiProduct.subcategory?.map((s) => s.displayName).toList(),
        sizes: apiProduct.sizes ?? [],
        colors: apiProduct.colors ?? [],
        material: apiProduct.material?.map((m) => m.displayName).toList(),
        season: apiProduct.season?.map((s) => s.displayName).toList(),
        currency: apiProduct.currency,
        rating: apiProduct.rating ?? 4.5,
        reviewCount: apiProduct.reviewCount ?? 0,
        inStock: apiProduct.inStock,
        isNew: apiProduct.isNew ?? false,
        isFeatured: false,
        seller: apiProduct.seller,
        sellerId: apiProduct.sellerId,
        discountPercentage: apiProduct.discountPercentage,
        originalPrice: apiProduct.originalPrice,
        titleLocalized: apiProduct.titleLocalized,
        descriptionLocalized: apiProduct.descriptionLocalized,
      );

      navigator.pop(); // dismiss loader overlay
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );
    } catch (e) {
      navigator.pop(); // dismiss loader overlay
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to load product details')),
      );
    }
  }

  Future<void> _loadCart() async {
    // First, load from local cache and show immediately
    await _cartService.init();
    List<CartItemModel> cachedItems = _cartService.getCartItems();
    double cachedSubtotal = _cartService.getSubtotal();
    int cachedTotalItems = cachedItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    // Check if the user has a token so we know whether to wait for the API
    final apiClient = getIt<ApiClient>();
    final token = apiClient.getToken();
    final hasToken = token != null && token.isNotEmpty;

    setState(() {
      _cartItems = cachedItems;
      _subtotal = cachedSubtotal;
      _totalItems = cachedTotalItems;
      // Keep the spinner when Hive is empty AND the API can be reached,
      // so the user sees a loader instead of the empty-cart screen while
      // the network request is in-flight.
      _isLoading = cachedItems.isEmpty && hasToken;
    });
    // Update badge from Hive immediately so all screens reflect current count.
    BadgeNotifier.instance.setCartCount(cachedTotalItems);

    if (!hasToken) return;

    // Then, try to fetch from API in background to update ONLY cart IDs
    try {
      // Fetch cart from API
      final cartData = await _apiService.getCart(token: token);

      final rawItems = cartData['items'];
      final rawSummary = cartData['summary'];
      if (rawItems == null || rawSummary == null) return;

      final items = rawItems as List<dynamic>;
      final summary = rawSummary as Map<String, dynamic>;

      final subtotal = (summary['subtotal'] as num?)?.toDouble() ?? 0.0;

      // Parse all API items into CartItemModel and build the ID map.
      // This is the source of truth – sync everything to Hive so the
      // cart is correct even after a fresh login.
      Map<String, String> cartItemIds = {};
      final List<CartItemModel> apiCartItems = [];

      // Keep a reference to the currently-cached items so we can fall back
      // to locally-stored values (brand, size, color) when the API returns
      // empty strings for those fields.
      final cachedById = {for (final c in _cartItems) c.productId: c};

      for (final rawItem in items) {
        if (rawItem is! Map<String, dynamic>) continue;
        final item = rawItem;
        final product = item['product'] as Map<String, dynamic>?;
        if (product == null) continue;

        final productId = product['id']?.toString() ?? '';
        if (productId.isEmpty) continue;

        cartItemIds[productId] = item['id']?.toString() ?? '';

        final rawPrice = product['price'];
        final price = rawPrice is num ? rawPrice.toInt() : 0;

        final images = product['images'];
        final imageList = images is List ? images : <dynamic>[];
        final imageUrl = imageList.isNotEmpty ? imageList.first.toString() : '';

        final titleLoc = (product['title_localized'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString()));
        final descLoc =
            (product['description_localized'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v.toString()),
            );

        final cached = cachedById[productId];
        final apiBrand = product['brand'] as String? ?? '';
        final apiSeller = product['seller'] as String? ?? '';
        // Mirror _convertApiProduct: prefer brand, fall back to seller, then cached.
        final resolvedBrand = (apiBrand.isNotEmpty && apiBrand != 'Unknown')
            ? apiBrand
            : apiSeller.isNotEmpty
            ? apiSeller
            : (cached?.brand ?? '');

        // The API uses selected_size / selected_color on the cart-item object.
        // Fall back to the cached Hive value if the field is absent/empty.
        final apiSize = item['selected_size'] as String? ?? '';
        final apiColor = item['selected_color'] as String?;

        apiCartItems.add(
          CartItemModel(
            productId: productId,
            brand: resolvedBrand,
            title: product['title'] as String? ?? '',
            price: price,
            imageUrl: imageUrl,
            quantity: item['quantity'] is int ? item['quantity'] as int : 1,
            selectedSize: apiSize.isNotEmpty
                ? apiSize
                : (cached?.selectedSize ?? ''),
            selectedColor: apiColor ?? cached?.selectedColor,
            category: product['category'] as String? ?? '',
            currency: product['currency'] as String? ?? 'UZS',
            titleLocalized: titleLoc,
            descriptionLocalized: descLoc,
            addedAt: item['created_at'] != null
                ? DateTime.tryParse(item['created_at'].toString()) ??
                      DateTime.now()
                : (cached?.addedAt ?? DateTime.now()),
          ),
        );
      }

      // Sync Hive with the authoritative API data.
      await _cartService.syncFromApi(apiCartItems);
      final syncedItems = _cartService.getCartItems();
      final syncedTotal = syncedItems.fold<int>(
        0,
        (sum, i) => sum + i.quantity,
      );

      BadgeNotifier.instance.setCartCount(syncedTotal);
      if (mounted) {
        setState(() {
          _cartItemIds = cartItemIds;
          _cartItems = syncedItems;
          _subtotal = subtotal;
          _totalItems = syncedTotal;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If API call fails, we already have cached data showing
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateQuantity(int index, int delta) async {
    final item = _cartItems[index];
    final newQuantity = item.quantity + delta;
    if (newQuantity > 0 && newQuantity <= 10) {
      // Always update local Hive cache first so _loadCart shows fresh data
      // immediately regardless of whether the API call succeeds.
      await _cartService.updateQuantity(index, newQuantity);

      // Fire-and-forget API update (best-effort sync), looked up by productId.
      try {
        final apiClient = getIt<ApiClient>();
        final token = apiClient.getToken();
        final cartItemId = _cartItemIds[item.productId];
        if (token != null &&
            token.isNotEmpty &&
            cartItemId != null &&
            cartItemId.isNotEmpty) {
          await _apiService.updateCartItem(
            itemId: cartItemId,
            quantity: newQuantity,
            token: token,
          );
        }
      } catch (_) {
        // Local cache already updated – nothing more to do.
      }

      await _loadCart();
    }
  }

  Future<void> _removeItem(int index) async {
    final item = _cartItems[index];
    final cartItemId = _cartItemIds[item.productId];

    // Always remove from local cache
    await _cartService.removeItem(index);

    // Best-effort API delete, looked up by productId
    try {
      final apiClient = getIt<ApiClient>();
      final token = apiClient.getToken();
      if (token != null &&
          token.isNotEmpty &&
          cartItemId != null &&
          cartItemId.isNotEmpty) {
        await _apiService.deleteCartItem(itemId: cartItemId, token: token);
      }
    } catch (_) {
      // Local cache already updated – nothing more to do.
    }

    await _loadCart();
  }

  Future<void> _clearCart() async {
    try {
      // Get auth token
      final apiClient = getIt<ApiClient>();
      final token = apiClient.getToken();

      if (token != null && token.isNotEmpty) {
        // Clear from API
        await _apiService.clearCart(token: token);
      }
    } catch (e) {
      // API clear failed – still wipe the local cache below
    }

    // Always clear the local Hive cache so the UI reflects an empty cart
    await _cartService.clearCart();

    await _loadCart();
  }

  double get subtotal => _subtotal;
  double get _shipping => 0.0; // TODO: Get from API
  double get _total => _subtotal + _shipping;

  /// Calculate subtotal for USD products
  double get _usdSubtotal {
    return _cartItems.fold(0.0, (sum, item) {
      if (item.currency == 'USD') {
        return sum + item.totalPrice;
      }
      return sum;
    });
  }

  /// Calculate subtotal for UZS products
  double get _uzsSubtotal {
    return _cartItems.fold(0.0, (sum, item) {
      if (item.currency == 'UZS') {
        return sum + item.totalPrice;
      }
      return sum;
    });
  }

  /// Check if cart has USD products
  bool get _hasUsdProducts => _usdSubtotal > 0;

  /// Check if cart has UZS products
  bool get _hasUzsProducts => _uzsSubtotal > 0;

  /// Format price with correct currency
  String _getFormattedPrice(double price, String currency) {
    if (currency == 'USD') {
      return '\$${price.toStringAsFixed(2)}';
    }
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
  }

  Future<void> _proceedToCheckout() async {
    // Gate for guest users
    final storage = await LocalStorageHelper.getInstance();
    if (storage.isGuestMode()) {
      if (mounted) GuestLoginPrompt.show(context);
      return;
    }
    // Navigate to checkout screen
    final result = await Navigator.of(
      context,
      rootNavigator: true,
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

    final topPadding = MediaQuery.of(context).padding.top;
    const headerHeight = 56.0;
    final headerTotal = topPadding + headerHeight + 8.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Content ─────────────────────────────────────────────
          _isLoading
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
                      child: RefreshIndicator(
                        onRefresh: _loadCart,
                        color: isDark ? AppColors.white : AppColors.black,
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            headerTotal + 8,
                            16,
                            16,
                          ),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            return GestureDetector(
                              onTap: () => _openProductDetail(item),
                              child: _CartItemCard(
                                item: item,
                                onQuantityChanged: (delta) =>
                                    _updateQuantity(index, delta),
                                onRemove: () => _removeItem(index),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Order Summary
                    _buildOrderSummary(),
                  ],
                ),

          // ── Floating glass header ───────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: headerTotal,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xD0050508)
                        : const Color(0xB8FFFFFF),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x22FFFFFF)
                          : const Color(0x28000000),
                      width: 0.5,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: topPadding),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            l10n.cart,
                            style: AppTypography.heading3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (_cartItems.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: GestureDetector(
                              onTap: _clearCart,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.5),
                                    width: 1.2,
                                  ),
                                  color: Colors.red.withValues(alpha: 0.08),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 56),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
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
        color: isDark ? const Color(0xF0050508) : const Color(0xF8FFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x22FFFFFF) : const Color(0x28000000),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            children: [
              // USD Total (if present)
              if (_hasUsdProducts) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _hasUzsProducts ? '${l10n.total} (USD)' : l10n.total,
                      style: AppTypography.heading4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _getFormattedPrice(_usdSubtotal + _shipping, 'USD'),
                      style: AppTypography.heading4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                if (_hasUzsProducts) const SizedBox(height: 8),
              ],

              // UZS Total (if present)
              if (_hasUzsProducts) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _hasUsdProducts ? '${l10n.total} (UZS)' : l10n.total,
                      style: AppTypography.heading4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _getFormattedPrice(_uzsSubtotal + _shipping, 'UZS'),
                      style: AppTypography.heading4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : AppColors.black,
                    foregroundColor: isDark ? AppColors.black : AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 90,
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    color: isDark
                        ? AppColors.darkMainBackground
                        : AppColors.gray100,
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl.isNotEmpty
                          ? item.imageUrl
                          : 'https://via.placeholder.com/400',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      cacheManager: ImageCacheManager.instance,
                      memCacheWidth: 180,
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
                      errorWidget: (context, url, error) => Container(
                        color: isDark
                            ? AppColors.darkMainBackground
                            : AppColors.gray100,
                        child: Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray400,
                        ),
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
                    item.localizedTitle(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Size and Color
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${l10n.size}: ${_formatSizeLabel(item.selectedSize)}',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.selectedColor != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '\u2022',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${l10n.color}:',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildColorCircle(item.selectedColor!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatCartItemPrice(item),
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      // Quantity Controls
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkMainBackground
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minus / trash
                            GestureDetector(
                              onTap: () => item.quantity == 1
                                  ? onRemove()
                                  : onQuantityChanged(-1),
                              child: Container(
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: item.quantity == 1
                                      ? Colors.red.withValues(alpha: 0.12)
                                      : (isDark
                                            ? AppColors.darkCardBackground
                                            : AppColors.white),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.3 : 0.08,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  item.quantity == 1
                                      ? Icons.delete_outline_rounded
                                      : Icons.remove_rounded,
                                  size: 16,
                                  color: item.quantity == 1
                                      ? Colors.red
                                      : (isDark
                                            ? AppColors.darkPrimaryText
                                            : AppColors.black),
                                ),
                              ),
                            ),
                            // Count
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: AppTypography.body2.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            // Plus
                            GestureDetector(
                              onTap: () => onQuantityChanged(1),
                              child: Container(
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCardBackground
                                      : AppColors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.3 : 0.08,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a small color circle widget for hex colors
  Widget _buildColorCircle(String hexColor) {
    Color color;
    try {
      color = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      // If not a valid hex color, return empty container
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
    );
  }
}
