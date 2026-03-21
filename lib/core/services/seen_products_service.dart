import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists product IDs the user has already interacted with
/// (added to cart and checked out) so the discovery feed can filter them out.
class SeenProductsService {
  static const String _key = 'seen_product_ids';
  static const String _userKey = 'seen_product_owner_id';
  static const int _maxEntries = 500; // cap to prevent unbounded growth

  /// Add product IDs that should no longer appear in the discovery feed.
  static Future<void> addSeenIds(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = _loadSet(prefs);
      existing.addAll(ids);
      // Trim oldest entries if we exceed the cap
      final trimmed = existing.length > _maxEntries
          ? existing.skip(existing.length - _maxEntries).toSet()
          : existing;
      await prefs.setString(_key, jsonEncode(trimmed.toList()));
    } catch (_) {
      // Never propagate — this is best-effort
    }
  }

  /// Returns the full set of seen product IDs.
  static Future<Set<String>> getSeenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _loadSet(prefs);
    } catch (_) {
      return {};
    }
  }

  /// Clears seen IDs only when the logged-in account changes.
  /// Same account re-login keeps the existing filter list intact.
  static Future<void> clearIfUserChanged(String newUserId) async {
    if (newUserId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString(_userKey);
      if (storedUserId != newUserId) {
        await prefs.remove(_key);
        await prefs.setString(_userKey, newUserId);
      }
    } catch (_) {}
  }

  /// Clears all stored seen IDs and the owner record (called on logout).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_userKey);
    } catch (_) {}
  }

  static Set<String> _loadSet(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }
}
