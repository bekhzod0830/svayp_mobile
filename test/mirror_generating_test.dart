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
import 'package:swipe/features/mirror/presentation/screens/mirror_generating_screen.dart';
import 'package:swipe/features/mirror/presentation/widgets/mirror_chrome.dart';
import 'package:swipe/features/mirror/presentation/widgets/mirror_fitting_stage.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Экран генерации: сцена у зеркала идёт за этапами работы, выбранные в
/// каталоге вещи стоят в зеркале сразу, отмена возвращает на шаг назад, а
/// честный отказ бэкенда показывается текстом.
Future<MirrorSessionController> _controller({
  required MirrorPath path,
  int elapsed = 0,
}) async {
  SharedPreferences.setMockInitialValues({'kiosk_demo_forced': true});
  final prefs = await SharedPreferences.getInstance();
  final api = KioskApi(prefs);
  return MirrorSessionController(
    api: api,
    demo: KioskDemoService(api, prefs),
    prefs: prefs,
    brand: lacosteBrand,
    analytics: (_, __) {},
  )
    ..path = path
    ..screen = MirrorScreen.generating
    ..elapsedSec = elapsed;
}

KioskCatalogItem _item(String id, String category) => KioskCatalogItem(
      id: id,
      title: id,
      category: category,
      price: 500000,
      currency: 'UZS',
      imageUrl: 'https://img.test/$id.jpg',
    );

final _catalog = [
  _item('t1', 'TOPWEAR'),
  _item('t2', 'TOPWEAR'),
  _item('b1', 'BOTTOMWEAR'),
  _item('s1', 'FOOTWEAR'),
];

Widget _harness(MirrorSessionController c) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: MirrorBrandScope(
            brand: lacosteBrand,
            child: Scaffold(body: MirrorGeneratingScreen(controller: c)),
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
  setUpAll(() async {
    await _loadFonts();
    MirrorFittingStage.debugImageBuilder =
        (_) => const ColoredBox(color: Color(0xFFDDDDDD));
  });
  tearDownAll(() => MirrorFittingStage.debugImageBuilder = null);

  testWidgets('этап скана: заголовок, статус этапа, слоты-заглушки',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller(path: MirrorPath.create, elapsed: 2);
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.text('Собираем образ'), findsOneWidget);
    expect(find.text('Разбираем черты лица'), findsOneWidget);
    expect(find.textContaining('%'), findsOneWidget);
    final stage =
        tester.widget<MirrorFittingStage>(find.byType(MirrorFittingStage));
    expect(stage.stage, 0);
    // Каталога нет — слоты подписаны категориями бренда.
    expect(find.text('ПОЛО И ВЕРХ'), findsOneWidget);
    expect(find.text('ОБУВЬ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('этап подбора: в слотах вещи зала вместо заглушек',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller(path: MirrorPath.create, elapsed: 13);
    c.seedCatalogForTest(_catalog);
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.text('Подбираем вещи из зала'), findsOneWidget);
    final stage =
        tester.widget<MirrorFittingStage>(find.byType(MirrorFittingStage));
    expect(stage.stage, 2);
    expect(stage.pool.length, _catalog.length);
    expect(find.text('ПОЛО И ВЕРХ'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('ветка «каталог»: выбранная вещь стоит в зеркале с чеком',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller(path: MirrorPath.catalog, elapsed: 2);
    c.seedCatalogForTest(_catalog);
    c.pickedProductIds.add('t1');
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    final stage =
        tester.widget<MirrorFittingStage>(find.byType(MirrorFittingStage));
    expect(stage.pinned.single.id, 't1');
    // Чек только у выбранной вещи — остальные слоты ещё заглушки.
    expect(find.byType(MirrorCheck), findsOneWidget);
    expect(find.text('ПОЛО И ВЕРХ'), findsNothing);
    expect(find.text('БРЮКИ И ШОРТЫ'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('«Отмена» возвращает к выбору стиля', (tester) async {
    _tabletSurface(tester);
    final c = await _controller(path: MirrorPath.create, elapsed: 8);
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    await tester.tap(find.text('Отмена'));
    await tester.pump();
    expect(c.screen, MirrorScreen.style);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });

  testWidgets('честный отказ «нет образа» показывается текстом, с Retry',
      (tester) async {
    _tabletSurface(tester);
    final c = await _controller(path: MirrorPath.create, elapsed: 9);
    c
      ..genFailed = true
      ..genReason = 'KIOSK_LOOK_UNAVAILABLE';
    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.byType(MirrorFittingStage), findsNothing);
    expect(find.text('Что-то пошло не так'), findsOneWidget);
    expect(
      find.text('Из того, что сейчас в наличии, полный образ не собрать'),
      findsOneWidget,
    );
    expect(find.text('ПОПРОБОВАТЬ СНОВА'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
