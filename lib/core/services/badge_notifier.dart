import 'package:flutter/foundation.dart';

/// Singleton that broadcasts real-time cart count and "new liked" indicator
/// to every widget that listens via [ValueListenableBuilder].
///
/// Cart count is the authoritative number displayed in all badge widgets.
/// It is seeded from the API (or local Hive fallback) whenever
/// [DiscoverScreen] or [ProductDetailScreen] calls their `_updateCartCount()`
/// helper, and is also kept up-to-date by [CartScreen] after each mutation.
///
/// The liked indicator shows a red dot on the heart icon whenever the user
/// likes a product.  The dot disappears when the user opens the Liked screen.
class BadgeNotifier {
  BadgeNotifier._();
  static final BadgeNotifier instance = BadgeNotifier._();

  /// Total items (sum of quantities) currently in the cart.
  final ValueNotifier<int> cartCount = ValueNotifier(0);

  /// True when the user has liked something since last opening Liked screen.
  final ValueNotifier<bool> hasNewLiked = ValueNotifier(false);

  /// True when there are unread notifications.
  final ValueNotifier<bool> hasUnreadNotifications = ValueNotifier(false);

  /// Overwrite the cart count (e.g. after an API sync).
  void setCartCount(int count) => cartCount.value = count;

  /// Mark that a new item was liked (shows dot on heart icon).
  void markNewLiked() => hasNewLiked.value = true;

  /// Remove the liked dot (call when the Liked screen is opened).
  void clearNewLiked() => hasNewLiked.value = false;

  /// Mark that there are unread notifications.
  void markUnreadNotifications() => hasUnreadNotifications.value = true;

  /// Clear the unread notifications dot (call when Notifications screen is opened).
  void clearUnreadNotifications() => hasUnreadNotifications.value = false;
}
