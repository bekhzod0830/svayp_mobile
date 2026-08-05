import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/features/tryon/presentation/tryon_failure.dart';
import 'package:swipe/l10n/app_localizations_en.dart';
import 'package:swipe/l10n/app_localizations_uz.dart';

void main() {
  final en = AppLocalizationsEn();

  group('mapTryOnFailure', () {
    test('never leaks a raw provider payload', () {
      // Verbatim shape of what the discovery/shop sheet used to print at users.
      const azure =
          "Error code: 400 - {'error': {'message': 'Your request was rejected by "
          "the safety system. If you believe this is an error, contact us at Azure "
          "support ticket and include the request ID c53c67e3-df14-45'}}";

      final msg = mapTryOnFailure(azure, en);

      expect(msg, en.tryOnFailedSafety);
      expect(msg, isNot(contains('Error code')));
      expect(msg, isNot(contains('{')));
      expect(msg, isNot(contains('Azure')));
    });

    test('buckets an overloaded engine as busy, not as a generic failure', () {
      expect(mapTryOnFailure('429 EngineOverloaded', en), en.tryOnFailedBusy);
      expect(
        mapTryOnFailure('Requests to the endpoint are currently servicing', en),
        en.tryOnFailedBusy,
      );
    });

    test('buckets timeouts', () {
      expect(mapTryOnFailure('Job timed out after 900s', en), en.tryOnFailedTimeout);
    });

    test('falls back to the generic message for null, empty and unknown', () {
      expect(mapTryOnFailure(null, en), en.tryOnFailedGeneric);
      expect(mapTryOnFailure('', en), en.tryOnFailedGeneric);
      expect(mapTryOnFailure('FAILED', en), en.tryOnFailedGeneric);
    });

    test('safety is checked before busy, so a rate-limited safety '
        'rejection still reads as a safety problem', () {
      // Both bucket keywords present: 'rejected'/'safety' must win, because
      // "wait and retry" is the wrong advice for a blocked photo.
      expect(
        mapTryOnFailure('rejected by the safety system (rate limited)', en),
        en.tryOnFailedSafety,
      );
    });

    test('is localized, not English-only', () {
      final uz = AppLocalizationsUz();
      expect(mapTryOnFailure('safety system', uz), uz.tryOnFailedSafety);
      expect(mapTryOnFailure('safety system', uz), isNot(en.tryOnFailedSafety));
    });
  });
}
