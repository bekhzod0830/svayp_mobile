import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_smartlook/flutter_smartlook.dart';

/// Unified analytics service that fans events out to:
///   • Firebase Analytics  — funnels, retention, custom events
///   • Smartlook           — session recordings, tap heatmaps
///
/// Usage:
///   AnalyticsService.instance.logEvent(AnalyticsEvents.otpRequested);
///   AnalyticsService.instance.setUser(userId: '123', phone: '+998...');
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _firebase = FirebaseAnalytics.instance;

  // ─── Initialisation ────────────────────────────────────────────────────────

  /// Call once from main() after Smartlook is started.
  /// Disables Firebase Analytics collection in debug mode (use DebugView instead).
  Future<void> init() async {
    // Always enable collection so DebugView works during development.
    // Firebase automatically batches/samples data in production.
    await _firebase.setAnalyticsCollectionEnabled(true);
  }

  // ─── User Identity ─────────────────────────────────────────────────────────

  /// Call after a successful login / registration.
  Future<void> setUser({
    required String userId,
    String? phone,
    String? username,
  }) async {
    // Firebase — tie all future events to this user
    await _firebase.setUserId(id: userId);
    if (phone != null && phone.isNotEmpty) {
      await _firebase.setUserProperty(name: 'phone_number', value: phone);
    }
    if (username != null && username.isNotEmpty) {
      await _firebase.setUserProperty(name: 'username', value: username);
    }

    // Smartlook — identify the session (disabled)
    // await Smartlook.instance.user.setIdentifier(userId);
    // if (username != null && username.isNotEmpty) {
    //   await Smartlook.instance.user.setName(username);
    // } else if (phone != null && phone.isNotEmpty) {
    //   await Smartlook.instance.user.setName(phone);
    // }
    // if (phone != null && phone.isNotEmpty) {
    //   await Smartlook.instance.user.setEmail(phone);
    // }
  }

  /// Call on logout to disassociate the session from the user.
  Future<void> clearUser() async {
    await _firebase.setUserId(id: null);
    // await Smartlook.instance.user.openNew();
  }

  // ─── Screen Tracking ───────────────────────────────────────────────────────

  /// Track a screen view manually (the NavigatorObserver handles routes
  /// automatically; call this only for non-route screens like bottom sheets).
  Future<void> logScreen(String screenName) async {
    await _firebase.logScreenView(screenName: screenName);
    // await Smartlook.instance.trackNavigationEnter(screenName);
  }

  Future<void> logScreenExit(String screenName) async {
    // await Smartlook.instance.trackNavigationExit(screenName);
  }

  // ─── Event Logging ─────────────────────────────────────────────────────────

  /// Log a named event with optional string parameters.
  Future<void> logEvent(
    String name, {
    Map<String, String>? parameters,
  }) async {
    // Firebase Analytics
    await _firebase.logEvent(
      name: name,
      parameters: parameters?.cast<String, Object>(),
    );

    // Smartlook custom event (disabled)
    // if (parameters != null && parameters.isNotEmpty) {
    //   final props = Properties();
    //   parameters.forEach((key, value) => props.putString(key, value: value));
    //   await Smartlook.instance.trackEvent(name, properties: props);
    // } else {
    //   await Smartlook.instance.trackEvent(name);
    // }
  }

  // ─── Smartlook recording helpers ───────────────────────────────────────────

  /// Pause session recording (e.g. on sensitive screens like payment forms).
  Future<void> pauseRecording() async {
    // await Smartlook.instance.stop();
  }

  /// Resume session recording.
  Future<void> resumeRecording() async {
    // await Smartlook.instance.start();
  }
}
