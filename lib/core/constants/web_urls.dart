/// Web app URL constants.
///
/// These map to the Next.js web app hosted at https://web.svaypai.com.
/// Flutter's WebView-based screens load these URLs so UI changes can be
/// deployed without a new app-store release.
class WebUrls {
  WebUrls._();

  static const String _base = 'https://web.svaypai.com';

  // ── Auth screens ───────────────────────────────────────────────────────────
  static const String authPhone = '$_base/auth/phone';

  // ── Tab screens ────────────────────────────────────────────────────────────
  static const String discover = '$_base/discover';
  static const String shop = '$_base/shop';
  static const String chat = '$_base/chat';
  static const String closet = '$_base/closet';

  // ── Pushed screens ─────────────────────────────────────────────────────────
  static const String liked = '$_base/liked';
  static const String cart = '$_base/cart';

  static String productDetail(String productId) => '$_base/product/$productId';
  static String chatDetail(String chatId) => '$_base/chat/$chatId';
}
