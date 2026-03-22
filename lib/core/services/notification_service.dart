import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/enums/notification_type.dart';
import 'package:swipe/core/globals.dart';
import 'package:swipe/core/services/notification_preferences_service.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/app/routes.dart';

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
    payload: '${message.data["type"] ?? ""}|${message.data["entityId"] ?? ""}',
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
      debugPrint('[FCM] 🗑️ device token deleted');
    } catch (e) {
      debugPrint('[FCM] ⚠️ deleteToken failed: $e');
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
      debugPrint('[FCM] ⚠️ getToken() returned null');
      return;
    }
    debugPrint('[FCM] 🔑 token: $token');

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
      debugPrint('[FCM] ✅ token registered with backend');
    } catch (e) {
      debugPrint('[FCM] ❌ failed to register token: $e');
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
      payload: _buildPayload(message.data),
    );
  }

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[FCM] 📩 onMessage fired — notification: ${message.notification?.title}, data: ${message.data}',
      );
      _showLocalNotification(message);
    });
  }

  void _handleBackgroundTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigate(message.data);
    });
  }

  Future<void> _handleTerminatedTap() async {
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Delay navigation until the widget tree is ready.
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigate(initial.data);
      });
    }
  }

  // ─── Deep-link routing ───────────────────────────────────────────────────────

  String _buildPayload(Map<String, dynamic> data) {
    return '${data['type'] ?? ''}|${data['entityId'] ?? ''}';
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : '';
    final entityId = parts.length > 1 ? parts[1] : null;
    _navigate({'type': type, 'entityId': entityId});
  }

  void _navigate(Map<String, dynamic> data) {
    final typeStr = data['type'] as String? ?? '';
    final entityId = data['entityId'] as String?;
    final type = NotificationType.fromString(typeStr);
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (type) {
      case NotificationType.orderUpdate:
        nav.pushNamed(AppRoutes.orders);
      case NotificationType.newMessage:
        nav.pushNamed(AppRoutes.main);
      case NotificationType.priceDrop:
      case NotificationType.restock:
      case NotificationType.newArrival:
      case NotificationType.recommendation:
        if (entityId != null) {
          nav.pushNamed(AppRoutes.productDetail, arguments: entityId);
        } else {
          nav.pushNamed(AppRoutes.discover);
        }
      case NotificationType.system:
        nav.pushNamed(AppRoutes.notifications);
    }
  }
}
