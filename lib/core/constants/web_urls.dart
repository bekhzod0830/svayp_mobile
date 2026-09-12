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
  // `nav=tab` tells the page it is a bottom-bar tab of the native shell (not a
  // pushed page or a browser): it hides in-page nav that duplicates the bar,
  // drops back arrows that would leave the tab, and traps Android back. The
  // web persists the marker per WebView, so later in-page navigations keep it
  // (see the web app's isShellTab()).
  static const String closet = '$_base/closet?nav=tab';
  static const String feed = '$_base/feed?nav=tab';
  static const String market = '$_base/market?nav=tab';
  static const String stylist = '$_base/stylist?nav=tab';

  // ── Pushed screens ─────────────────────────────────────────────────────────
  static const String liked = '$_base/liked';
  static const String cart = '$_base/cart';

  static String productDetail(String productId) => '$_base/product/$productId';
  static String chatDetail(String chatId) => '$_base/chat/$chatId';

  /// Resolves a notification `url` value to a full web URL.
  /// Absolute http(s) URLs are returned unchanged; relative paths
  /// (e.g. '/market/create') are prefixed with the web app base.
  static String resolve(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return '$_base$path';
  }
}
