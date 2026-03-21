import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// A model for a single notification item displayed in the history list.
/// Will be populated from GET /api/v1/notifications once the backend endpoint exists.
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String type;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.type,
  });
}

/// Notifications History Screen.
/// Currently shows an empty state — wire [_items] to the backend when ready.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // TODO: Replace with a BLoC / Cubit that fetches GET /api/v1/notifications
  final List<NotificationItem> _items = [];
  final bool _isLoading = false;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkMainBackground : AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkCardBackground : AppColors.white,
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
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/notification-preferences'),
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
          : _items.isEmpty
              ? _buildEmptyState(isDark)
              : _buildList(isDark),
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
            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
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
    return ListView.separated(
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

        return ListTile(
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
        );
      },
    );
  }
}
