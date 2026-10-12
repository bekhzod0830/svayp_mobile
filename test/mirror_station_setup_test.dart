import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/features/mirror/brand/mirror_brands.dart';
import 'package:swipe/features/mirror/brand/storexx_brand.dart';
import 'package:swipe/features/mirror/presentation/widgets/mirror_station_setup_screen.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Оверлей «станция не настроена»: оформление магазина без принятого ключа.
Widget _harness({required bool keyRejected, required VoidCallback onOpenSetup}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: MirrorBrandScope(
        brand: storexxBrand,
        child: Scaffold(
          body: MirrorStationSetupScreen(
            keyRejected: keyRejected,
            onOpenSetup: onOpenSetup,
          ),
        ),
      ),
    );

void main() {
  testWidgets('ключа нет — просим ввести ключ, кнопка открывает настройку',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      _harness(keyRejected: false, onOpenSetup: () => opened++),
    );
    await tester.pump();

    expect(find.text('Станция не настроена'), findsOneWidget);
    expect(
      find.text('Чтобы начать, введите ключ станции этого магазина'),
      findsOneWidget,
    );

    await tester.tap(find.textContaining('ВВЕСТИ КЛЮЧ', findRichText: true).first);
    await tester.pump();
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ключ не принят — говорим именно об этом', (tester) async {
    await tester.pumpWidget(_harness(keyRejected: true, onOpenSetup: () {}));
    await tester.pump();

    expect(find.textContaining('Ключ станции не принят'), findsOneWidget);
    expect(
      find.text('Чтобы начать, введите ключ станции этого магазина'),
      findsNothing,
    );
  });

  test('ключ станции требуют только оформления магазинов', () {
    expect(storexxBrand.requiresStationKey, isTrue);
    expect(storexxDarkBrand.requiresStationKey, isTrue);
    expect(kMirrorBrand.requiresStationKey, isFalse);
  });
}
