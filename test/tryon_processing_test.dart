import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/features/tryon/presentation/tryon_sheet.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// A 1x1 PNG on disk — enough for Image.file to lay out without network.
File _tempPng() {
  final f = File('${Directory.systemTemp.path}/tryon_test_photo.png');
  f.writeAsBytesSync(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);
  return f;
}

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('processing view shows the user photo under a scan beam',
      (tester) async {
    final photo = _tempPng();

    await tester.pumpWidget(_host(TryOnProcessingView(ink: Colors.black, sub: Colors.grey, subject: FileImage(photo))));
    await tester.pump();

    // The photo itself is on stage — this is the whole point of the change.
    final img = tester.widget<Image>(
      find.descendant(
        of: find.byType(TryOnProcessingView),
        matching: find.byType(Image),
      ).first,
    );
    expect(img.image, isA<FileImage>());

    // Phase label starts at "Starting try-on..." and the estimate is shown.
    expect(find.text('Starting try-on...'), findsOneWidget);
    expect(find.text('Usually takes 30–60 seconds'), findsOneWidget);

    // A tip card is present with one of the pink eyebrow headers.
    expect(
      find.byWidgetPredicate((w) =>
          w is Text && (w.data ?? '').startsWith('✦ ')),
      findsOneWidget,
    );
  });

  testWidgets('scan beam stays within the photo card', (tester) async {
    final photo = _tempPng();
    await tester.pumpWidget(_host(TryOnProcessingView(ink: Colors.black, sub: Colors.grey, subject: FileImage(photo))));
    await tester.pump();

    final cardFinder = find.byKey(const ValueKey('tryon-scan-card'));
    expect(cardFinder, findsOneWidget);
    final card = tester.getRect(cardFinder);

    // Card keeps the 3:4 portrait ratio the closet uses.
    expect(card.width / card.height, closeTo(3 / 4, 0.02));

    // Sample one sweep (the controller's period is 2800ms, so seven 400ms
    // steps stay inside a single pass).
    final tops = <double>[];
    for (var i = 0; i < 7; i++) {
      final beam = find.byKey(const ValueKey('tryon-scan-beam'));
      expect(beam, findsOneWidget, reason: 'beam missing at step $i');
      final r = tester.getRect(beam);

      // Band is 24% of the card, as on the web.
      expect(r.height, closeTo(card.height * 0.24, 1.0));
      // Never more than one card-height past either edge. This is the bug the
      // explicit pixel geometry fixes: a FractionalTranslation is relative to
      // the moving child's own height, so the sweep overshot by ~5x and the
      // beam spent nearly the whole loop outside the (clipped) card.
      expect(r.top, greaterThan(card.top - card.height), reason: 'step $i');
      expect(r.bottom, lessThan(card.bottom + card.height), reason: 'step $i');

      tops.add(r.top);
      await tester.pump(const Duration(milliseconds: 400));
    }

    // Guard against the assertions above passing on a beam that never moves.
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]),
          reason: 'beam should sweep downward; tops=$tops');
    }
    // And it really does traverse the card, rather than inching along.
    expect(tops.last - tops.first, greaterThan(card.height * 0.5));
  });
}
