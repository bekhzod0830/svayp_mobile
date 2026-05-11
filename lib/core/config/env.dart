/// Compile-time environment variables injected via --dart-define-from-file=.env
///
/// Values are baked in at build time — nothing is read at runtime from disk.
/// Pass them when running/building:
///   flutter run --dart-define-from-file=.env
///   flutter build apk --dart-define-from-file=.env
///
/// For CI, set the variables directly:
///   flutter build apk --dart-define=SMARTLOOK_API_KEY=xxx
abstract class Env {
  Env._();

  /// Smartlook project API key from https://app.smartlook.com
  static const String smartlookApiKey = String.fromEnvironment(
    'SMARTLOOK_API_KEY',
    defaultValue: '',
  );
}
