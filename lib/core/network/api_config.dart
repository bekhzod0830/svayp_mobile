/// API Configuration Constants
class ApiConfig {
  ApiConfig._();

  /// Base URL for API
  /// Change this to your backend server URL
  /// For local development on Android emulator: use 10.0.2.2
  /// For local development on iOS simulator: use localhost
  /// For production: use your deployed server URL
  static const String baseUrl = 'https://app.svaypai.com';

  /// API version prefix
  static const String apiPrefix = '/api/v1';

  /// Full base URL with API prefix
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ==================== Authentication Endpoints ====================
  static const String authSendOtp = '/auth/otp/send';
  static const String authVerifyOtp = '/auth/otp/verify';
  static const String authRefreshToken = '/auth/token/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  // ==================== User Endpoints ====================
  static const String userProfile = '/users/profile';
  static const String userMe = '/users/me';
  static const String updateProfile = '/users/me';
  static const String deleteAccount = '/users/me';

  // ==================== Address Endpoints ====================
  static const String addresses = '/addresses';
  static const String addressDetail = '/addresses/{id}';
  static const String addressSetDefault = '/addresses/{id}/default';

  // ==================== Event Endpoints ====================
  static const String userEvents = '/events';
  static const String userEventsBatch = '/events/batch';

  // ==================== Product Endpoints ====================
  static const String products = '/products';
  static const String productsRecommended = '/products/recommendations';
  static const String productsSearch = '/products/search';
  static const String productsSearchHistory = '/products/search/history';
  static const String productsSearchPopular = '/products/search/popular';
  static const String productDetail = '/products/{id}';
  static const String productLike = '/products/{id}/like';
  static const String productToggleLike = '/products/{id}/toggle-like';
  static const String productsFavorites = '/products/favorites';

  // ==================== Cart Endpoints ====================
  static const String cart = '/cart';
  static const String cartAdd = '/cart';
  static const String cartUpdate = '/cart/{id}';
  static const String cartRemove = '/cart/{id}';
  static const String cartClear = '/cart';

  // ==================== Order Endpoints ====================
  static const String orders = '/orders';
  static const String orderDetail = '/orders/{id}';
  static const String orderCancel = '/orders/{id}/cancel';
  static const String orderStats = '/orders/stats';

  // ==================== Chat Endpoints ====================
  static const String chats = '/chats';
  static const String chatDetail = '/chats/{id}';
  static const String chatMessages = '/chats/{id}/messages';
  static const String chatSendMessage = '/chats/{id}/messages';
  static const String chatMarkRead = '/chats/{id}/read';
  static const String chatArchive = '/chats/{id}/archive';
  static const String chatUnreadCount = '/chats/unread-count';

  // ==================== Brand Endpoints ====================
  static const String brands = '/brands';
  static const String brandDetail = '/brands/{id}';

  // ==================== Upload Endpoints ====================
  static const String uploadImage = '/upload/image';

  /// Build full URL
  static String buildUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }

  /// Replace path parameters
  static String replacePath(String path, Map<String, dynamic> params) {
    var result = path;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}
