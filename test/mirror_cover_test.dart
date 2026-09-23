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
import 'package:swipe/features/mirror/presentation/widgets/mirror_cover_stage.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Постер Magic Mirror в оформлении Lacoste: сцена-примерочная с вещами зала
/// (или типографскими карточками без каталога), знак бренда и CTA, ведущая
/// сразу на камеру. Блока «Как это работает» и строки про удаление фото на
/// постере нет.
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
      // совпадал с раскладкой; выключаем только анимации: сцена тогда сразу
      // показывает собранный образ.
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
    MirrorCoverStage.debugImageBuilder =
        (_) => const ColoredBox(color: Color(0xFFDDDDDD));
  });

  tearDownAll(() => MirrorCoverStage.debugImageBuilder = null);

  testWidgets('без каталога — сцена с типографскими карточками и обе CTA',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller();
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.text('LACOSTE'), findsOneWidget);
    expect(find.byType(MirrorCoverStage), findsOneWidget);
    expect(find.text('ВОЛШЕБНОЕ ЗЕРКАЛО'), findsOneWidget);
    // Вместо фото — подписи категорий бренда.
    expect(find.text('Поло и верх'), findsOneWidget);
    expect(find.text('Брюки и шорты'), findsOneWidget);
    expect(find.text('СОЗДАТЬ МОЙ ОБРАЗ'), findsOneWidget);
    expect(find.text('Выбрать из коллекции'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('на постере нет «Как это работает» и строки про удаление фото',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller();
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.textContaining('КАК ЭТО РАБОТАЕТ'), findsNothing);
    expect(find.textContaining('15 минут'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('с каталогом зала — образ в зеркале с ярлыком и суммой',
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

    expect(find.byType(MirrorCoverStage), findsOneWidget);
    expect(find.text('ОБРАЗ МОМЕНТА'), findsOneWidget);
    expect(find.text('1 500 000 сум'), findsOneWidget);
    // Фото вместо типографских карточек.
    expect(find.text('Поло и верх'), findsNothing);
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

  testWidgets('с анимациями сцена проигрывает цикл и меняет образ',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller();
    c.seedCatalogForTest([
      _item('t1', 'TOPWEAR'),
      _item('t2', 'TOPWEAR'),
      _item('b1', 'BOTTOMWEAR'),
      _item('b2', 'BOTTOMWEAR'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: MirrorBrandScope(
          brand: lacosteBrand,
          child: Scaffold(
            body: MirrorCoverScreen(controller: c, onOpenSetup: () {}),
          ),
        ),
      ),
    );

    final first = tester
        .widget<MirrorCoverStage>(find.byType(MirrorCoverStage))
        .look;
    // Полный цикл — 6.8 с: после него на сцене следующий образ.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    final second = tester
        .widget<MirrorCoverStage>(find.byType(MirrorCoverStage))
        .look;

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(identical(first, second), isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
