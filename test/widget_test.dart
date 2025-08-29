// اختبارات تطبيق MyBus
// MyBus Application Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mybus/main.dart';

void main() {
  testWidgets('MyBus app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for the app to load
    await tester.pumpAndSettle();

    // The app should start with some basic UI elements
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });
}
