import 'dart:io' show Platform;

import 'package:telegram_login/telegram_login.dart';

/// Telegram NATIVE login (official app-to-app SDK).
///
/// Opens the Telegram app directly — no browser — so there is NO interstitial
/// "Open Telegram" page and NO new Chrome/web device in the user's Telegram
/// sessions. Returns a signed `id_token` JWT that the backend verifies against
/// Telegram's JWKS (POST /auth/telegram/native).
class TelegramNativeAuth {
  TelegramNativeAuth._();
  static final TelegramNativeAuth instance = TelegramNativeAuth._();

  static const String _clientId = '8713945846';

  // Per-platform redirect URIs from BotFather → Native Login → App URL (the SDK
  // appends /tglogin). Android and iOS have DIFFERENT auto-generated app ids.
  // The Android value must also match the AndroidManifest app-link host.
  static const String _androidRedirectUri =
      'https://app1194732191-login.tg.dev/tglogin';
  static const String _iosRedirectUri =
      'https://app2122590493-login.tg.dev/tglogin';

  static String get _redirectUri =>
      Platform.isIOS ? _iosRedirectUri : _androidRedirectUri;

  /// iOS custom-scheme fallback (must match Info.plist CFBundleURLSchemes).
  static const String _fallbackScheme = 'com.svaypai.app';

  final TelegramLogin _tg = TelegramLogin();
  bool _configured = false;

  /// Opens the Telegram app and returns a signed `id_token`, or `null` if the
  /// user cancelled. Throws [TelegramLoginError] on other failures.
  Future<String?> login() async {
    if (!_configured) {
      await _tg.configure(TelegramLoginConfiguration(
        clientId: _clientId,
        redirectUri: _redirectUri,
        scopes: const ['profile', 'phone'],
        fallbackScheme: _fallbackScheme,
      ));
      _configured = true;
    }

    try {
      final result = await _tg.login();
      return result.idToken;
    } on TelegramLoginError catch (e) {
      if (e.code == TelegramLoginErrorCode.cancelled) return null;
      rethrow;
    }
  }
}
