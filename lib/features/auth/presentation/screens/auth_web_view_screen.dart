import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/constants/web_urls.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/network/api_config.dart';
import 'package:swipe/core/services/notification_service.dart';
import 'package:swipe/core/services/seen_products_service.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/core/utils/webview_settings_bridge.dart';

/// Full-screen WebView that hosts the auth + onboarding flow.
///
/// Kept for mini-app embedding — it is no longer the default auth entry point
/// (native phone → verify-method → OTP/social flow replaced it).
///
/// The web pages communicate back to Flutter via a JavascriptChannel
/// named "FlutterBridge". Supported message types:
///   auth_complete          — returning user; has an existing profile
///   onboarding_complete    — new user; just created their profile
///   partner_auth_complete  — partner/admin login
///   guest_mode             — user chose to browse without signing in
///   google_auth_start      — web button tapped; Flutter triggers native Google Sign-In
///   apple_auth_start       — web button tapped; Flutter triggers Sign in with Apple
///   set_language           — user changed language in the web view; sync native locale
///   set_theme              — user toggled theme in the web view; sync native theme
class AuthWebViewScreen extends StatefulWidget {
  const AuthWebViewScreen({super.key});

  @override
  State<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends State<AuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

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

  /// Load the auth phone page, passing lang + theme + platform as query params
  /// so the web page can show the correct social auth button.
  Future<void> _loadAuthUrl() async {
    try {
      final langCode = await LanguageService().getCurrentLanguageCode();
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('theme_mode') ?? 'light';
      final platform = Platform.isAndroid ? 'android' : 'ios';

      final uri = Uri.parse(WebUrls.authPhone).replace(
        queryParameters: {'lang': langCode, 'theme': theme, 'platform': platform},
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
        case 'google_auth_start':
          await _startGoogleAuth(map['phone'] as String?);
        case 'apple_auth_start':
          await _startAppleAuth(map['phone'] as String?);
        case 'set_language':
        case 'set_theme':
          if (mounted) await applyWebViewSetting(map, context);
      }
    } catch (_) {
      // Malformed message — ignore silently.
    }
  }

  /// Triggers native Google Sign-In (Android) and exchanges the id_token for app tokens.
  Future<void> _startGoogleAuth(String? enteredPhone) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      await _exchangeSocialToken(
        endpoint: ApiConfig.authGoogle,
        tokenKey: 'idToken',
        token: idToken,
        phoneNumber: enteredPhone,
        provider: 'Google',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In: $e')),
        );
      }
    }
  }

  /// Triggers Sign in with Apple (iOS) and exchanges the identity token for app tokens.
  Future<void> _startAppleAuth(String? enteredPhone) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final identityToken = credential.identityToken;
      if (identityToken == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      await _exchangeSocialToken(
        endpoint: ApiConfig.authApple,
        tokenKey: 'identityToken',
        token: identityToken,
        phoneNumber: enteredPhone,
        provider: 'Apple',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in with Apple: $e')),
        );
      }
    }
  }

  /// Sends a social token to the backend and completes the auth flow.
  Future<void> _exchangeSocialToken({
    required String endpoint,
    required String tokenKey,
    required String token,
    required String provider,
    String? phoneNumber,
  }) async {
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post<Map<String, dynamic>>(
        endpoint,
        data: {
          tokenKey: token,
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phoneNumber': phoneNumber,
        },
      );

      final body = response.data ?? {};
      final payload = (body['data'] ?? body) as Map<String, dynamic>;

      final accessToken  = payload['access_token']  as String? ?? '';
      final refreshToken = payload['refresh_token'] as String? ?? '';
      final user = payload['user'] as Map<String, dynamic>? ?? {};

      if (accessToken.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$provider: $e')),
        );
      }
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
    await SeenProductsService.clearIfUserChanged(userId);

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
    final l10n = AppLocalizations.of(context)!;
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
                      Text(
                        l10n.connectionErrorTitle,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loadAuthUrl,
                        child: Text(l10n.retry),
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
