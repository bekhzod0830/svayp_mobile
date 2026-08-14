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

  /// v2 API prefix — currently only simplified profile creation.
  static const String apiPrefixV2 = '/api/v2';

  /// Google Sign-In Web/server OAuth client id (audience of the idToken).
  /// Must equal the backend GOOGLE_CLIENT_ID. Leave empty to rely on the
  /// audience configured in google-services.json / GoogleService-Info.plist.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '187239045780-q0tnohll9h0saqppg46r6jn71h4movm4.apps.googleusercontent.com',
  );

  /// Full base URL with API prefix
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// Full base URL with the v2 API prefix
  static String get apiBaseUrlV2 => '$baseUrl$apiPrefixV2';

  /// Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ==================== Authentication Endpoints ====================
  static const String authCheckPhone = '/auth/check-phone';
  static const String authSendOtp = '/auth/otp/send';
  static const String authVerifyOtp = '/auth/otp/verify';
  static const String authGoogle = '/auth/google';
  static const String authApple = '/auth/apple';
  static const String authRefreshToken = '/auth/token/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String authAdminLogin = '/auth/admin/login';

  // ==================== User Endpoints ====================
  static const String userProfile = '/users/profile';

  /// v2 simplified profile creation (name + dob + gender only). Absolute URL
  /// on purpose: Dio's baseUrl carries the /api/v1 prefix, so a relative
  /// '/api/v2/...' path would double-prefix. Dio passes absolute URLs through
  /// unchanged and the auth interceptor still attaches the Bearer token.
  static String get userProfileV2 => '$apiBaseUrlV2/users/profile';
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
  static const String productsAll = '/products/all';
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
  static const String adminOrderDetail = '/admin/orders/{id}';
  static const String adminOrderStatus = '/admin/orders/{id}/status';

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

  // ==================== Seller Endpoints ====================
  static const String sellers = '/sellers';
  static const String sellerDetail = '/sellers/{id}';
  static const String sellerProducts = '/sellers/{id}/detail';

  // ==================== App Version / Config Endpoints ====================
  static const String appVersion = '/app/version';
  static const String appFeatureFlags = '/app/feature-flags';

  // ==================== Upload Endpoints ====================
  static const String uploadImage = '/upload/image';

  // ==================== Try-on Endpoints (примерка товаров) ====================
  /// Submit a try-on job. Body: { productIds:[...], personImageKey?, idempotencyKey }.
  static const String tryOn = '/outfits/try-on';
  /// Poll job status: GET /outfits/try-on/{id}.
  static const String tryOnDetail = '/outfits/try-on/{id}';
  /// Presigned PUT URL for the user's own photo (person try-on mode).
  static const String tryOnModelImageUrl = '/outfits/try-on/model-image-url';

  // ─── Промокоды блогеров ──────────────────────────────────────────────────
  /// POST: применить промокод. Ошибки: PROMO_NOT_FOUND / PROMO_EXPIRED /
  /// PROMO_LIMIT_REACHED / PROMO_ALREADY_HAS (400), RATE_LIMITED (429).
  static const String promoApply = '/promo/apply';
  /// GET: промокод текущего пользователя (null, если не активирован).
  static const String promoMe = '/promo/me';

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
