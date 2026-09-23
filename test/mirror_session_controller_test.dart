import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/features/mirror/data/kiosk_api.dart';
import 'package:swipe/features/mirror/data/kiosk_demo.dart';
import 'package:swipe/features/mirror/data/kiosk_models.dart';
import 'package:swipe/features/mirror/presentation/mirror_session_controller.dart';

/// Бэкенд под контролем теста: каждый ответ приходит тогда, когда тест решит.
class _FakeApi extends KioskApi {
  _FakeApi(super.prefs);

  final createLookCalls = <Completer<KioskLook>>[];
  final finishCalls = <Completer<KioskFinish>>[];
  void Function(KioskLook)? onDone;

  @override
  Future<KioskSession> startSession(String lang, String path) async =>
      const KioskSession(sessionId: 's1', storeLabel: 'Test', catalogSize: 10);

  @override
  Future<KioskLook> createLook({
    required String sessionId,
    required String gender,
    required String bodyShape,
    List<String>? styles,
    List<String>? productIds,
  }) {
    final c = Completer<KioskLook>();
    createLookCalls.add(c);
    return c.future;
  }

  @override
  KioskLookWatch watchLook(
    String lookId, {
    void Function(KioskLook look)? onProgress,
    required void Function(KioskLook look) onDone,
  }) {
    this.onDone = onDone;
    return super.watchLook('never-polled', onDone: (_) {})..close();
  }

  @override
  Future<KioskFinish> finishSession(String sessionId) {
    final c = Completer<KioskFinish>();
    finishCalls.add(c);
    return c.future;
  }

  @override
  Future<void> resetSession(String sessionId) async {}
}

KioskLook _look(String id, KioskLookStatus status, {String? reason}) =>
    KioskLook(lookId: id, status: status, failureReason: reason);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeApi api;
  late MirrorSessionController c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    api = _FakeApi(prefs);
    c = MirrorSessionController(
      api: api,
      demo: KioskDemoService(api, prefs),
      prefs: prefs,
      logEvent: (name, {parameters}) async {},
    );
    await c.begin(MirrorPath.create);
    c.gender = 'FEMALE';
    c.bodyShape = 'HOURGLASS';
  });

  tearDown(() => c.dispose());

  test('сбой генерации на сервере — честная ошибка, а не демо с фото вместо образа', () async {
    unawaited(c.startGeneration());
    api.createLookCalls.single.complete(_look('l1', KioskLookStatus.pending));
    await Future<void>.delayed(Duration.zero);

    // ML прислал таймаут текстом — раньше это уводило в демо.
    api.onDone!(_look('l1', KioskLookStatus.failed, reason: 'TIMEOUT'));

    expect(c.demoActive, isFalse);
    expect(c.genFailed, isTrue);
    expect(c.genReason, 'TIMEOUT');
    expect(api.createLookCalls, hasLength(1)); // никакой повторной «демо-генерации»
  });

  test('ответ отменённой генерации не подменяет новую', () async {
    // Отмена → сразу новая генерация (другие стили), а ответ первой приходит позже.
    unawaited(c.startGeneration());
    c.cancelGeneration();
    unawaited(c.startGeneration());
    expect(c.screen, MirrorScreen.generating);

    api.createLookCalls[0].complete(_look('old', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);

    // Раньше экран был «generating» — и показывался образ со старыми стилями.
    expect(c.resultReady, isFalse);
    expect(c.look?.lookId, isNot('old'));

    api.createLookCalls[1].complete(_look('new', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);
    expect(c.look?.lookId, 'new');
  });

  test('после сброса код и QR прошлого покупателя не достаются следующему', () async {
    unawaited(c.startGeneration());
    api.createLookCalls.single.complete(_look('l1', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);
    c.revealResult();
    expect(api.finishCalls, hasLength(1));

    await c.hardReset('timeout');
    api.finishCalls.single.complete(const KioskFinish(code: 'LB-1234', shareUrl: 'https://x/k/LB-1234'));
    await Future<void>.delayed(Duration.zero);

    expect(c.sellerCode, isNull);
    expect(c.shareUrl, isNull);
  });

  test('после «Пересобрать» код и QR запрашиваются для нового образа', () async {
    unawaited(c.startGeneration());
    api.createLookCalls[0].complete(_look('l1', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);
    c.revealResult();
    api.finishCalls[0].complete(const KioskFinish(code: 'LB-1111', shareUrl: 'https://x/k/LB-1111'));
    await Future<void>.delayed(Duration.zero);

    c.regenerate();
    api.createLookCalls[1].complete(_look('l2', KioskLookStatus.completed));
    await Future<void>.delayed(Duration.zero);
    c.revealResult();

    // Раньше ensureShare видел старый shareUrl и выходил — QR вёл на первый образ.
    expect(api.finishCalls, hasLength(2));
  });
}
