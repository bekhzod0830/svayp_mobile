import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/enums/notification_type.dart';
import 'package:swipe/core/globals.dart';
import 'package:swipe/core/services/badge_notifier.dart';
import 'package:swipe/core/services/notification_preferences_service.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/widgets/in_app_message_dialog.dart';
import 'package:swipe/app/routes.dart';
import 'package:swipe/core/constants/web_urls.dart';
import 'package:swipe/shared/widgets/web_view_screen.dart';
import 'package:swipe/features/chat/data/services/chat_websocket_service.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';

/// Builds the JSON payload carried by a local notification so a tap can later
/// reconstruct the message (type, target entity, text and image).
String buildNotificationPayload(Map<String, dynamic> data) {
  return jsonEncode({
    'type': data['type'] ?? '',
    'entityId': data['entityId'],
    'title': data['title'],
    'body': data['body'],
    'image': data['image'] ?? data['imageUrl'],
    // Optional explicit deep-link targets (override type-based routing).
    'tab': data['tab'],
    'route': data['route'],
    'url': data['url'],
  });
}

/// Handles FCM background messages (must be top-level).
/// For data-only messages (no `notification` key) the OS won't auto-show a
/// banner, so we do it manually here via flutter_local_notifications.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Don't show notifications if the user has logged out.
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('fcm_enabled') != true) return;
  if (prefs.getString('auth_token') == null) return;

  // Only needed for data-only messages; if there's already a notification
  // payload the OS will show it automatically.
  if (message.notification != null) return;

  final title = message.data['title'] as String?;
  final body = message.data['body'] as String?;
  if (title == null && body == null) return;

  const channel = AndroidNotificationChannel(
    'svayp_high_importance',
    'SVAYP Notifications',
    importance: Importance.high,
  );

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await plugin.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: buildNotificationPayload(message.data),
  );
}

