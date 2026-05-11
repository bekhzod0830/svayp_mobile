import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/services/badge_notifier.dart';
import 'package:swipe/core/services/notification_service.dart';
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
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? json['message'] as String? ?? '',
      body: json['body'] as String? ?? json['description'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
      final apiItems = raw
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();

      // Merge locally stored notifications (from FCM foreground messages
      // that the backend may not have stored in the DB).
      final localRaw = await NotificationService.loadLocalNotifications();
      final localItems = localRaw
          .map((e) => NotificationItem.fromJson(e))
          .where((local) {
            // Skip if there's an API item with the same title + body
            // received within 5 minutes (dedup backend-stored ones).
            return !apiItems.any(
              (api) =>
                  api.title == local.title &&
                  api.body == local.body &&
                  api.createdAt.difference(local.createdAt).abs() <
                      const Duration(minutes: 5),
            );
          })
          .toList();

      // Merge and sort newest first.
      final merged = [...apiItems, ...localItems]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _items = merged;
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
      // Sync the bell badge on the top bar.
      if (count > 0) {
        BadgeNotifier.instance.markUnreadNotifications();
      } else {
        BadgeNotifier.instance.clearUnreadNotifications();
      }
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
      await NotificationService.markLocalNotificationsRead();
      setState(() {
        for (final n in _items) {
          n.isRead = true;
        }
        _unreadCount = 0;
      });
      BadgeNotifier.instance.clearUnreadNotifications();
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

  String _timeAgo(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.chatLastSeenJustNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
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
        title: Text(
          l10n.notifications,
          style: AppTypography.heading3.copyWith(
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                l10n.notificationsReadAll,
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.notificationsLoadError,
            style: AppTypography.heading3.copyWith(
              color: isDark ? AppColors.darkPrimaryText : AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _fetchAll, child: Text(l10n.retry)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.notificationsEmpty,
            style: AppTypography.heading3.copyWith(
              color: isDark ? AppColors.darkPrimaryText : AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.notificationsEmptySubtitle,
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
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 22),
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
                    _timeAgo(context, item.createdAt),
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
