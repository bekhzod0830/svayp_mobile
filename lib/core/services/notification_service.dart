import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:swipe/core/enums/notification_type.dart';
import 'package:swipe/core/globals.dart';
import 'package:swipe/core/services/notification_preferences_service.dart';
import 'package:swipe/app/routes.dart';

/// Handles FCM background messages (must be top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized at this point; no need to re-init.
  // We just receive silently — the system tray notification is shown by FCM.
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

  /// Android notification channel for high-importance notifications.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'svayp_high_importance',
    'SVAYP Notifications',
    description: 'Order updates, price drops, new messages and more.',
    importance: Importance.high,
  );

  // ─── Public API ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Register background handler (must be called before any other FCM call).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permission (iOS shows system dialog; Android 13+ needs it too).
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    // 3. Set up local notifications plugin for foreground banners.
    await _setupLocalNotifications();

    // 4. Tell FCM to show heads-up notifications on iOS when app is foreground.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Wire up message handlers.
    _handleForegroundMessages();
    _handleBackgroundTap();
    await _handleTerminatedTap();
  }

  /// Returns the current FCM token for this device.
  /// Call after [initialize] to register with the backend.
  Future<String?> getToken() => _fcm.getToken();

  /// Stream that fires whenever the token is refreshed.
  /// Re-register with the backend inside the listener.
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

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
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Show a heads-up banner while app is in the foreground.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final type = NotificationType.fromString(
      message.data['type'] as String? ?? '',
    );

    // Respect per-type user preference.
    final prefs = NotificationPreferencesService.instance;
    if (!prefs.isEnabled(type)) return;

    final notification = message.notification;
    if (notification == null) return;

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
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: _buildPayload(message.data),
    );
  }

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
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
