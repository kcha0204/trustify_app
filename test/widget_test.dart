// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:Trustify/main.dart';

void main() {
  testWidgets(
      'Trustify app launches with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TrustifyApp());

    // Verify that splash screen shows the Trustify text
    expect(find.text('Trustify'), findsOneWidget);

    // Verify that the subtitle is also present
    expect(find.text('Stay Safe, Stay Smart 🛡️'), findsOneWidget);

    // Wait for all animations and timers to complete
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Verify that we're now on the home screen with the gaming cards
    expect(find.text('🛡️ SCAN & PROTECT'), findsOneWidget);
    expect(find.text('📊 CYBER INTEL'), findsOneWidget);
  });
}
