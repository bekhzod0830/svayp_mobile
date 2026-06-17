import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Telegram OIDC Authorization result — either success (code + verifiers) or
/// a user-facing error string.
sealed class TelegramAuthResult {}

class TelegramAuthSuccess extends TelegramAuthResult {
  final String code;
  final String codeVerifier;
  final String redirectUri;
  final String nonce;

  TelegramAuthSuccess({
    required this.code,
    required this.codeVerifier,
    required this.redirectUri,
    required this.nonce,
  });
}

class TelegramAuthError extends TelegramAuthResult {
  final String message;
  TelegramAuthError(this.message);
}

class TelegramAuthCancelled extends TelegramAuthResult {}

/// Handles the client-side of the Telegram OIDC Authorization Code + PKCE flow.
///
/// Usage:
/// ```dart
/// final result = await TelegramAuthService.instance.startAuth();
/// if (result is TelegramAuthSuccess) {
///   final tokenResponse = await authService.telegramOidcLogin(
///     code: result.code,
///     codeVerifier: result.codeVerifier,
///     redirectUri: result.redirectUri,
///     nonce: result.nonce,
///   );
/// }
/// ```
class TelegramAuthService {
  TelegramAuthService._();
  static final TelegramAuthService instance = TelegramAuthService._();

  static const String _clientId = '8713945846'; // public bot id from BotFather
  static const String _redirectUri = 'com.svaypai.app://auth/telegram/callback';
  static const String _authEndpoint = 'https://oauth.telegram.org/auth';

  // SharedPreferences keys — persist PKCE so a cold-start return (app killed
  // while the user was in the browser/Telegram) can still complete the login.
  static const String _kVerifier = 'tg_pkce_verifier';
  static const String _kState    = 'tg_pkce_state';
  static const String _kNonce    = 'tg_pkce_nonce';
  static const String _kRedirect = 'tg_pkce_redirect';

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  /// Launches the Telegram consent screen and waits for the deep link callback.
  /// Resolves when Telegram redirects back to the app or times out (2 minutes).
  ///
  /// PKCE params are also persisted so that if the app is killed while the user
  /// is in the external browser, the cold-start handler in app.dart can finish.
  Future<TelegramAuthResult> startAuth() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _s256(codeVerifier);
    final state = _generateRandom(32);
    final nonce = _generateRandom(32);

    // Persist for cold-start recovery (cleared once consumed).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVerifier, codeVerifier);
    await prefs.setString(_kState, state);
    await prefs.setString(_kNonce, nonce);
    await prefs.setString(_kRedirect, _redirectUri);

    final authUri = Uri.parse(_authEndpoint).replace(queryParameters: {
      'client_id': _clientId,
      'scope': 'openid phone profile',
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
      'nonce': nonce,
    });

    // Cancel any lingering subscription from a previous attempt.
    await _linkSub?.cancel();

    final completer = Completer<TelegramAuthResult>();

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      if (!_isTelegramCallback(uri)) return;
      _linkSub?.cancel();
      _linkSub = null;
      _clearPending(); // warm path consumed it — stop the cold-start handler

      final error = uri.queryParameters['error'];
      if (error != null) {
        // User denied consent or Telegram returned an error.
        completer.complete(TelegramAuthCancelled());
        return;
      }

      final returnedState = uri.queryParameters['state'];
      if (returnedState != state) {
        // State mismatch — possible CSRF attempt; reject silently.
        completer.complete(
          TelegramAuthError('Security check failed. Please try again.'),
        );
        return;
      }

      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        completer.complete(TelegramAuthError('No authorization code received.'));
        return;
      }

      completer.complete(TelegramAuthSuccess(
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: _redirectUri,
        nonce: nonce,
      ));
    });

    // 2-minute timeout — user closed Telegram without completing consent.
    Future.delayed(const Duration(minutes: 2), () {
      if (!completer.isCompleted) {
        _linkSub?.cancel();
        _linkSub = null;
        completer.complete(TelegramAuthCancelled());
      }
    });

    final launched = await launchUrl(
      authUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      await _linkSub?.cancel();
      _linkSub = null;
      await _clearPending();
      return TelegramAuthError('Could not open Telegram. Is it installed?');
    }

    return completer.future;
  }

  /// Cold-start completion: called from app.dart when the app is (re)launched
  /// via the Telegram deep link. Reads the persisted PKCE and validates `state`.
  /// Returns null if [uri] is not a Telegram callback or there is no pending flow.
  Future<TelegramAuthResult?> completePendingFromUri(Uri uri) async {
    if (!_isTelegramCallback(uri)) return null;

    final prefs = await SharedPreferences.getInstance();
    final codeVerifier = prefs.getString(_kVerifier);
    if (codeVerifier == null) return null; // nothing pending

    final expectedState = prefs.getString(_kState);
    final nonce = prefs.getString(_kNonce) ?? '';
    final redirectUri = prefs.getString(_kRedirect) ?? _redirectUri;
    await _clearPending();

    final error = uri.queryParameters['error'];
    if (error != null) return TelegramAuthCancelled();

    if (uri.queryParameters['state'] != expectedState) {
      return TelegramAuthError('Security check failed. Please try again.');
    }

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      return TelegramAuthError('No authorization code received.');
    }

    return TelegramAuthSuccess(
      code: code,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
      nonce: nonce,
    );
  }

  Future<void> _clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kVerifier);
    await prefs.remove(_kState);
    await prefs.remove(_kNonce);
    await prefs.remove(_kRedirect);
  }

  bool _isTelegramCallback(Uri uri) =>
      uri.scheme == 'com.svaypai.app' &&
      uri.host == 'auth' &&
      uri.path == '/telegram/callback';

  // ── PKCE helpers ──────────────────────────────────────────────────────────

  String _generateCodeVerifier() => _generateRandom(64);

  String _s256(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _generateRandom(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)])
        .join();
  }
}
