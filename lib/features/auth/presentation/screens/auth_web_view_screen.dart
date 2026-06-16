import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/constants/web_urls.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/services/notification_service.dart';
import 'package:swipe/core/services/seen_products_service.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';

/// Full-screen WebView that hosts the auth + onboarding flow.
///
/// The web pages communicate back to Flutter via a JavascriptChannel
/// named "FlutterBridge". Supported message types:
///   auth_complete          — returning user; has an existing profile
///   onboarding_complete    — new user; just created their profile
///   partner_auth_complete  — partner/admin login
///   guest_mode             — user chose to browse without signing in
///   telegram_auth_start    — web is about to redirect to Telegram OIDC;
///                            Flutter stores PKCE params and intercepts
///                            the com.svaypai.app:// deep-link callback
class AuthWebViewScreen extends StatefulWidget {
  const AuthWebViewScreen({super.key});

  @override
  State<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends State<AuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  // Stored when the web page sends telegram_auth_start
  String? _tgCodeVerifier;
  String? _tgState;
  String? _tgNonce;
  String? _tgRedirectUri;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (message) => _handleBridgeMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            // Intercept Telegram OIDC callback deep link
            if (url.startsWith('com.svaypai.app://auth/telegram/callback')) {
              _handleTelegramCallback(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) setState(() { _isLoading = true; _hasError = false; });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) setState(() { _isLoading = false; _hasError = true; });
            }
          },
        ),
      );

    _loadAuthUrl();
  }

  /// Load the auth phone page, passing lang + theme as query params so the
  /// web page can pick up the user's language and theme preference.
  Future<void> _loadAuthUrl() async {
    try {
      final langCode = await LanguageService().getCurrentLanguageCode();
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('theme_mode') ?? 'light';

      final uri = Uri.parse(WebUrls.authPhone).replace(
        queryParameters: {'lang': langCode, 'theme': theme},
      );
      await _controller.loadRequest(uri);
    } catch (_) {
      await _controller.loadRequest(Uri.parse(WebUrls.authPhone));
    }
  }

  // ── Bridge message handling ───────────────────────────────────────────────

  Future<void> _handleBridgeMessage(String rawMessage) async {
    try {
      final map = jsonDecode(rawMessage) as Map<String, dynamic>;
      final type = map['type'] as String? ?? '';

      switch (type) {
        case 'auth_complete':
          await _handleAuthComplete(map, isNewUser: false);
        case 'onboarding_complete':
          await _handleAuthComplete(map, isNewUser: true);
        case 'partner_auth_complete':
          await _handlePartnerAuthComplete(map);
        case 'guest_mode':
          await _handleGuestMode();
        case 'telegram_auth_start':
          // Store PKCE session so we can use it when intercepting the callback
          _tgCodeVerifier = map['codeVerifier'] as String?;
          _tgState        = map['state']        as String?;
          _tgNonce        = map['nonce']        as String?;
          _tgRedirectUri  = map['redirectUri']  as String?;
      }
    } catch (_) {
      // Malformed message — ignore silently.
    }
  }

  /// Called when the WebView is about to navigate to the Telegram deep-link
  /// callback URL (com.svaypai.app://auth/telegram/callback?code=...&state=...).
  Future<void> _handleTelegramCallback(String callbackUrl) async {
    final uri = Uri.parse(callbackUrl);
    final code  = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];

    // CSRF check
    if (code == null || state == null || state != _tgState ||
        _tgCodeVerifier == null || _tgRedirectUri == null) {
      // Mismatch — reload auth start
      await _loadAuthUrl();
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/telegram/oidc',
        data: {
          'code':          code,
          'codeVerifier': _tgCodeVerifier,
          'redirectUri':  _tgRedirectUri,
          'nonce':        _tgNonce,
        },
      );

      // Unwrap nested data structure
      final body = response.data ?? {};
      final payload = (body['data'] ?? body) as Map<String, dynamic>;

      final accessToken  = payload['access_token']  as String? ?? '';
      final refreshToken = payload['refresh_token'] as String? ?? '';
      final user = payload['user'] as Map<String, dynamic>? ?? {};

      if (accessToken.isEmpty) {
        await _loadAuthUrl();
        return;
      }

      await _handleAuthComplete({
        'accessToken':  accessToken,
        'refreshToken': refreshToken,
        'userId':   user['id']?.toString() ?? '',
        'phone':    user['phone_number']?.toString() ?? '',
        'username': user['username']?.toString() ?? '',
      }, isNewUser: !(user['hasProfile'] as bool? ??
                     user['has_profile'] as bool? ?? false));
    } catch (_) {
      // On error reload the auth flow
      if (mounted) setState(() => _isLoading = false);
      await _loadAuthUrl();
    }
  }

  /// Shared post-auth logic for both returning users and new users.
  Future<void> _handleAuthComplete(
    Map<String, dynamic> map, {
    required bool isNewUser,
  }) async {
    final accessToken = map['accessToken'] as String? ?? '';
    final refreshToken = map['refreshToken'] as String? ?? '';
    final userId = map['userId'] as String? ?? '';
    final phone = map['phone'] as String? ?? '';
    final username = map['username'] as String? ?? '';

    if (accessToken.isEmpty) return;

    // Save tokens — same keys the web app and the rest of Flutter use.
    final apiClient = getIt<ApiClient>();
    await apiClient.saveToken(accessToken);
    await apiClient.saveRefreshToken(refreshToken);

    // Clear any leftover partner role from a previous admin session.
    await apiClient.clearUserRole();

    // Clear guest mode if the user was browsing as guest.
    final storage = await LocalStorageHelper.getInstance();
    await storage.clearGuestMode();

    // Clear seen product IDs if a different account is logging in.
    final userIdInt = int.tryParse(userId) ?? 0;
    await SeenProductsService.clearIfUserChanged(userIdInt);

    // Register FCM token (fire-and-forget — non-critical).
    unawaited(NotificationService.instance.registerTokenWithBackend());

    if (!mounted) return;

    // Analytics
    final event = isNewUser
        ? AnalyticsEvents.registrationCompleted
        : AnalyticsEvents.loginCompleted;
    AnalyticsService.instance.logEvent(event);
    await AnalyticsService.instance.setUser(
      userId: userId,
      phone: phone,
      username: username,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/main');
  }

  Future<void> _handlePartnerAuthComplete(Map<String, dynamic> map) async {
    final accessToken = map['accessToken'] as String? ?? '';
    final refreshToken = map['refreshToken'] as String? ?? '';

    if (accessToken.isEmpty) return;

    final apiClient = getIt<ApiClient>();
    await apiClient.saveToken(accessToken);
    await apiClient.saveRefreshToken(refreshToken);

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/partner-main', (_) => false);
  }

  Future<void> _handleGuestMode() async {
    final storage = await LocalStorageHelper.getInstance();
    await storage.setGuestMode(true);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/main');
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Stack(
            children: [
              if (!_hasError)
                WebViewWidget(controller: _controller),

              if (_isLoading && !_hasError)
                const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),

              if (_hasError)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No connection',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loadAuthUrl,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
