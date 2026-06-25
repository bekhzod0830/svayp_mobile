import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/services/app_permissions.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/core/utils/webview_settings_bridge.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Generic full-screen WebView widget used by all web-backed screens.
///
/// After the page finishes loading the Flutter app injects the stored auth and
/// refresh tokens into the web page's `localStorage` so the web app can make
/// authenticated API requests without a separate sign-in.
class WebViewScreen extends StatefulWidget {
  final String url;
  /// Extra bottom padding to prevent content from being obscured by
  /// overlaying widgets such as the floating bottom nav bar.
  final double bottomPadding;

  const WebViewScreen({super.key, required this.url, this.bottomPadding = 0});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _pageLoaded = false;
  // Last theme/language pushed to the web page. Used to inject changes live
  // (no reload) only when they actually differ.
  String? _lastTheme;
  String? _lastLang;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) {
        // Grant camera/microphone permissions requested by the web page.
        request.grant();
      },
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Receive language/theme changes made inside the web view so the native
      // app stays in sync.
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (message) {
          if (mounted) handleWebViewSettingsMessage(message.message, context);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            // Non-http(s) schemes must always be handed to the OS
            // (tg://, mailto:, tel:, intent:, etc.)
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }

            // t.me links (Telegram web redirect) must open externally
            if (uri.host == 't.me' || uri.host.endsWith('.t.me')) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (_) {
            _pageLoaded = true;
            // The page may have loaded with stale params if the user changed
            // theme/language mid-load — reconcile now.
            _syncSettingsToWeb();
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            // Only surface errors from the main frame; sub-resource failures
            // are common (ads, analytics) and should not block the UI.
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              }
            }
          },
        ),
      );

    // Request native permissions upfront so the WebView can access them.
    _requestNativePermissions();

    // Android: bridge <input type="file"> to native ImagePicker so the web
    // page's library/camera buttons trigger the OS photo picker or camera.
    if (Platform.isAndroid) {
      final androidController = _controller.platform
          as AndroidWebViewController;
      androidController.setOnShowFileSelector(_handleFileSelector);
    }

    // Load the URL with auth tokens embedded as query params so the web app
    // can store them before its auth guard runs.
    _loadWithToken();
  }

  /// Called by Android WebView when the web page uses <input type="file">.
  /// Routes to the camera or gallery via `image_picker`.
  Future<List<String>> _handleFileSelector(
    FileSelectorParams params,
  ) async {
    final picker = ImagePicker();

    // Camera capture (`capture` attribute) is always a single shot.
    if (params.isCaptureEnabled) {
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return shot == null ? const [] : [Uri.file(shot.path).toString()];
    }

    // Gallery with `<input multiple>` (e.g. adding listing photos): let the user
    // select many images in one trip instead of re-opening the picker per image.
    if (params.mode == FileSelectorMode.openMultiple) {
      final picked = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return picked.map((x) => Uri.file(x.path).toString()).toList();
    }

    // Single-file gallery input.
    final single = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return single == null ? const [] : [Uri.file(single.path).toString()];
  }

  Future<void> _requestNativePermissions() async {
    // Route through the shared coordinator so this camera/photos request is
    // serialized with the notification request (see AppPermissions). Firing
    // them concurrently caused the OS to drop the notification dialog.
    await AppPermissions.requestStartupPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reading Theme + Localizations here makes this widget rebuild whenever the
    // native theme or locale changes, so we can push the change into the live
    // web page without a reload.
    _syncSettingsToWeb();
  }

  /// Inject the current native theme/language into the already-loaded web page
  /// (no reload). The web exposes `__setNativeTheme` / `__setNativeLocale`,
  /// which update silently without echoing back over the bridge — so this and
  /// the web→native bridge can't loop.
  void _syncSettingsToWeb() {
    if (!_pageLoaded || !mounted) return;
    final theme =
        Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    final lang = Localizations.localeOf(context).languageCode;
    if (theme == _lastTheme && lang == _lastLang) return;
    _lastTheme = theme;
    _lastLang = lang;
    _controller.runJavaScript(
      "window.__setNativeTheme && window.__setNativeTheme('$theme');"
      "window.__setNativeLocale && window.__setNativeLocale('$lang');",
    );
  }

  /// Reads the stored tokens, language preference, and theme from
  /// SharedPreferences and loads the target URL with those values appended as
  /// query parameters.
  ///
  /// The web app reads these params before its auth guard and providers
  /// initialise, stores them in localStorage, and strips them from the URL.
  Future<void> _loadWithToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final refreshToken = prefs.getString('refresh_token') ?? '';

      // Read the user's preferred language (stored by LanguageService via Hive).
      final langCode = await LanguageService().getCurrentLanguageCode();

      // Read theme preference stored by ThemeService ('dark' or 'light').
      final theme = prefs.getString('theme_mode') ?? 'light';

      // Remember what we loaded with so live-sync only injects real changes.
      _lastLang = langCode;
      _lastTheme = theme;

      Uri uri = Uri.parse(widget.url);
      final merged = Map<String, String>.from(uri.queryParameters)
        ..['lang'] = langCode
        ..['theme'] = theme;
      if (token.isNotEmpty) {
        merged['auth_token'] = token;
        merged['refresh_token'] = refreshToken;
      }
      uri = uri.replace(queryParameters: merged);
      await _controller.loadRequest(uri);
    } catch (_) {
      // Fallback: load without params; web app will use its own defaults.
      await _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Depend on Theme + Localizations so didChangeDependencies fires (and the
    // change is pushed into the live web page) when either changes natively.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Localizations.localeOf(context);
    // Match the web page's dark background (#111111) so the status-bar strip and
    // the area behind the bottom nav don't flash white in dark mode.
    final bgColor = isDark ? const Color(0xFF111111) : Colors.white;

    return PopScope(
      // Intercept back gestures: navigate inside the WebView first, then
      // fall through to Flutter's navigator pop.
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
        // Keep the WebView at full height when a soft keyboard opens. Otherwise
        // this Scaffold insets its body by the keyboard height, shrinking the
        // WebView surface — which collapses the web page's `100dvh` layout and
        // makes pinned buttons jump up with a white gap. Instead the keyboard
        // overlays the page and the web side keeps the focused field in view
        // (visual-viewport scroll + `interactive-widget=resizes-visual`).
        resizeToAvoidBottomInset: false,
        backgroundColor: bgColor,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              ),
            if (_hasError && !_isLoading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48),
                    const SizedBox(height: 16),
                    const Text('Failed to load page'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        _controller.reload();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
