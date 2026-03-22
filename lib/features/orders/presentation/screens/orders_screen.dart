import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/orders/data/models/order_model.dart';
import 'package:swipe/features/orders/data/services/order_service.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper function to format a price with the given currency code
String _formatItemPrice(double price, String currency) {
  if (currency == 'USD') {
    return '\$${price.toStringAsFixed(2)}';
  }
  return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
}

/// Helper function to format order total using the order's own currency
String _formatOrderTotal(OrderModel order) {
  final total = order.items.fold(0.0, (sum, item) => sum + item.subtotal);
  return _formatItemPrice(total, order.currency);
}

/// Refreshable interface for orders screen
abstract class Refreshable {
  void refresh();
}

/// Orders Screen - Order history, tracking, and chat with sellers
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver
    implements Refreshable {
  late final OrderService _orderService;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isPartner = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize OrderService with ApiClient
    final apiClient = getIt<ApiClient>();
    _orderService = OrderService(apiClient);
    _isPartner = apiClient.isPartnerLogin();
    _loadOrders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes back to foreground
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch orders from API
      final orders = _isPartner
          ? await _orderService.fetchAdminOrders()
          : await _orderService.fetchOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to load orders. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  /// Public method to refresh orders (can be called from parent)
  @override
  void refresh() {
    if (mounted) {
      _loadOrders();
    }
  }

  void _onOrderTap(OrderModel order) {
    // Show order details in bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) =>
          _OrderDetailSheet(order: order, isPartner: _isPartner),
    );
  }

  Future<void> _onChangeStatusTap(OrderModel order) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor(String s) {
      switch (s.toUpperCase()) {
        case 'WAITING':
          return const Color(0xFFFF9800);
        case 'CONFIRMED':
          return const Color(0xFF2196F3);
        case 'READY_TO_SHIP':
          return const Color(0xFF009688);
        case 'READY_FOR_PICKUP':
          return const Color(0xFF00BCD4);
        case 'SHIPPED':
          return const Color(0xFF3F51B5);
        case 'DELIVERED':
          return const Color(0xFF8BC34A);
        case 'COMPLETED':
          return const Color(0xFF4CAF50);
        case 'CANCELLED':
          return const Color(0xFFF44336);
        case 'RETURNED':
          return const Color(0xFF9E9E9E);
        case 'VOIDED':
          return const Color(0xFF607D8B);
        default:
          return const Color(0xFFFF9800);
      }
    }

    final statuses = [
      ('WAITING', l10n.waiting),
      ('CONFIRMED', l10n.confirmed),
      ('READY_TO_SHIP', l10n.readyToShip),
      ('READY_FOR_PICKUP', l10n.readyForPickup),
      ('SHIPPED', l10n.shipped),
      ('DELIVERED', l10n.delivered),
      ('COMPLETED', l10n.completed),
      ('CANCELLED', l10n.cancelled),
      ('RETURNED', l10n.returned),
      ('VOIDED', l10n.voided),
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? AppColors.darkCardBackground : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.changeStatus,
                  style: AppTypography.heading4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...statuses.map((entry) {
                        final (apiValue, label) = entry;
                        final isCurrent =
                            apiValue == order.status.toUpperCase();
                        final color = statusColor(apiValue);
                        return ListTile(
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                            label,
                            style: AppTypography.body1.copyWith(
                              color: isCurrent
                                  ? color
                                  : theme.colorScheme.onSurface,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: isCurrent
                              ? Icon(Icons.check_rounded, color: color)
                              : null,
                          onTap: () => Navigator.of(ctx).pop(apiValue),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == order.status.toUpperCase()) return;
    if (!mounted) return;

    try {
      await _orderService.updateOrderStatus(order.id, selected);
      if (mounted) _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGenericSubtitle),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.orders,
                          style: AppTypography.heading2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.ordersCount(_orders.length),
                          style: AppTypography.body2.copyWith(
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
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                      ),
                    )
                  : _errorMessage != null
                  ? _buildErrorState(l10n, _errorMessage!)
                  : _orders.isEmpty
                  ? _buildEmptyState(l10n)
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _OrderCard(
                            order: order,
                            onTap: () => _onOrderTap(order),
                            l10n: l10n,
                            isPartner: _isPartner,
                            onChangeStatus: _isPartner
                                ? () => _onChangeStatusTap(order)
                                : null,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, String errorMessage) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.errorGenericTitle,
              style: AppTypography.heading3.copyWith(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.errorGenericSubtitle,
              style: AppTypography.body2.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.black,
                foregroundColor: isDark ? AppColors.black : AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                l10n.errorRetry,
                style: AppTypography.body1.copyWith(
                  color: isDark ? AppColors.black : AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPartner ? Icons.inbox_outlined : Icons.receipt_long_outlined,
              size: 100,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              _isPartner ? l10n.noOrdersReceivedYet : l10n.noOrdersYet,
              style: AppTypography.heading3.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _isPartner
                  ? l10n.customerOrdersAppearHere
                  : l10n.orderHistoryAppearHere,
              style: AppTypography.body1.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Order Card Widget
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final AppLocalizations l10n;
  final bool isPartner;
  final VoidCallback? onChangeStatus;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.l10n,
    this.isPartner = false,
    this.onChangeStatus,
  });

  String _formatDate(DateTime date) {
    final months = [
      l10n.jan,
      l10n.feb,
      l10n.mar,
      l10n.apr,
      l10n.may,
      l10n.jun,
      l10n.jul,
      l10n.aug,
      l10n.sep,
      l10n.oct,
      l10n.nov,
      l10n.dec,
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.order,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.orderNumber,
                          style: AppTypography.body1.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),

              const SizedBox(height: 12),

              // Customer info row (partner/seller view)
              if (isPartner && order.clientName != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.clientPhone != null
                            ? '${order.clientName!}  •  ${order.clientPhone!}'
                            : order.clientName!,
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Delivery Method and Payment Method
              Row(
                children: [
                  Icon(
                    order.deliveryMethod.toUpperCase() == 'PICKUP'
                        ? Icons.store_outlined
                        : Icons.local_shipping_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    order.getLocalizedDeliveryMethod(context),
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    order.paymentMethod.toUpperCase() == 'CASH'
                        ? Icons.money_outlined
                        : Icons.credit_card_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    order.getLocalizedPaymentMethod(context),
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Date and Item Count
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(order.createdAt),
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.itemsCount(order.itemCount),
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Total Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalAmount,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatOrderTotal(order),
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // View Details Button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            fixedSize: const Size.fromHeight(48),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.black,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            l10n.viewDetails,
                            style: AppTypography.body2.copyWith(
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (onChangeStatus != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: onChangeStatus,
                          style: OutlinedButton.styleFrom(
                            fixedSize: const Size(72, 48),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.black,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            size: 22,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Order Detail Bottom Sheet
class _OrderDetailSheet extends StatefulWidget {
  final OrderModel order;
  final bool isPartner;

  const _OrderDetailSheet({required this.order, this.isPartner = false});

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  bool _itemsExpanded = false;
  late String _currentStatus; // tracks optimistic status update
  bool _isOpeningProduct = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  Future<void> _openProductDetail(OrderItemModel item) async {
    if (_isOpeningProduct || !mounted) return;
    setState(() => _isOpeningProduct = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Show loading overlay
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final apiService = ProductApiService();
      final api_models.Product apiProduct =
          await apiService.getProductById(item.productId, token: token);

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
        images: apiProduct.images.isNotEmpty ? apiProduct.images : [],
        category:
            apiProduct.originalCategoryString ?? apiProduct.category.value,
        subcategory:
            apiProduct.subcategory?.map((s) => s.displayName).toList(),
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

      if (mounted) navigator.pop(); // dismiss loader
      if (mounted) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      }
    } catch (_) {
      if (mounted) navigator.pop(); // dismiss loader
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not load product details. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningProduct = false);
    }
  }

  // Calculate items subtotal
  double get _itemsSubtotal {
    return widget.order.items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Order Number
            Text(
              '${l10n.order} ${widget.order.orderNumber}',
              style: AppTypography.heading4.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Status badge (tracks optimistic update)
            _StatusBadge(status: _currentStatus),

            const SizedBox(height: 24),

            // Customer info box (partner/seller view only)
            if (widget.isPartner &&
                (widget.order.clientName != null ||
                    widget.order.clientPhone != null)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkMainBackground
                      : AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.order.clientName != null)
                      _DetailRow(
                        label: l10n.customerName,
                        value: widget.order.clientName!,
                      ),
                    if (widget.order.clientPhone != null) ...[
                      const SizedBox(height: 6),
                      _DetailRow(
                        label: l10n.customerPhone,
                        value: widget.order.clientPhone!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Delivery Method
            _DetailRow(
              label: l10n.deliveryMethod,
              value: widget.order.getLocalizedDeliveryMethod(context),
            ),
            const SizedBox(height: 12),

            // Payment Method
            _DetailRow(
              label: l10n.paymentMethod,
              value: widget.order.getLocalizedPaymentMethod(context),
            ),
            const SizedBox(height: 12),

            // Total Amount
            _DetailRow(
              label: l10n.totalAmount,
              value: _formatItemPrice(_itemsSubtotal, widget.order.currency),
            ),

            const SizedBox(height: 24),

            // Items Section
            InkWell(
              onTap: () {
                setState(() {
                  _itemsExpanded = !_itemsExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.items} (${widget.order.itemCount})',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Icon(
                    _itemsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),

            // Expandable Items List
            if (_itemsExpanded) ...[
              const SizedBox(height: 16),
              ...widget.order.items.map((item) {
                return GestureDetector(
                  onTap: () => _openProductDetail(item),
                  child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkMainBackground
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image (3:4 aspect ratio)
                      if (item.productImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: item.productImage!,
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                            cacheManager: ImageCacheManager.instance,
                            memCacheWidth: 120,
                            memCacheHeight: 160,
                            errorWidget: (context, url, error) {
                              return Container(
                                width: 60,
                                height: 80,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.gray300,
                                child: const Icon(Icons.image),
                              );
                            },
                          ),
                        ),
                      const SizedBox(width: 12),

                      // Product Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.localizedTitle(
                                Localizations.localeOf(context).languageCode,
                              ),
                              style: AppTypography.body2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Size and Color
                            if (item.selectedSize != null ||
                                item.selectedColor != null)
                              Row(
                                children: [
                                  if (item.selectedSize != null) ...[
                                    Text(
                                      '${l10n.size}: ${item.selectedSize}',
                                      style: AppTypography.caption.copyWith(
                                        color: isDark
                                            ? AppColors.darkSecondaryText
                                            : AppColors.gray600,
                                      ),
                                    ),
                                  ],
                                  if (item.selectedSize != null &&
                                      item.selectedColor != null) ...[
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
                                  ],
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
                                  ],
                                ],
                              ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${l10n.qty}: ${item.quantity}',
                                  style: AppTypography.body2.copyWith(
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.gray600,
                                  ),
                                ),
                                Text(
                                  _formatItemPrice(item.subtotal, widget.order.currency),
                                  style: AppTypography.body2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
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
              }).toList(),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Build color circle widget from hex color string
  Widget _buildColorCircle(String hexColor) {
    Color color;
    try {
      final hex = hexColor.replaceAll('#', '');
      color = Color(int.parse('0xFF$hex'));
    } catch (e) {
      color = Colors.grey;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
    );
  }
}

/// Status Badge Widget - shows coloured pill for any status string
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'WAITING':
        return const Color(0xFFFF9800);
      case 'CONFIRMED':
        return const Color(0xFF2196F3);
      case 'READY_TO_SHIP':
        return const Color(0xFF009688);
      case 'READY_FOR_PICKUP':
        return const Color(0xFF00BCD4);
      case 'SHIPPED':
        return const Color(0xFF3F51B5);
      case 'DELIVERED':
        return const Color(0xFF8BC34A);
      case 'COMPLETED':
        return const Color(0xFF4CAF50);
      case 'CANCELLED':
        return const Color(0xFFF44336);
      case 'RETURNED':
        return const Color(0xFF9E9E9E);
      case 'VOIDED':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String _label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toUpperCase()) {
      case 'WAITING':
        return l10n.waiting;
      case 'CONFIRMED':
        return l10n.confirmed;
      case 'READY_TO_SHIP':
        return l10n.readyToShip;
      case 'READY_FOR_PICKUP':
        return l10n.readyForPickup;
      case 'SHIPPED':
        return l10n.shipped;
      case 'DELIVERED':
        return l10n.delivered;
      case 'COMPLETED':
        return l10n.completed;
      case 'CANCELLED':
        return l10n.cancelled;
      case 'RETURNED':
        return l10n.returned;
      case 'VOIDED':
        return l10n.voided;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(context),
        style: AppTypography.body2.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: AppTypography.body2.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
