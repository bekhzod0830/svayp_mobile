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
import 'package:swipe/core/di/service_locator.dart';

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
    setState(() {
      _isLoading = true;
    });

    List<CartItemModel> cartItems = [];
    double subtotal = 0.0;

    try {
      // Get auth token
      final apiClient = getIt<ApiClient>();
      final token = apiClient.getToken();

      if (token != null && token.isNotEmpty) {
        // Fetch cart from API
        final cartData = await _apiService.getCart(token: token);

        final items = cartData['items'] as List<dynamic>;
        final summary = cartData['summary'] as Map<String, dynamic>;

        // Get subtotal from API response
        subtotal = (summary['subtotal'] as num?)?.toDouble() ?? 0.0;

        // Convert API items to CartItemModel
        cartItems = items.map((item) {
          final product = item['product'] as Map<String, dynamic>;

          return CartItemModel(
            productId: (product['id']?.toString() ?? ''),
            brand: (product['brand'] as String? ?? ''),
            title: (product['title'] as String? ?? 'Unknown'),
            price: (product['price'] as int? ?? 0),
            imageUrl: (product['images'] as List?)?.isNotEmpty == true
                ? (product['images'][0] as String? ?? '')
                : '',
            quantity: (item['quantity'] as int? ?? 1),
            selectedSize: (item['selected_size'] as String? ?? ''),
            selectedColor: item['selected_color'] as String?,
            category: '',
            addedAt: item['created_at'] != null
                ? DateTime.tryParse(item['created_at'] as String) ??
                      DateTime.now()
                : DateTime.now(),
          );
        }).toList();
      } else {
        // Not authenticated, use local cache
        await _cartService.init();
        cartItems = _cartService.getCartItems();
        subtotal = _cartService.getSubtotal();
      }
    } catch (e) {
      // Fallback to local cache
      await _cartService.init();
      cartItems = _cartService.getCartItems();
      subtotal = _cartService.getSubtotal();
    }

    await _addressService.init();
    await _paymentMethodService.init();

    setState(() {
      _cartItems = cartItems;
      _subtotalAmount = subtotal;
      _selectedAddress = _addressService.getDefaultAddress();
      _selectedPaymentMethod = _paymentMethodService.getDefaultPaymentMethod();
      _isLoading = false;
    });
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

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.checkout,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.white : AppColors.black,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Delivery Address Section - DISABLED FOR NOW
                // _buildDeliveryAddressSection(l10n),
                // const SizedBox(height: 16),

                // Delivery Method Section
                _buildDeliveryMethodSection(l10n),
                const SizedBox(height: 16),

                // Payment Method Section
                _buildPaymentMethodSection(l10n),
                const SizedBox(height: 16),

                // Order Items Section
                _buildOrderItemsSection(l10n),
                const SizedBox(height: 16),

                // Order Summary Section
                _buildOrderSummarySection(l10n),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
      bottomNavigationBar: _buildBottomBar(l10n),
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
            isFree
                ? (l10n?.free ?? 'FREE')
                : '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
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

  Widget _buildOrderItemCard(CartItemModel item, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: isDark ? AppColors.darkMainBackground : Colors.white,
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                cacheManager: ImageCacheManager.instance,
                memCacheWidth: 120,
                memCacheHeight: 120,
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
                  item.title,
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Size and Color
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '${l10n.size}: ${item.selectedSize}',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.gray600,
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
                    ),
                    const SizedBox(width: 8),
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
            '${item.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
            style: AppTypography.body2.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
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
          _buildSummaryRow(l10n.subtotal, _subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow(l10n.deliveryFee, _deliveryFee),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
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
          '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : AppColors.black).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.white : AppColors.black,
            foregroundColor: isDark ? AppColors.black : AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: AppColors.gray400,
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
