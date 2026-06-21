import 'package:permission_handler/permission_handler.dart';
import 'package:swipe/core/services/notification_service.dart';

/// Coordinates the system permission prompts shown at app startup.
///
/// The OS can only present ONE permission dialog at a time. The closet WebView
/// requests camera/photos while the Discover screen requests notifications, and
/// because [MainScreen]'s IndexedStack builds every tab at once these requests
/// fired simultaneously on first launch — the OS showed the photo dialog and
/// silently dropped the notification one, so notifications were only ever
/// requested on the *second* launch (once photos was already granted and no
/// longer needed a dialog).
///
/// Routing every startup request through [requestStartupPermissions] serializes
/// them behind a single shared future: the prompts appear one after another
/// (notifications → camera → photos) and each permission is requested only once
/// per app session — even when several call sites fire concurrently.
class AppPermissions {
  AppPermissions._();

  static Future<void>? _startupRequest;

  /// Requests every permission the app needs at startup, in sequence, exactly
  /// once per app session. Safe to call from multiple call sites concurrently —
  /// they all await the same underlying request rather than racing the OS.
  static Future<void> requestStartupPermissions() {
    return _startupRequest ??= _run();
  }

  static Future<void> _run() async {
    // Notifications first — requests permission and registers the FCM token.
    await NotificationService.instance.requestPermissionAndRegisterToken();
    // Then camera + photo library — needed by the closet/seller WebViews.
    await [Permission.camera, Permission.photos].request();
  }
}
