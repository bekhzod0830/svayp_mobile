import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/core/analytics/session_replay_pause.dart';

void main() {
  late List<String> calls;

  SessionReplayPause pause({bool enabled = true, bool failing = false}) {
    return SessionReplayPause(
      enabled: enabled,
      stop: () async {
        calls.add('stop');
        if (failing) throw StateError('плагин не поднят');
      },
      start: () async {
        calls.add('start');
        if (failing) throw StateError('плагин не поднят');
      },
    );
  }

  setUp(() => calls = []);

  test('вход в киоск останавливает запись, выход — возвращает', () async {
    final p = pause();
    await p.set(true);
    expect(p.paused, isTrue);
    expect(calls, ['stop']);

    await p.set(false);
    expect(p.paused, isFalse);
    expect(calls, ['stop', 'start']);
  });

  test('повтор с тем же значением плагин не дёргает', () async {
    final p = pause();
    // Киоск закрыт с самого начала — запись и так идёт, запускать нечего.
    await p.set(false);
    expect(calls, isEmpty);

    // Вход в киоск зовётся и при старте, и при возврате приложения на экран.
    await p.set(true);
    await p.set(true);
    expect(calls, ['stop']);
  });

  test('сборка без ключа PostHog: ничего не зовётся', () async {
    final p = pause(enabled: false);
    await p.set(true);
    await p.set(false);
    await p.apply();
    expect(calls, isEmpty);
  });

  test('PostHog поднялся позже входа в киоск — пауза применяется повторно', () async {
    final p = pause();
    await p.set(true);
    // setup плагина сам включает запись — сервис аналитики зовёт apply() после него.
    await p.apply();
    expect(calls, ['stop', 'stop']);
  });

  test('сбой плагина не роняет киоск и не теряет состояние', () async {
    final p = pause(failing: true);
    await expectLater(p.set(true), completes);
    expect(p.paused, isTrue);
  });
}
