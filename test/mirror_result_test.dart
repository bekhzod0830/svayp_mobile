import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/features/mirror/brand/lacoste_brand.dart';
import 'package:swipe/features/mirror/brand/mirror_brands.dart';
import 'package:swipe/features/mirror/data/kiosk_api.dart';
import 'package:swipe/features/mirror/data/kiosk_demo.dart';
import 'package:swipe/features/mirror/data/kiosk_models.dart';
import 'package:swipe/features/mirror/presentation/mirror_session_controller.dart';
import 'package:swipe/features/mirror/presentation/screens/mirror_result_screen.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Экран результата: полноэкранный образ, панель с суммой и вещами, QR и два
/// действия. «Отложить» доступно только когда код продавца уже получен.
Future<MirrorSessionController> _controller({required bool withCode}) async {
  SharedPreferences.setMockInitialValues({'kiosk_demo_forced': true});
  final prefs = await SharedPreferences.getInstance();
  final api = KioskApi(prefs);
  final c = MirrorSessionController(
    api: api,
    demo: KioskDemoService(api, prefs),
    prefs: prefs,
    brand: lacosteBrand,
    analytics: (_, __) {},
  );
  c
    ..path = MirrorPath.create
    ..screen = MirrorScreen.result
    ..look = const KioskLook(
      lookId: 'l1',
      status: KioskLookStatus.completed,
      items: [
        KioskLookItem(productId: 'p1', title: 'Поло L.12.12', size: 'M', price: 1290000),
        KioskLookItem(productId: 'p3', title: 'Чиносы slim fit', size: '32', price: 1590000),
      ],
      totalPrice: 2880000,
      currency: 'UZS',
    );
  if (withCode) {
    c
      ..sellerCode = 'LB-4821'
      ..shareUrl = 'https://web.svaypai.com/k/LB-4821';
  }
  return c;
}

/// Как в MirrorTab: экран перестраивается на каждое изменение контроллера.
Widget _liveHarness(MirrorSessionController c) =>
    ListenableBuilder(listenable: c, builder: (context, _) => _harness(c));

Widget _harness(MirrorSessionController c) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: MirrorBrandScope(
            brand: lacosteBrand,
            child: Scaffold(body: MirrorResultScreen(controller: c)),
          ),
        ),
      ),
    );

