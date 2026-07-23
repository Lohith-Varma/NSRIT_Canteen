import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:nsrit_canteen/screens/auth/splash_screen.dart';

void main() {
  testWidgets('Canteen App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(autoNavigate: false)),
    );

    // Verify splash screen text exists
    expect(find.text('NSRIT CANTEEN'), findsOneWidget);
  });
}
