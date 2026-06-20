import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bank/main.dart';

void main() {
  testWidgets('Smoke test basic layout', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Pasamos isFirebaseReady: false para el test básico
    await tester.pumpWidget(const MyApp(isFirebaseReady: false));

    // Verify that onboarding starts (Window 1)
    expect(find.text('Ventana 1'), findsOneWidget);
  });
}
