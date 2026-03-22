import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/enums/notification_type.dart';
import 'package:swipe/core/services/notification_preferences_service.dart';

/// Notification Preferences Screen.
/// One toggle per NotificationType, persisted via SharedPreferences.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final _prefs = NotificationPreferencesService.instance;

  // ─── Display helpers ──────────────────────────────────────────────────────

  String _label(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return 'Order Updates';
      case NotificationType.newMessage:
        return 'New Messages';
      case NotificationType.priceDrop:
        return 'Price Drops';
      case NotificationType.restock:
        return 'Back in Stock';
      case NotificationType.newArrival:
        return 'New Arrivals';
      case NotificationType.recommendation:
        return 'Recommendations';
      case NotificationType.system:
        return 'News & Announcements';
    }
  }

  String _description(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return 'Shipping, delivery, and refund updates';
      case NotificationType.newMessage:
        return 'Messages from support or partners';
      case NotificationType.priceDrop:
        return 'Items you liked or carted have dropped in price';
      case NotificationType.restock:
        return 'Liked or carted items are back in stock';
      case NotificationType.newArrival:
        return 'New items matching your style profile';
      case NotificationType.recommendation:
        return 'Personalised picks from our AI';
      case NotificationType.system:
        return 'Promotions, updates, and app news';
    }
  }

  IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.local_shipping_outlined;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.priceDrop:
        return Icons.trending_down;
      case NotificationType.restock:
        return Icons.inventory_2_outlined;
      case NotificationType.newArrival:
        return Icons.fiber_new_outlined;
      case NotificationType.recommendation:
        return Icons.star_outline;
      case NotificationType.system:
        return Icons.campaign_outlined;
    }
  }

  Future<void> _toggle(NotificationType type, bool value) async {
    await _prefs.setEnabled(type, value);
    setState(() {});
  }

  bool get _allEnabled =>
      NotificationType.values.every((t) => _prefs.isEnabled(t));

  @override
  Widget build(BuildContext context) {
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
          'Notification Settings',
          style: AppTypography.heading3.copyWith(
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
        ),
      ),
      body: ListView(
        children: [
          // ── Master toggle ───────────────────────────────────────────────────
          _SectionHeader(label: 'All Notifications', isDark: isDark),
          _ToggleTile(
            icon: Icons.notifications_active_outlined,
            iconColor: isDark ? AppColors.darkPrimaryText : AppColors.black,
            label: 'Enable All',
            description: 'Toggle all notification types at once',
            value: _allEnabled,
            isDark: isDark,
            onChanged: (v) async {
              if (v) {
                await _prefs.enableAll();
              } else {
                await _prefs.disableAll();
              }
              setState(() {});
            },
          ),
          const SizedBox(height: 8),

          // ── Per-type toggles ────────────────────────────────────────────────
          _SectionHeader(label: 'Notification Types', isDark: isDark),
          ...NotificationType.values.map(
            (type) => _ToggleTile(
              icon: _icon(type),
              iconColor: _prefs.isEnabled(type)
                  ? (isDark ? AppColors.darkPrimaryText : AppColors.black)
                  : (isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.secondaryText),
              label: _label(type),
              description: _description(type),
              value: _prefs.isEnabled(type),
              isDark: isDark,
              onChanged: (v) => _toggle(type, v),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String description;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.description,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.darkCardBackground : AppColors.white,
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(
          label,
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
        ),
        subtitle: Text(
          description,
          style: AppTypography.body2.copyWith(
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.secondaryText,
          ),
        ),
        trailing: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: isDark
              ? AppColors.darkPrimaryText
              : AppColors.black,
        ),
        isThreeLine: false,
      ),
    );
  }
}
