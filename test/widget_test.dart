import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SwipeApp());

    // Verify that the app runs without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
