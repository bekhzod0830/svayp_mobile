import 'package:swipe/core/services/badge_notifier.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/features/cart/data/services/cart_service.dart';

/// Single place that refreshes the cart badge count.
///
/// Discover, ProductDetail and other screens used to fire their own
/// GET /cart just to update [BadgeNotifier.cartCount] — often several times
/// per screen open. This service coalesces concurrent refreshes and skips
/// repeats within [_minInterval]; cart mutations must pass `force: true`
/// so the badge reflects them immediately.
class CartBadgeService {
  CartBadgeService._();

  static final CartBadgeService instance = CartBadgeService._();

  static const Duration _minInterval = Duration(seconds: 15);

  final ProductApiService _apiService = ProductApiService();
  final CartService _cartService = CartService();

  Future<void>? _inFlight;
  DateTime? _lastSuccessAt;

  /// Forget the last successful fetch so the next [refresh] hits the API.
  void invalidate() => _lastSuccessAt = null;

  Future<void> refresh({String? token, bool force = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final last = _lastSuccessAt;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _minInterval) {
      return Future.value();
    }
    final future =
        _doRefresh(token).whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<void> _doRefresh(String? token) async {
    try {
      if (token != null && token.isNotEmpty) {
        final cartData = await _apiService.getCart(token: token);
        final summary = cartData['summary'] as Map<String, dynamic>;
        final totalItems = summary['total_items'] as int;
        BadgeNotifier.instance.setCartCount(totalItems);
        _lastSuccessAt = DateTime.now();
      } else {
        await _cartService.init();
        BadgeNotifier.instance.setCartCount(_cartService.getTotalQuantity());
      }
    } catch (_) {
      // API failed — fall back to the local Hive cart, same as the old
      // per-screen logic did.
      try {
        await _cartService.init();
        BadgeNotifier.instance.setCartCount(_cartService.getTotalQuantity());
      } catch (_) {}
    }
  }
}
