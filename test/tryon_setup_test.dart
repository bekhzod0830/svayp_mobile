import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/features/tryon/presentation/tryon_sheet.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/l10n/app_localizations_en.dart';
import 'package:swipe/shared/widgets/body_scan_visual.dart';

const _preview = 'https://example.com/product.png';

Future<void> _openSheet(WidgetTester tester, {String? previewImage}) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const Scaffold(body: SizedBox.expand()),
  ));
  showProductTryOnSheet(
    tester.element(find.byType(Scaffold)),
    productId: 'p1',
    previewImage: previewImage,
  );
  await tester.pumpAndSettle();
}

void main() {
  final en = AppLocalizationsEn();

  testWidgets('setup shows the garment, not the animated silhouette',
      (tester) async {
    await _openSheet(tester, previewImage: _preview);

    // The body-scan silhouette is gone from try-on entirely.
    expect(find.byType(BodyScanVisual), findsNothing);

    // In its place: the product being tried on.
    final images = tester
        .widgetList<Image>(find.byType(Image))
        .where((i) => i.image is NetworkImage)
        .toList();
    expect(images, isNotEmpty, reason: 'preview image should be shown');
    expect((images.first.image as NetworkImage).url, _preview);
  });

  testWidgets('no preview image means no empty stage', (tester) async {
    await _openSheet(tester);

    expect(find.byType(BodyScanVisual), findsNothing);
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .where((i) => i.image is NetworkImage),
      isEmpty,
      reason: 'nothing to preview — the card should be omitted, not blank',
    );
    // The rest of the sheet still works.
    expect(find.text(en.tryOnTargetSelf), findsOneWidget);
  });

  testWidgets('target is a segmented control with both options',
      (tester) async {
    await _openSheet(tester, previewImage: _preview);

    expect(find.text(en.tryOnTargetMannequin), findsOneWidget);
    expect(find.text(en.tryOnTargetSelf), findsOneWidget);
  });

  testWidgets('photo row carries the guidance and no worked example',
      (tester) async {
    await _openSheet(tester, previewImage: _preview);

    // "On my photo" is the default target, so the row is visible immediately.
    expect(find.text(en.tryOnUploadPhoto), findsOneWidget);
    expect(find.text(en.tryOnPhotoHint), findsOneWidget);

    // Exactly one local image slot (the empty picker draws an icon, not an
    // Image) — i.e. no sample photo beside it.
    final assetImages = tester
        .widgetList<Image>(find.byType(Image))
        .where((i) => i.image is AssetImage || i.image is FileImage);
    expect(assetImages, isEmpty);
  });

  testWidgets('switching to the mannequin hides the photo row',
      (tester) async {
    await _openSheet(tester, previewImage: _preview);
    expect(find.text(en.tryOnUploadPhoto), findsOneWidget);

    await tester.tap(find.text(en.tryOnTargetMannequin));
    await tester.pumpAndSettle();

    expect(find.text(en.tryOnUploadPhoto), findsNothing);
    expect(find.text(en.tryOnPhotoHint), findsNothing);
  });

  testWidgets('start is enabled for a mannequin run and blocked until a photo '
      'is uploaded for a self run', (tester) async {
    await _openSheet(tester, previewImage: _preview);

    ElevatedButton startButton() => tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text(en.tryOnConfirm),
            matching: find.byType(ElevatedButton),
          ),
        );

    // Default is "on my photo" with nothing picked yet.
    expect(startButton().onPressed, isNull);

    await tester.tap(find.text(en.tryOnTargetMannequin));
    await tester.pumpAndSettle();
    expect(startButton().onPressed, isNotNull);
  });
}
