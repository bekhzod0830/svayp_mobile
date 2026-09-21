import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/features/mirror/brand/lacoste_brand.dart';
import 'package:swipe/features/mirror/brand/mirror_brands.dart';
import 'package:swipe/features/mirror/data/kiosk_api.dart';
import 'package:swipe/features/mirror/data/kiosk_demo.dart';
import 'package:swipe/features/mirror/data/kiosk_models.dart';
import 'package:swipe/features/mirror/presentation/mirror_session_controller.dart';
import 'package:swipe/features/mirror/presentation/screens/mirror_cover_screen.dart';
import 'package:swipe/features/mirror/presentation/widgets/mirror_cover_look_card.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Постер Magic Mirror в оформлении Lacoste: знак бренда, живой образ из
/// каталога (или типографский герой без него) и CTA, ведущая сразу на камеру.
Future<MirrorSessionController> _controller() async {
  // Принудительное демо: касание CTA не должно ходить в сеть.
  SharedPreferences.setMockInitialValues({'kiosk_demo_forced': true});
  final prefs = await SharedPreferences.getInstance();
  final api = KioskApi(prefs);
  return MirrorSessionController(
    api: api,
    demo: KioskDemoService(api, prefs),
    prefs: prefs,
    brand: lacosteBrand,
    analytics: (_, __) {},
  );
}

Widget _harness(MirrorSessionController c) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      // Размер экрана — настоящий (из tester.view), чтобы масштаб киоска
      // совпадал с раскладкой; выключаем только анимации.
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: MirrorBrandScope(
            brand: lacosteBrand,
            child: Scaffold(
              body: MirrorCoverScreen(controller: c, onOpenSetup: () {}),
            ),
          ),
        ),
      ),
    );

KioskCatalogItem _item(String id, String category) => KioskCatalogItem(
      id: id,
      title: id,
      category: category,
      price: 500000,
      currency: 'UZS',
      imageUrl: 'https://img.test/$id.jpg',
    );

/// Размер портретного iPad, чтобы раскладка постера была настоящей.
void _tabletSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(820, 1180);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Настоящие шрифты бренда вместо тестового Ahem: у него каждый глиф —
/// квадрат шириной в кегль, и любой заголовок «разъезжается» на лишние строки.
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
  setUpAll(() async {
    await _loadFonts();
    MirrorCoverLookCard.debugImageBuilder =
        (_) => const ColoredBox(color: Color(0xFFDDDDDD));
  });

  tearDownAll(() => MirrorCoverLookCard.debugImageBuilder = null);

  testWidgets('без каталога — типографский герой, знак бренда и обе CTA',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller();
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.text('LACOSTE'), findsWidgets);
    expect(find.byType(MirrorCoverLookCard), findsNothing);
    expect(find.text('СОЗДАТЬ МОЙ ОБРАЗ'), findsOneWidget);
    expect(find.text('Выбрать из коллекции'), findsOneWidget);
    expect(find.text('Как это работает'.toUpperCase()), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('с каталогом зала — карточка образа с ценой и кикером',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller();
    c.seedCatalogForTest([
      _item('t1', 'TOPWEAR'),
      _item('b1', 'BOTTOMWEAR'),
      _item('s1', 'FOOTWEAR'),
    ]);
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.byType(MirrorCoverLookCard), findsOneWidget);
    expect(find.text('ОБРАЗ МОМЕНТА'), findsOneWidget);
    expect(find.text('1 500 000 сум'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('«Создать мой образ» ведёт сразу на камеру, без интро',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller();
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    await tester.tap(find.text('СОЗДАТЬ МОЙ ОБРАЗ'));
    await tester.pump();

    expect(c.screen, MirrorScreen.camera);
    expect(c.path, MirrorPath.create);
    expect(c.demoActive, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('переключатель языка меняет язык покупателя', (tester) async {
    _tabletSurface(tester);
    final c = await _controller();
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(c.shopperLang, 'ru');
    await tester.tap(find.text('OʻZ'));
    await tester.pump();
    expect(c.shopperLang, 'uz');

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
