import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_config.dart';

/// Offline-resilient sink that batches generic analytics events to our backend
/// (POST /api/v1/analytics/events/batch). Events are queued in memory, mirrored to
/// SharedPreferences so they survive a kill, and flushed on a timer / when the queue
/// grows / on demand. Auth is optional — anonymous events are accepted by the backend;
/// a token, when available, is attached so the event is attributed to the user.
///
/// Never throws into the caller — analytics must not disrupt the app.
class AnalyticsApiService {
  AnalyticsApiService._();
  static final AnalyticsApiService instance = AnalyticsApiService._();

  static const String _prefsKey = 'analytics_event_queue_v1';
  static const int _maxQueue = 500; // hard cap to bound memory/storage
  static const int _flushThreshold = 20;
  static const Duration _flushInterval = Duration(seconds: 10);

  final List<Map<String, dynamic>> _queue = [];
  Timer? _timer;
  bool _flushing = false;

  /// Supplies a bearer token if the user is logged in (else null). Wired from
  /// AnalyticsService so this file has no dependency on ApiClient internals.
  String? Function()? tokenProvider;

  Future<void> init() async {
    await _restore();
    _timer ??= Timer.periodic(_flushInterval, (_) => flush());
  }

  void enqueue(Map<String, dynamic> event) {
    _queue.add(event);
    if (_queue.length > _maxQueue) {
      _queue.removeRange(0, _queue.length - _maxQueue);
    }
    _persist();
    if (_queue.length >= _flushThreshold) {
      flush();
    }
  }

  Future<void> flush() async {
    if (_flushing || _queue.isEmpty) return;
    _flushing = true;
    final batch = List<Map<String, dynamic>>.from(_queue.take(200));
    try {
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/analytics/events/batch');
      final headers = <String, String>{'Content-Type': 'application/json'};
      final token = tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await http
          .post(uri, headers: headers, body: json.encode({'events': batch}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 || res.statusCode == 201) {
        _queue.removeRange(0, batch.length);
        _persist();
      }
      // Non-2xx → keep events queued for the next flush.
    } catch (_) {
      // Network/serialization failure → keep events queued; retried later.
    } finally {
      _flushing = false;
    }
  }

  void _persist() {
    // Fire-and-forget; never block the caller.
    SharedPreferences.getInstance().then((prefs) {
      try {
        prefs.setString(_prefsKey, json.encode(_queue));
      } catch (_) {/* ignore */}
    });
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = json.decode(raw) as List<dynamic>;
        _queue
          ..clear()
          ..addAll(list.map((e) => Map<String, dynamic>.from(e as Map)));
      }
    } catch (_) {/* ignore corrupt cache */}
  }
}
