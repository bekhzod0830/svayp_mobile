import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'analytics_api_service.dart';
import 'posthog_config.dart';
import 'session_manager.dart';

/// Unified analytics dispatcher. Every event fans out to:
///   • Firebase Analytics — funnels, retention, custom events (Google console)
///   • Our backend (app_events) — GA-like dashboard in the admin + ML signals
///   • PostHog — wired in Phase C (posthog_flutter)
///
/// Each event is enriched with session_id, platform, app version/build, OS version,
/// anon_id, source and the current screen, so the backend can power Acquisition /
/// Engagement / Retention / Tech without per-call boilerplate.
///
/// Usage:
///   AnalyticsService.instance.logEvent(AnalyticsEvents.otpRequested);
///   AnalyticsService.instance.setUser(userId: '123', phone: '+998...');
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _firebase = FirebaseAnalytics.instance;
  static const _uuid = Uuid();
  static const String _anonKey = 'analytics_anon_id';

  // ─── Enrichment context ────────────────────────────────────────────────────
  final String _platform =
      Platform.isIOS ? 'iOS' : (Platform.isAndroid ? 'Android' : 'other');
  String? _appVersion;
  int? _appBuild;
  String? _osVersion;
  String? _deviceModel;
  String? _anonId;
  String? _userId;
  String? _currentScreen;

  // ─── Initialisation ────────────────────────────────────────────────────────

  /// Call once from main() after Firebase is ready.
  Future<void> init() async {
    await _firebase.setAnalyticsCollectionEnabled(true);

    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _appBuild = int.tryParse(info.buildNumber);
    } catch (_) {/* version is best-effort */}

    // Человекочитаемые ОС и модель ("Android 14", "SM-A525F") вместо
    // build-fingerprint из Platform.operatingSystemVersion — иначе в дашборде
    // «Технологии» версии нечитаемы, а device_model вовсе не заполнялся.
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        _osVersion = 'Android ${android.version.release}';
        _deviceModel = android.model;
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        _osVersion = 'iOS ${ios.systemVersion}';
        _deviceModel = ios.utsname.machine;
      }
    } catch (_) {/* os version is best-effort */}
    _osVersion ??= '$_platform ${Platform.operatingSystemVersion}';

    await _loadAnonId();
    await AnalyticsApiService.instance.init();
    await _initPostHog();
  }

  /// PostHog (self-hosted) — включается только при заданном POSTHOG_KEY.
  Future<void> _initPostHog() async {
    if (!PostHogSettings.enabled) return;
    try {
      final config = PostHogConfig(PostHogSettings.apiKey)
        ..host = PostHogSettings.host
        ..captureApplicationLifecycleEvents = true
        // Session replay: запись экранов/жестов для просмотра «что делал юзер»
        // в PostHog → Session replay.
        ..sessionReplay = true
        ..debug = false;
      // Видимость записи: по умолчанию SDK маскирует ВСЁ (тексты, картинки,
      // platform views). Тексты и картинки открываем — иначе нативные экраны
      // в записи бесполезны.
      // ВНИМАНИЕ: с maskAllTexts=false в записи видны и вводимые тексты
      // (телефон/OTP на экране входа).
      //
      // maskAllPlatformViews ОСТАВЛЯЕМ true: с false плагин включает нативный
      // захват, и его fallback (captureNativeScreenshotFallback) КРАШИТ
      // приложение на hybrid-composition WebView: "Software rendering doesn't
      // support hardware bitmaps" (баг posthog_flutter 5.30, PosthogFlutterPlugin.kt:863).
      // Вебвью в мобильной записи остаётся чёрным — его детальная запись идёт
      // отдельным web-реплеем из webapp.
      config.sessionReplayConfig
        ..maskAllImages = false
        ..maskAllTexts = false;
      await Posthog().setup(config);
    } catch (_) {/* аналитика никогда не роняет приложение */}
  }

  /// Wire the auth-token getter so backend events are attributed to the logged-in user.
  /// Anonymous events still flow (and carry anon_id) when no token is available.
  void attachTokenProvider(String? Function() provider) {
    AnalyticsApiService.instance.tokenProvider = provider;
  }

  Future<void> _loadAnonId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _anonId = prefs.getString(_anonKey);
      if (_anonId == null) {
        _anonId = _uuid.v4();
        await prefs.setString(_anonKey, _anonId!);
      }
    } catch (_) {
      _anonId ??= _uuid.v4();
    }
  }

  // ─── User Identity ─────────────────────────────────────────────────────────

  /// Call after a successful login / registration.
  Future<void> setUser({
    required String userId,
    String? phone,
    String? username,
    String? tier,
    String? source,
  }) async {
    _userId = userId;
    await _firebase.setUserId(id: userId);
    if (phone != null && phone.isNotEmpty) {
      await _firebase.setUserProperty(name: 'phone_number', value: phone);
    }
    if (username != null && username.isNotEmpty) {
      await _firebase.setUserProperty(name: 'username', value: username);
    }
    if (tier != null && tier.isNotEmpty) {
      await _firebase.setUserProperty(name: 'tier', value: tier);
    }
    if (source != null && source.isNotEmpty) {
      await _firebase.setUserProperty(name: 'registration_source', value: source);
    }
    if (_appVersion != null) {
      await _firebase.setUserProperty(name: 'app_version', value: _appVersion);
    }
    await _firebase.setUserProperty(name: 'platform', value: _platform);

    if (PostHogSettings.enabled) {
      try {
        await Posthog().identify(userId: userId, userProperties: {
          if (username != null && username.isNotEmpty) 'username': username,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (tier != null && tier.isNotEmpty) 'tier': tier,
          'platform': _platform,
        });
      } catch (_) {/* ignore */}
    }
  }

  /// Call on logout to disassociate the session from the user.
  Future<void> clearUser() async {
    _userId = null;
    await _firebase.setUserId(id: null);
    if (PostHogSettings.enabled) {
      try {
        await Posthog().reset();
      } catch (_) {/* ignore */}
    }
  }

  // ─── Screen Tracking ───────────────────────────────────────────────────────

  /// Record the current screen. Updates enrichment context and emits a screen_view
  /// event to the backend (Firebase screen_view is handled by the NavigatorObserver).
  Future<void> setScreen(String screenName) async {
    _currentScreen = screenName;
    _enqueueBackend('screen_view', {'screen': screenName});
  }

  Future<void> logScreen(String screenName) async {
    _currentScreen = screenName;
    await _firebase.logScreenView(screenName: screenName);
    _enqueueBackend('screen_view', {'screen': screenName});
    if (PostHogSettings.enabled) {
      try {
        await Posthog().screen(screenName: screenName);
      } catch (_) {/* ignore */}
    }
  }

  Future<void> logScreenExit(String screenName) async {}

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  void logAppOpen() => logEvent('app_open');

  void logSessionStart() {
    SessionManager.instance.rotate();
    logEvent('session_start');
  }

  void logSessionEnd() => logEvent('session_end');

  // ─── Event Logging ─────────────────────────────────────────────────────────

  /// Log a named event with optional string parameters. Fans out to Firebase and
  /// our backend (app_events). Never throws.
  Future<void> logEvent(
    String name, {
    Map<String, String>? parameters,
  }) async {
    try {
      await _firebase.logEvent(
        name: name,
        parameters: parameters?.cast<String, Object>(),
      );
    } catch (_) {/* never disrupt the app */}

    _enqueueBackend(name, parameters);

    if (PostHogSettings.enabled) {
      try {
        await Posthog().capture(eventName: name, properties: parameters ?? const {});
      } catch (_) {/* ignore */}
    }
  }

  void _enqueueBackend(String name, Map<String, String>? parameters) {
    try {
      // Wire-формат — snake_case, единый с webapp (бэкенд принимает оба
      // варианта через @JsonAlias, но шлём канонический).
      final event = <String, dynamic>{
        'event_name': name,
        'session_id': SessionManager.instance.currentId(),
        'anon_id': _anonId,
        'platform': _platform,
        'source': 'mobile',
        'client_ts': DateTime.now().toUtc().toIso8601String(),
        if (_appVersion != null) 'app_version': _appVersion,
        if (_appBuild != null) 'app_build': _appBuild,
        if (_osVersion != null) 'os_version': _osVersion,
        if (_deviceModel != null) 'device_model': _deviceModel,
        if (_currentScreen != null) 'screen': _currentScreen,
        if (parameters != null && parameters.isNotEmpty) 'properties': parameters,
      };
      AnalyticsApiService.instance.enqueue(event);
    } catch (_) {/* analytics must never break the caller */}
  }

  /// Flush the backend queue (e.g. on app pause). Best-effort.
  Future<void> flush() => AnalyticsApiService.instance.flush();

  // ─── Session-replay helpers (Smartlook/PostHog — Phase C) ───────────────────

  Future<void> pauseRecording() async {}

  Future<void> resumeRecording() async {}
}
