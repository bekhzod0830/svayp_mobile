/// Пауза записи экрана (PostHog session replay).
///
/// Запись снимает весь экран раз в секунду: сравнивает пиксели на UI-потоке,
/// кодирует PNG и отдаёт в натив. На слабом планшете зеркала это заметные
/// рывки, а в кадре — лица покупателей, поэтому в режиме киоска запись стоит.
///
/// Отдельный класс без PostHog внутри — чтобы логику паузы можно было проверить
/// тестом: реальные вызовы плагина приходят снаружи.
class SessionReplayPause {
  SessionReplayPause({
    required this.enabled,
    required Future<void> Function() stop,
    required Future<void> Function() start,
  }) : _stop = stop,
       _start = start;

  /// PostHog вообще включён в этой сборке (задан ключ). Без него — no-op.
  final bool enabled;

  final Future<void> Function() _stop;
  final Future<void> Function() _start;

  bool _paused = false;

  bool get paused => _paused;

  /// Поставить запись на паузу или вернуть. Повтор с тем же значением плагин
  /// не дёргает.
  Future<void> set(bool paused) async {
    if (_paused == paused) return;
    _paused = paused;
    await apply();
  }

  /// Привести плагин к текущему состоянию. Зовётся и после инициализации
  /// PostHog: setup включает запись сам, даже если киоск уже открыт.
  Future<void> apply() async {
    if (!enabled) return;
    try {
      await (_paused ? _stop() : _start());
    } catch (_) {
      /* аналитика никогда не роняет приложение */
    }
  }
}
