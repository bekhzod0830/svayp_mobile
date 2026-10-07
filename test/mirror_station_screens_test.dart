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

      testWidgets('гардероб: «Продолжить» неактивна до выбора', (tester) async {
        final c = await _controller();
        c.gender = null;
        await pump(tester, _listening(c, () => MirrorGenderScreen(controller: c)));
        expect(find.text('Женский гардероб'), findsOneWidget);
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
        await tester.tap(find.text('5–8 из 8'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Преппи'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('бренд: «Любой бренд» и 12 брендов', (tester) async {
        final c = await _controller();
        await pump(tester, _listening(c, () => MirrorShopBrandScreen(controller: c)));
        await tester.tap(find.text('Любой бренд'));
        await tester.pump();
        expect(c.shopBrand, 'ANY');
        expect(tester.takeException(), isNull);
      });

      testWidgets('«Что изменить?»: вопрос про лицо, цвета, список стилей', (tester) async {
        final c = await _controller();
        c.styles.add('CASUAL');
        await pump(tester, _listening(c, () => MirrorRefineScreen(controller: c)));
        await tester.tap(find.text('Нет'));
        await tester.pump();
        expect(c.faceLiked, isFalse);

        await tester.tap(find.text('Поменять стиль'));
        await tester.pump();
        expect(find.text('Деловой'), findsOneWidget);

        await tester.tap(find.text('Другой цвет'));
        await tester.pump();
        expect(find.text('Какие цвета не показывать?'), findsOneWidget);
        expect(find.text('Тёмно-синие'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
