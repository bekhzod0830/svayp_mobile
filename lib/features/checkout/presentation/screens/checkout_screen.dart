import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/cart/data/models/cart_item_model.dart';
import 'package:swipe/features/cart/data/services/cart_service.dart';
import 'package:swipe/features/address/data/models/address_model.dart';
import 'package:swipe/features/address/data/services/address_service.dart';
import 'package:swipe/features/address/presentation/screens/address_list_screen.dart';
import 'package:swipe/features/payment/data/models/payment_method_model.dart';
import 'package:swipe/features/payment/data/services/payment_method_service.dart';
import 'package:swipe/features/orders/data/services/order_service.dart';
import 'package:swipe/features/checkout/presentation/screens/order_confirmation_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/services/seen_products_service.dart';
import 'package:swipe/core/di/service_locator.dart';
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

/// Helper function to format checkout item price using the currency field from the API
String _formatCheckoutItemPrice(CartItemModel item) {
  final currency = item.currency;
  final double totalPrice = item.totalPrice;

  if (currency == 'USD') {
    return '\$${totalPrice.toStringAsFixed(2)}';
  }
  return '${totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
}

/// Checkout Screen - Final review before placing order
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final AddressService _addressService = AddressService();
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final ProductApiService _apiService = ProductApiService();
  late final OrderService _orderService;

  List<CartItemModel> _cartItems = [];
  AddressModel? _selectedAddress;
  PaymentMethodModel? _selectedPaymentMethod;
  String _deliveryMethod = 'pickup'; // pickup is now the default
  bool _isLoading = true;
  bool _isPlacingOrder = false;
  double _subtotalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize ApiClient for OrderService
    final prefs = await SharedPreferences.getInstance();
    final apiClient = ApiClient(prefs);
    _orderService = OrderService(apiClient);

    await _loadCheckoutData();
  }

  Future<void> _loadCheckoutData() async {
    if (!mounted) return;

    // ── Step 1: show local cache immediately so the screen is never blank ──
    await _cartService.init();
    await _addressService.init();
    await _paymentMethodService.init();

    final cachedItems = _cartService.getCartItems();
    final cachedSubtotal = _cartService.getSubtotal();

    if (!mounted) return;
    setState(() {
      _cartItems = cachedItems;
      _subtotalAmount = cachedSubtotal;
      _selectedAddress = _addressService.getDefaultAddress();
      _selectedPaymentMethod = _paymentMethodService.getDefaultPaymentMethod();
      _isLoading = false;
    });

    // ── Step 2: fetch fresh data from API in background ──
    try {
      final apiClient = getIt<ApiClient>();
      final token = apiClient.getToken();

      if (token == null || token.isEmpty) return;

      final cartData = await _apiService.getCart(token: token);

      final items = cartData['items'] as List<dynamic>;
      final summary = cartData['summary'] as Map<String, dynamic>;
      final subtotal = (summary['subtotal'] as num?)?.toDouble() ?? 0.0;

      // Build a lookup keyed by productId|size|color so the same product
      // added with different variations stays as separate entries.
      String _variantKey(String productId, String size, String? color) =>
          '$productId|$size|${color ?? ''}';

      final cachedByVariant = {
        for (var c in _cartItems)
          _variantKey(c.productId, c.selectedSize, c.selectedColor): c,
      };

      final apiItemByVariant = <String, CartItemModel>{};
      for (final item in items) {
        final product = item['product'] as Map<String, dynamic>;
        final productId = product['id']?.toString() ?? '';
        final size = (item['selected_size'] as String? ?? '');
        final color = item['selected_color'] as String?;
        final variantKey = _variantKey(productId, size, color);

        final cachedItem = cachedByVariant[variantKey];
        final apiBrand = (product['brand'] as String?) ?? '';
        final apiSeller = (product['seller'] as String?) ?? '';
        // Mirror _convertApiProduct: prefer brand, fall back to seller, then cached.
        final resolvedBrand = (apiBrand.isNotEmpty && apiBrand != 'Unknown')
            ? apiBrand
            : apiSeller.isNotEmpty
            ? apiSeller
            : (cachedItem?.brand ?? '');

        apiItemByVariant[variantKey] = CartItemModel(
          productId: productId,
          brand: resolvedBrand,
          title: (product['title'] as String? ?? 'Unknown'),
          price: ((product['price'] as num?)?.toInt() ?? 0),
          currency: (product['currency'] as String? ?? 'UZS'),
          imageUrl: (product['images'] as List?)?.isNotEmpty == true
              ? (product['images'][0] as String? ?? '')
              : (cachedItem?.imageUrl ?? ''),
          quantity: (item['quantity'] as int? ?? 1),
          selectedSize: size,
          selectedColor: color,
          category: (cachedItem?.category ?? ''),
          titleLocalized: (product['title_localized'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value.toString())),
          descriptionLocalized:
              (product['description_localized'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, value.toString()),
              ),
          addedAt: item['created_at'] != null
              ? DateTime.tryParse(item['created_at'] as String) ??
                    DateTime.now()
              : DateTime.now(),
        );
      }

      if (!mounted) return;
      if (apiItemByVariant.isNotEmpty) {
        // Merge: preserve cached display order, replace data for matching
        // variant keys, drop items no longer in the API response.
        final merged = _cartItems
            .map(
              (c) =>
                  apiItemByVariant[_variantKey(
                    c.productId,
                    c.selectedSize,
                    c.selectedColor,
                  )] ??
                  c,
            )
            .where(
              (c) => apiItemByVariant.containsKey(
                _variantKey(c.productId, c.selectedSize, c.selectedColor),
              ),
            )
            .toList();
        // Append any new variants that weren't in the cached list.
        for (final entry in apiItemByVariant.entries) {
          if (!merged.any(
            (c) =>
                _variantKey(c.productId, c.selectedSize, c.selectedColor) ==
                entry.key,
          )) {
            merged.add(entry.value);
          }
        }
        setState(() {
          _cartItems = merged;
          _subtotalAmount = subtotal;
        });
      }
    } catch (_) {
      // API failed – cached data is already showing, nothing more to do.
    }
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.of(context).push<AddressModel>(
      MaterialPageRoute(
        builder: (context) => AddressListScreen(
          isSelectionMode: true,
          selectedAddressId: _selectedAddress?.id,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAddress = result;
      });
    }
  }

  Future<void> _selectPaymentMethod() async {
    final l10n = AppLocalizations.of(context)!;
    // TODO: Navigate to payment method selection screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.paymentSelectionComingSoon)));
  }

  double get _subtotal => _subtotalAmount;

  double get _deliveryFee {
    switch (_deliveryMethod) {
      case 'pickup':
        return 0; // Pickup is always free
      case 'standard':
        return _subtotal >= 500000 ? 0 : 30000;
      case 'express':
        return 50000;
      case 'sameday':
        return 100000;
      default:
        return 0; // Default to free
    }
  }

  double get _total => _subtotal + _deliveryFee;

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

  /// Format individual cart item price with intelligent currency detection

  Future<void> _placeOrder() async {
    final l10n = AppLocalizations.of(context)!;

    // Only require address if NOT pickup (pickup in store doesn't need delivery address)
    if (_deliveryMethod != 'pickup' && _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectDeliveryAddress),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectPaymentMethod),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      // Place order via API (cart items are read from server-side cart)
      final orderResponse = await _orderService.placeOrderApi(
        addressId: _selectedAddress?.id,
        deliveryMethod: _deliveryMethod,
        paymentMethod: _selectedPaymentMethod!.id,
      );

      // Extract order details from response
      final orderNumber =
          orderResponse['orderNumber']?.toString() ??
          orderResponse['order_number']?.toString() ??
          '#SW${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Parse status from response or default to confirmed
      final status = orderResponse['status']?.toString() ?? 'confirmed';

      // Get items count from response or local cart
      final responseItems = orderResponse['items'] as List?;
      final itemsCount = responseItems?.length ?? _cartItems.length;

      // Order is already saved on the server via placeOrderApi()
      // No need to save locally anymore - orders are fetched from API

      // Persist purchased product IDs so the discovery feed excludes them
      await SeenProductsService.addSeenIds(
        _cartItems.map((item) => item.productId),
      );

      // Clear cart after successful order
      await _cartService.clearCart();

      if (mounted) {
        // Navigate to order confirmation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderNumber: orderNumber,
              totalAmount: _total,
              status: status,
              itemsCount: itemsCount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorPlacingOrder(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
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
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _buildBottomBar(l10n),
      body: Stack(
        children: [
          // ── Content ─────────────────────────────────────────────
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    headerTotal + 8,
                    16,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  children: [
                    // Delivery Method Section
                    _buildDeliveryMethodSection(l10n),
                    const SizedBox(height: 16),

                    // Payment Method Section
                    _buildPaymentMethodSection(l10n),
                    const SizedBox(height: 16),

                    // Order Items Section
                    _buildOrderItemsSection(l10n),
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
                            l10n.checkout,
                            style: AppTypography.heading3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
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

  Widget _buildDeliveryAddressSection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
                Text(
                  l10n.deliveryAddress,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_selectedAddress != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedAddress!.fullName,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAddress!.phoneNumber,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedAddress!.formattedAddress,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray700,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.noAddressSelected,
                style: AppTypography.body2.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray600,
                ),
              ),
            ),
          const Divider(height: 1),
          InkWell(
            onTap: _selectAddress,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedAddress == null ? Icons.add : Icons.edit_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedAddress == null
                        ? l10n.addAddress
                        : l10n.changeAddress,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMethodSection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.store, color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
                Text(
                  l10n.deliveryMethod,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Only show Pick up in store option
          _buildDeliveryOption(
            'pickup',
            l10n.pickupInStore,
            l10n.availableForPickup,
            0,
            l10n: l10n,
          ),
          // Other delivery methods - DISABLED FOR NOW
          // _buildDeliveryOption(
          //   'standard',
          //   l10n.standardDelivery,
          //   l10n.businessDays(3, 5),
          //   _subtotal >= 500000 ? 0 : 30000,
          //   l10n: l10n,
          // ),
          // _buildDeliveryOption(
          //   'express',
          //   l10n.expressDelivery,
          //   l10n.businessDays(1, 2),
          //   50000,
          //   l10n: l10n,
          // ),
          // _buildDeliveryOption(
          //   'sameday',
          //   l10n.sameDayDelivery,
          //   l10n.tashkentOnly,
          //   100000,
          //   l10n: l10n,
          // ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(
    String value,
    String title,
    String subtitle,
    double price, {
    AppLocalizations? l10n,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _deliveryMethod == value;
    final isFree = price == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
          ),
        ),
      ),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: _deliveryMethod,
            onChanged: null, // Disabled since it's the only option
            activeColor: isDark ? AppColors.white : AppColors.black,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body1.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isFree ? (l10n?.free ?? 'FREE') : _getFormattedPrice(price, 'UZS'),
            style: AppTypography.body2.copyWith(
              fontWeight: FontWeight.w600,
              color: isFree ? Colors.green : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.payment, color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
                Text(
                  l10n.paymentMethod,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_selectedPaymentMethod != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.darkStandardBorder
                        : AppColors.gray200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'cashOnDelivery',
                    groupValue: 'cashOnDelivery',
                    onChanged: null, // Disabled since it's the only option
                    activeColor: isDark ? AppColors.white : AppColors.black,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPaymentMethod!.type == 'cashOnDelivery'
                              ? l10n.cashOnDelivery
                              : _selectedPaymentMethod!.displayName,
                          style: AppTypography.body1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _selectedPaymentMethod!.type == 'cashOnDelivery'
                              ? l10n.payWhenYouReceive
                              : (_selectedPaymentMethod!
                                        .displaySubtitle
                                        .isNotEmpty
                                    ? _selectedPaymentMethod!.displaySubtitle
                                    : ''),
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.noPaymentMethodSelected,
                style: AppTypography.body2.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray600,
                ),
              ),
            ),
          // Divider and Change Payment button - DISABLED FOR NOW
          // const Divider(height: 1),
          // InkWell(
          //   onTap: _selectPaymentMethod,
          //   child: Padding(
          //     padding: const EdgeInsets.all(16),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Icon(
          //           _selectedPaymentMethod == null
          //               ? Icons.add
          //               : Icons.edit_outlined,
          //           size: 18,
          //           color: theme.colorScheme.onSurface,
          //         ),
          //         const SizedBox(width: 8),
          //         Text(
          //           _selectedPaymentMethod == null
          //               ? l10n.addPayment
          //               : l10n.changePayment,
          //           style: AppTypography.body2.copyWith(
          //             fontWeight: FontWeight.w600,
          //             color: theme.colorScheme.onSurface,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.orderItems(_cartItems.length),
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._cartItems.map((item) => _buildOrderItemCard(item, l10n)),
        ],
      ),
    );
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

  Widget _buildOrderItemCard(CartItemModel item, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openProductDetail(item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
            ),
          ),
        ),
        child: Row(
          children: [
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
                    ),
                  ),
                  Text(
                    item.localizedTitle(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Line 1: Size
                  Text(
                    '${l10n.size}: ${_formatSizeLabel(item.selectedSize)}',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Line 2: Color + Quantity
                  Row(
                    children: [
                      if (item.selectedColor != null) ...[
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
                        const SizedBox(width: 10),
                      ],
                      Text(
                        '${l10n.qty}: ${item.quantity}',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              _formatCheckoutItemPrice(item),
              style: AppTypography.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummarySection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orderSummary,
            style: AppTypography.body1.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // USD Subtotal (if present)
          if (_hasUsdProducts) ...[
            _buildSummaryRow(
              _hasUzsProducts ? '${l10n.subtotal} (USD)' : l10n.subtotal,
              _usdSubtotal,
              'USD',
            ),
            const SizedBox(height: 8),
          ],

          // UZS Subtotal (if present)
          if (_hasUzsProducts) ...[
            _buildSummaryRow(
              _hasUsdProducts ? '${l10n.subtotal} (UZS)' : l10n.subtotal,
              _uzsSubtotal,
              'UZS',
            ),
            const SizedBox(height: 8),
          ],

          // Delivery Fee (shown for each currency if applicable)
          if (_hasUsdProducts && _deliveryFee > 0) ...[
            _buildSummaryRow(
              _hasUzsProducts ? '${l10n.deliveryFee} (USD)' : l10n.deliveryFee,
              0, // Convert to USD if needed, for now 0
              'USD',
            ),
            const SizedBox(height: 8),
          ],

          if (_hasUzsProducts) ...[
            _buildSummaryRow(
              _hasUsdProducts ? '${l10n.deliveryFee} (UZS)' : l10n.deliveryFee,
              _deliveryFee,
              'UZS',
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 4),
          const Divider(),
          const SizedBox(height: 12),

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
                  _getFormattedPrice(_usdSubtotal, 'USD'),
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
                  _getFormattedPrice(_uzsSubtotal + _deliveryFee, 'UZS'),
                  style: AppTypography.heading4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, String currency) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.body2.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray700,
          ),
        ),
        Text(
          _getFormattedPrice(amount, currency),
          style: AppTypography.body2.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Order summary rows ────────────────────────────
              if (_hasUsdProducts) ...[
                _buildSummaryRow(
                  _hasUzsProducts ? '${l10n.subtotal} (USD)' : l10n.subtotal,
                  _usdSubtotal,
                  'USD',
                ),
                const SizedBox(height: 8),
              ],
              if (_hasUzsProducts) ...[
                _buildSummaryRow(
                  _hasUsdProducts ? '${l10n.subtotal} (UZS)' : l10n.subtotal,
                  _uzsSubtotal,
                  'UZS',
                ),
                const SizedBox(height: 8),
              ],
              if (_hasUzsProducts) ...[
                _buildSummaryRow(
                  _hasUsdProducts
                      ? '${l10n.deliveryFee} (UZS)'
                      : l10n.deliveryFee,
                  _deliveryFee,
                  'UZS',
                ),
                const SizedBox(height: 4),
              ],
              const Divider(),
              const SizedBox(height: 8),
              if (_hasUsdProducts) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _hasUzsProducts ? '${l10n.total} (USD)' : l10n.total,
                      style: AppTypography.heading4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _getFormattedPrice(_usdSubtotal, 'USD'),
                      style: AppTypography.heading4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                if (_hasUzsProducts) const SizedBox(height: 8),
              ],
              if (_hasUzsProducts) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _hasUsdProducts ? '${l10n.total} (UZS)' : l10n.total,
                      style: AppTypography.heading4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _getFormattedPrice(_uzsSubtotal + _deliveryFee, 'UZS'),
                      style: AppTypography.heading4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // ── Place Order button ────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : AppColors.black,
                    foregroundColor: isDark ? AppColors.black : AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    disabledBackgroundColor: AppColors.gray400,
                    elevation: 0,
                  ),
                  child: _isPlacingOrder
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? AppColors.black : AppColors.white,
                          ),
                        )
                      : Text(
                          l10n.placeOrder,
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
