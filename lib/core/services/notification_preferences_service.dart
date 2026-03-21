import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/enums/notification_type.dart';

/// Persists per-type notification toggle preferences.
///
/// Usage:
///   NotificationPreferencesService.instance.isEnabled(NotificationType.priceDrop)
///   await NotificationPreferencesService.instance.setEnabled(NotificationType.priceDrop, false)
class NotificationPreferencesService {
  NotificationPreferencesService._();
  static final NotificationPreferencesService instance =
      NotificationPreferencesService._();

  static const String _prefix = 'notif_pref_';

  // In-memory cache populated on first access.
  final Map<NotificationType, bool> _cache = {};

  /// Call once at startup (after SharedPreferences is ready).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    for (final type in NotificationType.values) {
      // Default: all types enabled.
      _cache[type] = prefs.getBool('$_prefix${type.value}') ?? true;
    }
  }

  bool isEnabled(NotificationType type) => _cache[type] ?? true;

  Map<NotificationType, bool> get all => Map.unmodifiable(_cache);

  Future<void> setEnabled(NotificationType type, bool enabled) async {
    _cache[type] = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix${type.value}', enabled);
  }

  Future<void> enableAll() async {
    for (final type in NotificationType.values) {
      await setEnabled(type, true);
    }
  }

  Future<void> disableAll() async {
    for (final type in NotificationType.values) {
      await setEnabled(type, false);
    }
  }
}
