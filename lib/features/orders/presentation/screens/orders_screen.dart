import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/orders/data/models/order_model.dart';
import 'package:swipe/features/orders/data/services/order_service.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';
import 'package:swipe/features/chat/presentation/screens/chat_list_screen.dart';

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
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0 = Chat, 1 = Orders
  int _chatRefreshKey = 0; // Counter to force ChatListScreen rebuild

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    });

    await _orderService.init();

    if (!mounted) return;

    setState(() {
      _orders = _orderService.getOrders();
      _isLoading = false;
    });
  }

  /// Public method to refresh orders (can be called from parent)
  @override
  void refresh() {
    if (mounted) {
      _loadOrders();
      // Increment refresh key to force ChatListScreen rebuild
      setState(() {
        _chatRefreshKey++;
      });
    }
  }

  void _onOrderTap(OrderModel order) {
    // Show order details in bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => _OrderDetailSheet(order: order),
    );
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
            // Header with Tab Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  // Tab Buttons
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardBackground
                          : AppColors.gray100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        // Chat Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 0;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 0
                                    ? (isDark
                                          ? AppColors.white
                                          : AppColors.black)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.chat,
                                style: AppTypography.button.copyWith(
                                  color: _selectedTabIndex == 0
                                      ? (isDark
                                            ? AppColors.black
                                            : AppColors.white)
                                      : (isDark
                                            ? AppColors.darkSecondaryText
                                            : AppColors.gray600),
                                  fontWeight: _selectedTabIndex == 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Orders Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 1;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 1
                                    ? (isDark
                                          ? AppColors.white
                                          : AppColors.black)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.myOrders,
                                style: AppTypography.button.copyWith(
                                  color: _selectedTabIndex == 1
                                      ? (isDark
                                            ? AppColors.black
                                            : AppColors.white)
                                      : (isDark
                                            ? AppColors.darkSecondaryText
                                            : AppColors.gray600),
                                  fontWeight: _selectedTabIndex == 1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedTabIndex == 1) ...[
                    const SizedBox(height: 12),
                    // Order count subtitle (only show for orders tab)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_orders.length} ${_orders.length == 1 ? "order" : "orders"}',
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Content
            Expanded(
              child: _selectedTabIndex == 0
                  ? ChatListScreen(key: ValueKey(_chatRefreshKey))
                  : _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                      ),
                    )
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
              Icons.receipt_long_outlined,
              size: 100,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noOrdersYet,
              style: AppTypography.heading3.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.orderHistoryAppearHere,
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
                // Navigate to Discover tab (index 0)
                final mainScreenState = context
                    .findAncestorStateOfType<MainScreenState>();
                if (mainScreenState != null) {
                  mainScreenState.navigateToTab(0);
                }
              },
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
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.startShopping),
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

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.l10n,
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
                  Text(
                    order.id,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: order.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.getLocalizedStatus(context),
                      style: AppTypography.caption.copyWith(
                        color: order.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

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
                    _formatDate(order.orderDate),
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

              // Total and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        order.formattedTotal,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
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
class _OrderDetailSheet extends StatelessWidget {
  final OrderModel order;

  const _OrderDetailSheet({required this.order});

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
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Order ID
          Text(
            '${l10n.order} ${order.id}',
            style: AppTypography.heading4.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: order.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.getLocalizedStatus(context),
              style: AppTypography.body2.copyWith(
                color: order.statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tracking Number
          if (order.trackingNumber != null) ...[
            _DetailRow(
              label: l10n.trackingNumber,
              value: order.trackingNumber!,
            ),
            const SizedBox(height: 12),
          ],

          // Item Count
          _DetailRow(
            label: l10n.items,
            value: '${order.itemCount} ${l10n.products}',
          ),
          const SizedBox(height: 12),

          // Total
          _DetailRow(label: l10n.total, value: order.formattedTotal),

          const SizedBox(height: 24),

          // Action Button
          if (order.trackingNumber != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Track order
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.trackingComingSoon)),
                  );
                },
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: Text(l10n.track),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
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
      children: [
        Text(
          label,
          style: AppTypography.body2.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
          ),
        ),
        Text(
          value,
          style: AppTypography.body2.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
