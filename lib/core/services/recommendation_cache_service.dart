import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:swipe/core/models/product.dart';

/// Recommendation Cache Service
/// Caches recommended products fetched during onboarding to reuse in discover screen
/// This improves UX by avoiding duplicate API calls for first-time users
class RecommendationCacheService {
  static const String _cacheKey = 'cached_recommendations';
  static const String _cacheTimestampKey = 'cached_recommendations_timestamp';
  static const String _isFirstLaunchKey = 'is_first_launch_after_onboarding';
  static const Duration _cacheValidity = Duration(
    hours: 1,
  ); // Cache valid for 1 hour

  /// Save recommended products to cache
  /// Used in onboarding completion screen after fetching recommendations
  static Future<void> cacheRecommendations(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert products to JSON
      final productsJson = products.map((p) => p.toJson()).toList();
      final jsonString = json.encode(productsJson);

      // Save to cache
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setBool(_isFirstLaunchKey, true);

      print('✅ Cached ${products.length} recommendations');
    } catch (e) {
      print('❌ Failed to cache recommendations: $e');
    }
  }

  /// Get cached recommendations if available and valid
  /// Returns null if cache is invalid, expired, or not available
  static Future<List<Product>?> getCachedRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if this is the first launch after onboarding
      final isFirstLaunch = prefs.getBool(_isFirstLaunchKey) ?? false;
      if (!isFirstLaunch) {
        print('📭 Not first launch - no cached recommendations');
        return null;
      }

      // Get cached data
      final jsonString = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (jsonString == null || timestamp == null) {
        print('📭 No cached recommendations found');
        return null;
      }

      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final age = now.difference(cacheTime);

      if (age > _cacheValidity) {
        print(
          '⏰ Cached recommendations expired (${age.inMinutes} minutes old)',
        );
        await clearCache(); // Clear expired cache
        return null;
      }

      // Parse and return products
      final List<dynamic> productsJson = json.decode(jsonString);
      final products = productsJson
          .map((json) => Product.fromJson(json))
          .toList();

      print(
        '✅ Retrieved ${products.length} cached recommendations (${age.inMinutes} minutes old)',
      );
      return products;
    } catch (e) {
      print('❌ Failed to retrieve cached recommendations: $e');
      await clearCache(); // Clear corrupted cache
      return null;
    }
  }

  /// Mark that cached recommendations have been used
  /// This prevents reusing them on subsequent app launches
  static Future<void> markCacheAsUsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isFirstLaunchKey, false);
      print(
        '✅ Marked cache as used - will fetch fresh recommendations next time',
      );
    } catch (e) {
      print('❌ Failed to mark cache as used: $e');
    }
  }

  /// Clear all cached recommendations
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove(_isFirstLaunchKey);
      print('🗑️ Cleared recommendation cache');
    } catch (e) {
      print('❌ Failed to clear cache: $e');
    }
  }

  /// Check if cached recommendations are available
  static Future<bool> hasCachedRecommendations() async {
    final cached = await getCachedRecommendations();
    return cached != null && cached.isNotEmpty;
  }
}
