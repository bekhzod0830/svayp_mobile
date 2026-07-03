import 'package:uuid/uuid.dart';

/// Derives an analytics session id on the client: one UUID per app launch, rotated
/// after [_timeout] of inactivity. No server-side sessions table — backend aggregates
/// session metrics by session_id. Call [currentId] on every tracked event; it touches
/// the activity clock and rotates the id when the gap exceeds the timeout.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  static const Duration _timeout = Duration(minutes: 30);
  static const _uuid = Uuid();

  String _id = _uuid.v4();
  DateTime _lastActivity = DateTime.now();

  /// Returns the current session id, rotating it if the app was idle past the timeout.
  String currentId() {
    final now = DateTime.now();
    if (now.difference(_lastActivity) > _timeout) {
      _id = _uuid.v4();
    }
    _lastActivity = now;
    return _id;
  }

  /// Force a brand-new session (e.g. on explicit session_start at app resume).
  String rotate() {
    _id = _uuid.v4();
    _lastActivity = DateTime.now();
    return _id;
  }

  /// True if the app has been idle longer than the session timeout.
  bool get isExpired => DateTime.now().difference(_lastActivity) > _timeout;
}
