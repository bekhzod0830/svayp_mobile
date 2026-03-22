import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/l10n/app_localizations.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;
  final String type;
  final String? entityId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.type,
    this.entityId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      type: json['type'] as String? ?? 'SYSTEM',
      entityId: json['entity_id'] as String?,
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

/// Notifications History Screen.
/// Fetches data from GET /notifications and supports mark-as-read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiClient _api = getIt<ApiClient>();

  List<NotificationItem> _items = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  // ─── API calls ─────────────────────────────────────────────────────────────

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await Future.wait([_fetchNotifications(), _fetchUnreadCount()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await _api.get<dynamic>(
        '/notifications',
        queryParameters: {'page': 0, 'size': 50},
      );
      final outer = response.data;
      // Response shape: { "data": { "data": [...], "pagination": {...} } }
      final List<dynamic> raw =
          (outer['data']?['data'] ?? outer['data'] ?? outer) as List<dynamic>;
      if (mounted) {
        setState(() {
          _items = raw
              .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await _api.get<dynamic>('/notifications/unread-count');
      final outer = response.data;
      // Response shape: { "data": { "unread_count": 5 } }
      final count =
          (outer['data']?['unread_count'] ?? outer['unread_count'] ?? 0) as int;
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _markAsRead(NotificationItem item) async {
    if (item.isRead) return;
    try {
      await _api.patch<dynamic>('/notifications/${item.id}/read');
      setState(() {
        item.isRead = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.patch<dynamic>('/notifications/read-all');
      setState(() {
        for (final n in _items) {
          n.isRead = true;
        }
        _unreadCount = 0;
      });
    } catch (_) {}
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  IconData _iconForType(String type) {
    switch (type) {
      case 'ORDER_UPDATE':
        return Icons.local_shipping_outlined;
      case 'NEW_MESSAGE':
        return Icons.chat_bubble_outline;
      case 'PRICE_DROP':
        return Icons.trending_down;
      case 'RESTOCK':
        return Icons.inventory_2_outlined;
      case 'NEW_ARRIVAL':
        return Icons.fiber_new_outlined;
      case 'RECOMMENDATION':
        return Icons.star_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorForType(String type, bool isDark) {
    switch (type) {
      case 'ORDER_UPDATE':
        return Colors.blue;
      case 'NEW_MESSAGE':
        return Colors.purple;
      case 'PRICE_DROP':
        return Colors.red;
      case 'RESTOCK':
        return Colors.orange;
      case 'NEW_ARRIVAL':
        return Colors.green;
      case 'RECOMMENDATION':
        return Colors.amber;
      default:
        return isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

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
            ? AppColors.darkCardBackground
            : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              l10n.notifications,
              style: AppTypography.heading3.copyWith(
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Read all',
                style: TextStyle(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  fontSize: 14,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/notification-preferences'),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError(isDark)
          : _items.isEmpty
          ? _buildEmptyState(isDark)
          : _buildList(isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 56,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load notifications',
            style: AppTypography.heading3.copyWith(
              color: isDark ? AppColors.darkPrimaryText : AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _fetchAll, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 72,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTypography.heading3.copyWith(
              color: isDark ? AppColors.darkPrimaryText : AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see order updates, price drops,\nand messages here.',
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? AppColors.darkLightBorder : AppColors.lightBorder,
          indent: 72,
        ),
        itemBuilder: (context, index) {
          final item = _items[index];
          final icon = _iconForType(item.type);
          final color = _colorForType(item.type, isDark);

          return InkWell(
            onTap: () => _markAsRead(item),
            child: ListTile(
              tileColor: item.isRead
                  ? Colors.transparent
                  : (isDark
                        ? AppColors.darkCardBackground.withValues(alpha: 0.4)
                        : color.withValues(alpha: 0.05)),
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (!item.isRead)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                item.title,
                style: AppTypography.body1.copyWith(
                  fontWeight: item.isRead ? FontWeight.normal : FontWeight.w600,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(item.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