/// Central service for Firebase Cloud Messaging.
///
/// Lifecycle:
/// 1. [initialize] — called once in main.dart after Firebase.initializeApp()
/// 2. Requests permission, registers device token, sets up message handlers.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _tokenRefreshListenerAdded = false;
  bool _registrationEnabled = false;

  /// Holds a cold-start notification (tapped while the app was terminated)
  /// until the app has finished navigating to its landing screen. Firing it
  /// earlier shows the popup/deep-link on top of the splash route, which is
  /// then destroyed by the splash's pushReplacement — losing the popup.
  /// Flushed via [flushPendingInitialNotification] once the main screen mounts.
  VoidCallback? _pendingInitialNotification;

  static const String _fcmEnabledKey = 'fcm_enabled';

  /// Android notification channel for high-importance notifications.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'svayp_high_importance',
    'SVAYP Notifications',
    description: 'Order updates, price drops, new messages and more.',
    importance: Importance.high,
  );

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Call once in main() — registers handlers and sets up local notifications.
  /// Does NOT request permission or show any system dialog.
  Future<void> initialize() async {
    // 1. Restore persisted login state so foreground guard works after cold start.
    final prefs = await SharedPreferences.getInstance();
    _registrationEnabled = prefs.getBool(_fcmEnabledKey) ?? false;

    // 2. Register background handler (must be called before any other FCM call).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Set up local notifications plugin for foreground banners.
    await _setupLocalNotifications();

    // 4. Wire up message handlers.
    _handleForegroundMessages();
    _handleBackgroundTap();
    await _handleTerminatedTap();
  }

  /// Call from the Discovery screen (after login/registration).
  /// Requests permission, configures foreground presentation, and registers
  /// the FCM token with the backend. Safe to call on every app launch —
  /// iOS only shows the system dialog once; subsequent calls are silent.
  Future<void> requestPermissionAndRegisterToken() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    await _fcm.setForegroundNotificationPresentationOptions(
      alert:
          false, // flutter_local_notifications handles the banner — avoids duplicate
      badge: true, // still update the app icon badge count
      sound: false, // flutter_local_notifications plays the sound
    );

    _registrationEnabled = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fcmEnabledKey, true);

    // Register token now and on every refresh (guard against duplicate listeners).
    await registerTokenWithBackend();
    if (!_tokenRefreshListenerAdded) {
      _tokenRefreshListenerAdded = true;
      _fcm.onTokenRefresh.listen((_) => registerTokenWithBackend());
    }
  }

  /// Call on logout — disables token re-registration and deletes the device
  /// token from FCM so no further notifications are delivered.
  Future<void> onLogout() async {
    // Persist BEFORE deleteToken() so the background handler (separate isolate)
    // and the onTokenRefresh callback both see the disabled state immediately.
    _registrationEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fcmEnabledKey, false);
    try {
      await _fcm.deleteToken();
    } catch (e) {
    }
  }

  /// Returns the current FCM token for this device.
  /// Call after [initialize] to register with the backend.
  Future<String?> getToken() => _fcm.getToken();

  /// Stream that fires whenever the token is refreshed.
  /// Re-register with the backend inside the listener.
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  /// Registers the FCM token + current app language with the backend.
  /// Call this after login and whenever [onTokenRefresh] fires.
  Future<void> registerTokenWithBackend() async {
    if (!_registrationEnabled) return;
    final token = await _fcm.getToken();
    if (token == null) {
      return;
    }

    final languageCode = await LanguageService().getCurrentLanguageCode();

    try {
      final api = getIt<ApiClient>();
      await api.put<dynamic>(
        '/users/me/fcm-token',
        data: {
          'fcm_token': token,
          'language': languageCode,
          'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
        },
      );
    } catch (e) {
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested via FCM above.
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Tapped while app is open (foreground local notification).
        _handleNotificationTap(details.payload);
      },
    );

    // Create the Android high-importance channel.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  /// Show a heads-up banner while app is in the foreground.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Read login state fresh from SharedPreferences — the in-memory flag can
    // be stale after hot-restart or cross-isolate operations.
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool('fcm_enabled') != true) return;
    if (sp.getString('auth_token') == null) return;
    final type = NotificationType.fromString(
      message.data['type'] as String? ?? '',
    );

    // Respect per-type user preference.
    final prefs = NotificationPreferencesService.instance;
    if (!prefs.isEnabled(type)) return;

    // Support both notification-payload messages and data-only messages.
    final title =
        message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: buildNotificationPayload({
        ...message.data,
        'title': title,
        'body': body,
        'image': _imageUrlFromMessage(message),
      }),
    );
  }

  /// Extracts an image URL from an FCM message, checking the notification
  /// payload (Android/Apple) first, then common data keys.
  static String? _imageUrlFromMessage(RemoteMessage message) {
    return message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        message.data['image'] as String? ??
        message.data['imageUrl'] as String?;
  }

  // ─── Local notification persistence ──────────────────────────────────────

  static const String _localNotifKey = 'fcm_local_notifications_v1';
  static const int _localNotifMaxCount = 100;

  /// Persist a received FCM notification to SharedPreferences so it can be
  /// shown in the Notifications screen even when the backend didn't store it.
  static Future<void> saveLocalNotification({
    required String title,
    required String body,
    required String type,
    String? entityId,
    String? imageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localNotifKey);
      final List<dynamic> list = raw != null ? jsonDecode(raw) as List : [];
      list.insert(0, {
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'body': body,
        'type': type,
        'entity_id': entityId,
        'image_url': imageUrl,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_read': false,
        'is_local': true,
      });
      if (list.length > _localNotifMaxCount) {
        list.removeRange(_localNotifMaxCount, list.length);
      }
      await prefs.setString(_localNotifKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Load all locally persisted notifications.
  static Future<List<Map<String, dynamic>>> loadLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localNotifKey);
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Mark all locally stored notifications as read.
  static Future<void> markLocalNotificationsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localNotifKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final item in list) {
        item['is_read'] = true;
      }
      await prefs.setString(_localNotifKey, jsonEncode(list));
    } catch (_) {}
  }

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      // Mark the notification bell badge for all incoming messages.
      BadgeNotifier.instance.markUnreadNotifications();

      // Persist the notification locally so it appears in the Notifications
      // screen even if the backend did not store it.
      final title =
          message.notification?.title ?? message.data['title'] as String? ?? '';
      final body =
          message.notification?.body ?? message.data['body'] as String? ?? '';
      final typeStr = message.data['type'] as String? ?? '';
      final entityId = message.data['entityId'] as String?;
      if (title.isNotEmpty || body.isNotEmpty) {
        saveLocalNotification(
          title: title,
          body: body,
          type: typeStr.isEmpty ? 'SYSTEM' : typeStr,
          entityId: entityId,
          imageUrl: _imageUrlFromMessage(message),
        );
      }

      // When a message arrives for a chat the WS isn't subscribed to yet
      // (e.g. a buyer started a brand-new conversation with the seller),
      // subscribe to that chatId so future messages arrive via WS, and
      // count this first message in the badge since the WS drop it.
      if (NotificationType.fromString(typeStr) == NotificationType.newMessage) {
        final chatId = entityId;
        if (chatId != null) {
          final wsService = getIt<ChatWebSocketService>();
          final wasNew = wsService.addChatToList(chatId);
          if (wasNew) {
            wsService.unreadCountNotifier.value += 1;
          }
        }
      }
    });
  }

  void _handleBackgroundTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationOpen(
        typeStr: message.data['type'] as String? ?? '',
        entityId: message.data['entityId'] as String?,
        title: message.notification?.title ?? message.data['title'] as String?,
        body: message.notification?.body ?? message.data['body'] as String?,
        imageUrl: _imageUrlFromMessage(message),
        tab: message.data['tab'] as String?,
        route: message.data['route'] as String?,
        url: message.data['url'] as String?,
      );
    });
  }

  Future<void> _handleTerminatedTap() async {
    final initial = await _fcm.getInitialMessage();
    if (initial == null) return;

    // The app is cold-starting: the splash screen is still showing and will
    // pushReplacement to the landing route once auth/profile verification
    // completes. Handling the tap now would surface the popup/deep-link on the
    // splash route, which the pushReplacement then tears down. Stash it and let
    // the main screen flush it once navigation has settled.
    _pendingInitialNotification = () {
      handleNotificationOpen(
        typeStr: initial.data['type'] as String? ?? '',
        entityId: initial.data['entityId'] as String?,
        title: initial.notification?.title ?? initial.data['title'] as String?,
        body: initial.notification?.body ?? initial.data['body'] as String?,
        imageUrl: _imageUrlFromMessage(initial),
        tab: initial.data['tab'] as String?,
        route: initial.data['route'] as String?,
        url: initial.data['url'] as String?,
      );
    };
  }

  /// Processes a cold-start notification that was deferred during startup.
  ///
  /// Call once the app has reached its landing screen (e.g. from the main
  /// screen's first frame) so the deep-link/popup lands on the real route
  /// instead of the splash route that gets replaced during startup. No-op if
  /// there is no pending notification.
  void flushPendingInitialNotification() {
    final pending = _pendingInitialNotification;
    if (pending == null) return;
    _pendingInitialNotification = null;
    pending();
  }

  // ─── Deep-link routing ───────────────────────────────────────────────────────

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    Map<String, dynamic> data;
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      // Backward-compat with the old `type|entityId` payload format.
      final parts = payload.split('|');
      data = {
        'type': parts.isNotEmpty ? parts[0] : '',
        'entityId': parts.length > 1 ? parts[1] : null,
      };
    }
    handleNotificationOpen(
      typeStr: data['type'] as String? ?? '',
      entityId: data['entityId'] as String?,
      title: data['title'] as String?,
      body: data['body'] as String?,
      imageUrl: data['image'] as String?,
      tab: data['tab'] as String?,
      route: data['route'] as String?,
      url: data['url'] as String?,
    );
  }

  /// Bottom-nav tab names, in nav-bar order. Index = tab index used by
  /// [MainScreenState.navigateToTab].
  static const List<String> _tabNames = [
    'feed',
    'closet',
    'market',
    'shop',
    'chat',
    'discover',
  ];

  /// Resolves a notification `tab` value to a bottom-nav tab index.
  /// Accepts a tab name ('feed', 'closet', 'market', 'shop', 'chat',
  /// 'discover') or a numeric string ('0'–'5'). Returns null if no match.
  static int? _tabIndexFromValue(String? tab) {
    if (tab == null || tab.isEmpty) return null;
    final byName = _tabNames.indexOf(tab.toLowerCase());
    if (byName != -1) return byName;
    final byNumber = int.tryParse(tab);
    if (byNumber != null && byNumber >= 0 && byNumber < _tabNames.length) {
      return byNumber;
    }
    return null;
  }

  /// Handles opening a notification (tapped banner, list item, or cold start).
  ///
  /// An explicit [tab], [route], and/or [url] in the payload takes precedence
  /// for navigation:
  ///  - [tab] switches the bottom-nav tab (closet/market/shop/chat/discover).
  ///  - [route] pushes a native Flutter named page on top (with [entityId] as
  ///    its route argument) — for pages registered in [AppRoutes].
  ///  - [url] opens a web page (e.g. '/market/create') in a full-screen WebView
  ///    — for pages that live in the web app, not the native router.
  /// When none is given, navigation falls back to type-based routing.
  ///
  /// Independently, SYSTEM messages with text/image always surface as an in-app
  /// popup — shown on top of whatever destination the navigation resolved to.
  static void handleNotificationOpen({
    required String typeStr,
    String? entityId,
    String? title,
    String? body,
    String? imageUrl,
    String? tab,
    String? route,
    String? url,
  }) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final type = NotificationType.fromString(typeStr);

    // Explicit deep-link target from the payload wins over type-based routing.
    final tabIndex = _tabIndexFromValue(tab);
    final hasRoute = route != null && route.isNotEmpty;
    final hasUrl = url != null && url.isNotEmpty;
    if (tabIndex != null || hasRoute || hasUrl) {
      if (tabIndex != null) {
        // No-op if the main screen isn't mounted (e.g. on the auth flow).
        MainScreen.globalKey.currentState?.navigateToTab(tabIndex);
      }
      if (hasRoute) {
        nav.pushNamed(route, arguments: entityId);
      }
      if (hasUrl) {
        // Web pages (Market, Closet, etc.) live in the web app, not AppRoutes —
        // open them in a full-screen WebView instead of the native router.
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => WebViewScreen(url: WebUrls.resolve(url)),
          ),
        );
      }
      // The popup is opt-in here: only an explicit `type: SYSTEM` shows it on
      // top of the destination. Any other (or missing) type navigates silently
      // — note NotificationType.fromString defaults unknown types to system,
      // so we check the raw value, not the parsed enum.
      // Skip the no-content fallback so it can't override the navigation above.
      final hasContent = (title?.isNotEmpty ?? false) ||
          (body?.isNotEmpty ?? false) ||
          (imageUrl?.isNotEmpty ?? false);
      if (typeStr == NotificationType.system.value && hasContent) {
        _showSystemMessage(
          title: title ?? '',
          body: body ?? '',
          imageUrl: imageUrl,
        );
      }
      return;
    }

    switch (type) {
      case NotificationType.orderUpdate:
        if (entityId != null && entityId.isNotEmpty) {
          nav.pushNamed(AppRoutes.orderDetail, arguments: entityId);
        } else {
          nav.pushNamed(AppRoutes.orders);
        }
      case NotificationType.newMessage:
        if (entityId != null && entityId.isNotEmpty) {
          nav.pushNamed(AppRoutes.chatDetail, arguments: entityId);
        } else {
          nav.pushNamed(AppRoutes.chatList);
        }
      case NotificationType.priceDrop:
      case NotificationType.restock:
      case NotificationType.newArrival:
      case NotificationType.recommendation:
        if (entityId != null && entityId.isNotEmpty) {
          nav.pushNamed(AppRoutes.productDetail, arguments: entityId);
        } else {
          nav.pushNamed(AppRoutes.discover);
        }
      case NotificationType.feedLike:
      case NotificationType.feedComment:
        // Feed lives in a WebView tab — open it. No-op if MainScreen isn't mounted.
        MainScreen.globalKey.currentState
            ?.navigateToTab(_tabNames.indexOf('feed'));
      case NotificationType.system:
        _showSystemMessage(
          title: title ?? '',
          body: body ?? '',
          imageUrl: imageUrl,
        );
    }
  }

  /// Shows a SYSTEM notification as an in-app popup. Falls back to the
  /// notifications list when there's no content to display.
  static void _showSystemMessage({
    required String title,
    required String body,
    String? imageUrl,
  }) {
    final ctx = navigatorKey.currentContext;
    final hasContent =
        title.isNotEmpty || body.isNotEmpty || (imageUrl?.isNotEmpty ?? false);
    if (ctx == null || !hasContent) {
      navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
      return;
    }
    showInAppMessageDialog(
      ctx,
      title: title,
      body: body,
      imageUrl: imageUrl,
    );
  }
}
