import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (_) {
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
    // Load the URL with auth tokens embedded as query params so the web app
    // can store them before its auth guard runs.
    _loadWithToken();
  }

  Future<void> _requestNativePermissions() async {
    await [Permission.camera, Permission.photos].request();
  }

  /// Reads the stored tokens from SharedPreferences and loads the target URL
  /// with auth_token / refresh_token appended as query parameters.
  ///
  /// The web app reads these params in _app.tsx before its auth guard runs,
  /// stores them in localStorage, and strips them from the URL — so the token
  /// never stays visible in the address bar and no JS injection timing race
  /// exists.
  Future<void> _loadWithToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final refreshToken = prefs.getString('refresh_token') ?? '';

      Uri uri = Uri.parse(widget.url);
      if (token.isNotEmpty) {
        final merged = Map<String, String>.from(uri.queryParameters)
          ..['auth_token'] = token
          ..['refresh_token'] = refreshToken;
        uri = uri.replace(queryParameters: merged);
      }
      await _controller.loadRequest(uri);
    } catch (_) {
      // Fallback: load without token; web app will show its own login.
      await _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Colors.white,
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
