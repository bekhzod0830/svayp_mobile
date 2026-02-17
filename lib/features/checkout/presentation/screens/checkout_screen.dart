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
import 'package:swipe/features/orders/data/models/order_model.dart';
import 'package:swipe/features/orders/data/services/order_service.dart';
import 'package:swipe/features/checkout/presentation/screens/order_confirmation_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';

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
  final OrderService _orderService = OrderService();

  List<CartItemModel> _cartItems = [];
  AddressModel? _selectedAddress;
  PaymentMethodModel? _selectedPaymentMethod;
  String _deliveryMethod = 'pickup'; // pickup is now the default
  bool _isLoading = true;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadCheckoutData();
  }

  Future<void> _loadCheckoutData() async {
    setState(() {
      _isLoading = true;
    });

    await _cartService.init();
    await _addressService.init();
    await _paymentMethodService.init();

    setState(() {
      _cartItems = _cartService.getCartItems();
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

  double get _subtotal => _cartService.getSubtotal();

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
      // Simulate API call to place order
      await Future.delayed(const Duration(seconds: 2));

      // Generate order ID
      final orderId =
          '#SW${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Calculate estimated delivery date based on delivery method
      int deliveryDays;
      switch (_deliveryMethod) {
        case 'pickup':
          deliveryDays = 0; // Available immediately for pickup
          break;
        case 'sameday':
          deliveryDays = 1;
          break;
        case 'express':
          deliveryDays = 2;
          break;
        default:
          deliveryDays = 5;
      }
      final estimatedDelivery = DateTime.now().add(
        Duration(days: deliveryDays),
      );

      // Create order model
      final order = OrderModel(
        id: orderId,
        items: List.from(_cartItems), // Create a copy of items
        orderDate: DateTime.now(),
        status: 'confirmed',
        subtotal: _subtotal,
        deliveryFee: _deliveryFee,
        total: _total,
        deliveryAddressId: _selectedAddress?.id ?? 'pickup',
        deliveryAddressName: _selectedAddress?.fullName ?? l10n.pickupInStore,
        deliveryAddressPhone: _selectedAddress?.phoneNumber ?? '',
        deliveryAddressFormatted:
            _selectedAddress?.formattedAddress ?? l10n.availableForPickup,
        paymentMethodId: _selectedPaymentMethod!.id,
        paymentMethodName: _selectedPaymentMethod!.displayName,
        deliveryMethod: _deliveryMethod,
        estimatedDeliveryDate: estimatedDelivery,
      );

      // Save order to database
      await _orderService.init();
      await _orderService.addOrder(order);

      // Clear cart after successful order
      await _cartService.clearCart();

      if (mounted) {
        // Navigate to order confirmation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                OrderConfirmationScreen(orderId: orderId, totalAmount: _total),
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
                    Expanded(
                      child: Text(
                        '${l10n.size}: ${item.selectedSize}${item.selectedColor != null ? ' • ${l10n.color}: ${item.selectedColor}' : ''}',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
}
