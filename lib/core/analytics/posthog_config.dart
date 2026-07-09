/// Конфигурация PostHog (self-hosted в Azure, https://ph.libas.uz).
///
/// Ключ и хост можно переопределить при сборке:
///   flutter build apk --dart-define=POSTHOG_KEY=phc_xxx --dart-define=POSTHOG_HOST=https://ph.libas.uz
/// Пустой ключ = PostHog выключен (все вызовы no-op) — приложение работает как раньше.
abstract class PostHogSettings {
  PostHogSettings._();

  static const String apiKey = String.fromEnvironment('POSTHOG_KEY', defaultValue: '');
  static const String host = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://ph.libas.uz',
  );

  static bool get enabled => apiKey.isNotEmpty;
}
