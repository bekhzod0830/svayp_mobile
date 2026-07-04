import 'package:swipe/core/services/product_api_service.dart';

/// Process-wide cache of seller info (logo, locations, contacts) by seller id.
///
/// Sellers change rarely, but every ProductDetail open used to refetch
/// GET /sellers/{id}. Entries live for [_ttl]; concurrent requests for the
/// same seller are coalesced into one network call. List screens can [put]
/// already-loaded sellers to make detail screens instant.
class SellerCacheService {
  SellerCacheService._();

  static final SellerCacheService instance = SellerCacheService._();

  static const Duration _ttl = Duration(minutes: 10);

  final ProductApiService _apiService = ProductApiService();
  final Map<String, SellerInfo> _byId = {};
  final Map<String, DateTime> _fetchedAt = {};
  final Map<String, Future<SellerInfo>> _inFlight = {};

  Future<SellerInfo> getSeller({required String sellerId, String? token}) {
    final cached = _byId[sellerId];
    final at = _fetchedAt[sellerId];
    if (cached != null &&
        at != null &&
        DateTime.now().difference(at) < _ttl) {
      return Future.value(cached);
    }
    final pending = _inFlight[sellerId];
    if (pending != null) return pending;

    final future = _apiService
        .getSeller(sellerId: sellerId, token: token)
        .then((info) {
      _byId[sellerId] = info;
      _fetchedAt[sellerId] = DateTime.now();
      return info;
    }).whenComplete(() => _inFlight.remove(sellerId));
    _inFlight[sellerId] = future;
    return future;
  }

  /// Seed the cache with a seller already loaded elsewhere (e.g. a list).
  void put(SellerInfo info) {
    if (info.id.isEmpty) return;
    _byId[info.id] = info;
    _fetchedAt[info.id] = DateTime.now();
  }
}