void _tabletSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(820, 1180);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _loadFonts() async {
  final golos = FontLoader('GolosText')
    ..addFont(rootBundle.load('assets/fonts/GolosText-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/GolosText-Bold.ttf'));
  final playfair = FontLoader('PlayfairDisplay')
    ..addFont(rootBundle.load('assets/fonts/PlayfairDisplay-Variable.ttf'));
  await golos.load();
  await playfair.load();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('панель: заголовок, сумма, вещи, QR и оба действия',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller(withCode: true);
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.text('Ваш образ'), findsOneWidget);
    expect(find.text('2 880 000 сум'), findsOneWidget);
    expect(find.text('Поло L.12.12'), findsOneWidget);
    expect(find.text('Чиносы slim fit'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('ОТЛОЖИТЬ НА ПРИМЕРКУ'), findsOneWidget);
    expect(find.textContaining('ПЕРЕСОБРАТЬ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('«Отложить на примерку» открывает состав образа',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller(withCode: true);
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    await tester.tap(find.text('ОТЛОЖИТЬ НА ПРИМЕРКУ'));
    await tester.pump();
    expect(c.screen, MirrorScreen.buy);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('пока кода продавца нет — «Отложить» не срабатывает, QR ждёт',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller(withCode: false);
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.byType(QrImageView), findsNothing);
    await tester.tap(find.text('ОТЛОЖИТЬ НА ПРИМЕРКУ'));
    await tester.pump();
    expect(c.screen, MirrorScreen.result);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('касание QR открывает его крупно, касание в любом месте закрывает',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller(withCode: true);
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.byType(QrImageView), findsOneWidget);
    await tester.tap(find.text('Скачать фото'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Поверх экрана — второй, крупный QR с подсказкой.
    final qrs = find.byType(QrImageView);
    expect(qrs, findsNWidgets(2));
    final widths = [
      for (var i = 0; i < 2; i++) tester.getSize(qrs.at(i)).width,
    ];
    expect(widths.reduce((a, b) => a > b ? a : b), greaterThan(500));
    expect(
      find.text('Отсканируйте QR — фото сохранится в телефон'),
      findsOneWidget,
    );

    // Закрывает касание и в углу экрана, а не только по «Закрыть».
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(c.screen, MirrorScreen.result);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('«Пересобрать» без счётчика оставшихся попыток', (tester) async {
    _tabletSurface(tester);
    final c = await _controller(withCode: true);
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.text('ПЕРЕСОБРАТЬ'), findsOneWidget);
    expect(find.textContaining('ОСТАЛОСЬ'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  group('пачка образов', () {
    KioskLook look(String id, KioskLookStatus status, String title) => KioskLook(
          lookId: id,
          status: status,
          items: [KioskLookItem(productId: 'p-$id', title: title, price: 100000)],
          totalPrice: 100000,
          currency: 'UZS',
        );

    testWidgets('лента образов: соседний выглядывает, листание вбок выбирает образ',
        (tester) async {
      _tabletSurface(tester);
      final c = await _controller(withCode: true);
      c.seedPackForTest(
        [
          look('l1', KioskLookStatus.completed, 'Жакет'),
          look('l2', KioskLookStatus.completed, 'Свитер'),
          look('l3', KioskLookStatus.processing, 'Пальто'),
        ],
        current: 'l1',
      );
      await tester.pumpWidget(_liveHarness(c));
      await tester.pump();

      // Текущий образ по центру, следующий выглядывает справа.
      final screen = tester.getSize(find.byType(MirrorResultScreen)).width;
      final current = tester.getRect(find.byKey(const ValueKey('variant-l1')));
      final next = tester.getRect(find.byKey(const ValueKey('variant-l2')));
      expect(current.center.dx, closeTo(screen / 2, 1));
      expect(next.left, greaterThan(current.right));
      expect(next.left, lessThan(screen)); // край следующего виден
      // Точки: три образа, третий ещё рисуется.
      expect(find.byKey(const ValueKey('variant-dot-l1')), findsOneWidget);
      expect(find.byKey(const ValueKey('variant-dot-l3')), findsOneWidget);
      expect(find.text('Жакет'), findsOneWidget);

      // Листаем влево — выбран второй образ, вещи и сумма его.
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(c.look?.lookId, 'l2');
      expect(find.text('Свитер'), findsOneWidget);
      expect(find.text('Жакет'), findsNothing);

      // Третий ещё в работе: его видно (заглушка с индикатором), но выбран
      // по-прежнему второй.
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('variant-l3')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(c.look?.lookId, 'l2');

      // Дорисовался, пока человек на нём стоит, — выбирается сам.
      c.seedPackForTest(
        [
          look('l1', KioskLookStatus.completed, 'Жакет'),
          look('l2', KioskLookStatus.completed, 'Свитер'),
          look('l3', KioskLookStatus.completed, 'Пальто'),
        ],
        current: 'l2',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.look?.lookId, 'l3');
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });

    testWidgets('касание по выглядывающему образу переходит к нему', (tester) async {
      _tabletSurface(tester);
      final c = await _controller(withCode: true);
      c.seedPackForTest(
        [
          look('l1', KioskLookStatus.completed, 'Жакет'),
          look('l2', KioskLookStatus.completed, 'Свитер'),
        ],
        current: 'l1',
      );
      await tester.pumpWidget(_liveHarness(c));
      await tester.pump();

      final peek = tester.getRect(find.byKey(const ValueKey('variant-l2')));
      // Нижняя часть выглядывающего образа: сверху его прикрывает карточка QR.
      await tester.tapAt(Offset(peek.left + 12, peek.bottom - 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.look?.lookId, 'l2');

      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });

    testWidgets('один образ — ленты нет', (tester) async {
      _tabletSurface(tester);
      final c = await _controller(withCode: true);
      c.seedPackForTest(
        [look('l1', KioskLookStatus.completed, 'Жакет')],
        current: 'l1',
      );
      await tester.pumpWidget(_liveHarness(c));
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(find.byKey(const ValueKey('variant-dot-l1')), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });
  });
}
