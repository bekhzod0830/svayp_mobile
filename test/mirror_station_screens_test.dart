import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/features/mirror/brand/libas_brand.dart';
import 'package:swipe/features/mirror/brand/mirror_brands.dart';
import 'package:swipe/features/mirror/data/kiosk_api.dart';
import 'package:swipe/features/mirror/data/kiosk_demo.dart';
import 'package:swipe/features/mirror/data/kiosk_models.dart';
import 'package:swipe/features/mirror/presentation/mirror_session_controller.dart';
import 'package:swipe/features/mirror/presentation/screens/mirror_body_screens.dart';
import 'package:swipe/features/mirror/presentation/screens/mirror_colors_screen.dart';
import 'package:swipe/features/mirror/presentation/screens/mirror_refine_screen.dart';
import 'package:swipe/features/mirror/presentation/screens/mirror_shop_brand_screen.dart';
import 'package:swipe/features/mirror/presentation/screens/mirror_style_screen.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Шаги станции LIBAS (гардероб, фигура, стиль, бренд, «Что изменить?») на
/// вертикальном экране станции и на планшете: без переполнений и с рабочими кнопками.
Future<MirrorSessionController> _controller() async {
  SharedPreferences.setMockInitialValues({'kiosk_demo_forced': true});
  final prefs = await SharedPreferences.getInstance();
  final api = KioskApi(prefs);
  return MirrorSessionController(
    api: api,
    demo: KioskDemoService(api, prefs),
    prefs: prefs,
    brand: libasBrand,
    analytics: (_, __) {},
  )
    ..path = MirrorPath.create
    ..gender = 'MALE'
    ..look = const KioskLook(lookId: 'l1', status: KioskLookStatus.completed);
}

/// Экран перерисовывается по изменениям контроллера — как в приложении (там слушает
/// родитель).
Widget _listening(MirrorSessionController c, Widget Function() build) =>
    ListenableBuilder(listenable: c, builder: (_, __) => build());

Widget _harness(Widget screen) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: MirrorBrandScope(brand: libasBrand, child: Scaffold(body: screen)),
        ),
      ),
    );

const _surfaces = {
  'станция 1080×1920': Size(1080, 1920),
  'планшет 820×1180': Size(820, 1180),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in _surfaces.entries) {
    group(entry.key, () {
      setUp(() {});

      Future<void> pump(WidgetTester tester, Widget screen) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_harness(screen));
        await tester.pump(const Duration(seconds: 1));
      }

      testWidgets('пол: касание карточки сразу ведёт к фигуре', (tester) async {
        final c = await _controller();
        c.gender = null;
        await pump(tester, _listening(c, () => MirrorGenderScreen(controller: c)));
        expect(find.text('Продолжить'), findsNothing);
        await tester.tap(find.text('Для женщин'));
        expect(c.gender, 'FEMALE');
        expect(c.screen, MirrorScreen.shape);
        expect(tester.takeException(), isNull);
      });

      testWidgets('фигура: четыре силуэта и «Не знаю свой тип фигуры»', (tester) async {
        final c = await _controller();
        await pump(tester, _listening(c, () => MirrorShapeScreen(controller: c)));
        expect(find.text('Овал'), findsOneWidget);
        await tester.tap(find.text('Не знаю свой тип фигуры'));
        expect(c.bodyShape, 'UNKNOWN');
        expect(tester.takeException(), isNull);
      });

      testWidgets('стиль: две страницы по четыре, выбор виден в счётчике', (tester) async {
        final c = await _controller();
        await pump(tester, _listening(c, () => MirrorStyleScreen(controller: c)));
        await tester.tap(find.text('Кэжуал'));
        await tester.pump();
        expect(find.text('Выбрано: 1'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('Следующие стили'));
        await tester.pumpAndSettle();
        expect(find.text('Преппи'), findsOneWidget);
        expect(find.text('Выбрано: 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('бренд: «Все бренды» и 12 брендов', (tester) async {
        final c = await _controller();
        await pump(tester, _listening(c, () => MirrorShopBrandScreen(controller: c)));
        await tester.tap(find.text('Все бренды'));
        await tester.pump();
        expect(c.shopBrands, {'ANY'});
        expect(tester.takeException(), isNull);
      });

      testWidgets('цвета: отмеченные исключаются', (tester) async {
        final c = await _controller();
        await pump(tester, _listening(c, () => MirrorColorsScreen(controller: c)));
        expect(find.text('Ничего не исключено — покажем все цвета'), findsOneWidget);
        await tester.tap(find.text('Красные'));
        await tester.pump();
        expect(c.avoidColors, ['red']);
        expect(find.text('Исключено цветов: 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('«Что изменить?»: несколько причин, раскрытые выборы, одна кнопка', (tester) async {
        final c = await _controller();
        c.styles.add('CASUAL');
        await pump(tester, _listening(c, () => MirrorRefineScreen(controller: c)));
        await tester.tap(find.text('Нет'));
        await tester.pump();
        expect(c.faceLiked, isFalse);
        expect(find.text('Просто пересобрать'), findsOneWidget);

        // Дешевле и дороже — одно из двух.
        await tester.tap(find.bySemanticsLabel('Дешевле'));
        await tester.tap(find.bySemanticsLabel('Дороже'));
        await tester.pump();

        await tester.tap(find.bySemanticsLabel('Поменять стиль'));
        await tester.pumpAndSettle();
        expect(find.text('Выберите стиль ниже'), findsOneWidget);
        await tester.ensureVisible(find.text('Деловой'));
        await tester.tap(find.text('Деловой'));
        await tester.pump();
        expect(find.text('Выберите стиль ниже'), findsNothing);

        await tester.tap(find.bySemanticsLabel('Другой цвет'));
        await tester.pumpAndSettle();
        expect(find.text('Какие цвета убрать?'), findsOneWidget);
        // Раскрыт один выбор: стили свернулись, отметка стиля осталась.
        expect(find.text('Какой стиль попробовать?'), findsNothing);
        expect(find.text('Выбрано: 3'), findsOneWidget);

        // Повторное касание отмеченной плитки раскрывает её выбор снова.
        await tester.tap(find.bySemanticsLabel('Поменять стиль'));
        await tester.pumpAndSettle();
        expect(find.text('Какой стиль попробовать?'), findsOneWidget);
        expect(find.text('Какие цвета убрать?'), findsNothing);
        expect(find.text('Выбрано: 3'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
