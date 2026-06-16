import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
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

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  /// Launches the Telegram consent screen and waits for the deep link callback.
  /// Resolves when Telegram redirects back to the app or times out (2 minutes).
  Future<TelegramAuthResult> startAuth() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _s256(codeVerifier);
    final state = _generateRandom(32);
    final nonce = _generateRandom(32);

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
      return TelegramAuthError('Could not open Telegram. Is it installed?');
    }

    return completer.future;
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
