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

  testWidgets('касание QR-карточки показывает подсказку про телефон',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller(withCode: true);
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.text('Заберите образ в телефон'), findsOneWidget);
    await tester.tap(find.text('Скачать фото'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Отсканируйте QR — фото сохранится в телефон'),
      findsOneWidget,
    );
    // Подсказка сама гаснет через 2.5 с.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Заберите образ в телефон'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
