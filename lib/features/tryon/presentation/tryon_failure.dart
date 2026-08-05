import 'package:swipe/l10n/app_localizations.dart';

/// Turns a raw backend try-on failure into a message a person can act on.
///
/// `failureReason` is whatever the provider handed back, and that is routinely
/// a raw Azure/OpenAI payload — e.g.
/// `Error code: 400 - {'error': {'message': 'Your request was rejected by the
/// safety system. ... include the request ID c53c67e3-df14-45...'}}`. Showing
/// that verbatim is what the closet web app deliberately avoids, so this
/// mirrors its `mapTryOnFailure` (see swipe-web
/// `components/closet/TryOnFlow.tsx`) bucket for bucket: the two surfaces must
/// not disagree about what the same job failure means.
///
/// Keep the bucket order in step with the web version when either changes —
/// 'quota' matches the busy bucket before the generic fallback, and safety is
/// checked first because a safety rejection can also mention a request id.
String mapTryOnFailure(String? reason, AppLocalizations l10n) {
  final r = (reason ?? '').toLowerCase();

  if (r.contains('safety') ||
      r.contains('content policy') ||
      r.contains('content_policy') ||
      r.contains('moderation') ||
      r.contains('policy') ||
      r.contains('rejected')) {
    return l10n.tryOnFailedSafety;
  }

  // Engine overloaded / rate-limited (Azure 429 EngineOverloaded and friends).
  if (r.contains('busy') ||
      r.contains('overloaded') ||
      r.contains('429') ||
      r.contains('too many') ||
      r.contains('rate') ||
      r.contains('quota') ||
      r.contains('currently servicing')) {
    return l10n.tryOnFailedBusy;
  }

  if (r.contains('timed out') || r.contains('timeout')) {
    return l10n.tryOnFailedTimeout;
  }

  return l10n.tryOnFailedGeneric;
}
