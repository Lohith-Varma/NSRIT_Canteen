import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nsrit_canteen/main.dart';
import 'package:nsrit_canteen/providers/auth_provider.dart';
import 'package:nsrit_canteen/providers/theme_provider.dart';
import 'package:nsrit_canteen/providers/inventory_provider.dart';
import 'package:nsrit_canteen/providers/supplier_provider.dart';
import 'package:nsrit_canteen/providers/purchase_provider.dart';

void main() {
  testWidgets('Canteen App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => InventoryProvider()),
          ChangeNotifierProvider(create: (_) => SupplierProvider()),
          ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ],
        child: const CollegeCanteenApp(),
      ),
    );

    // Verify splash screen text exists
    expect(find.text('NSRIT CANTEEN'), findsOneWidget);

    // Advance timer past splash screen delay
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
