import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'services/demo_seed_service.dart';
import 'services/firebase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/kitchen_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/auth/splash_screen.dart';

void main() {
  runZonedGuarded(
    () async {
      debugPrint('[startup] main() entered');
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('[startup] WidgetsFlutterBinding initialized');

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('[startup] FlutterError.onError: ${details.exception}');
        debugPrint('[startup] FlutterError stack:\n${details.stack}');
      };
      ErrorWidget.builder = (FlutterErrorDetails details) {
        debugPrint('[startup] ErrorWidget.builder: ${details.exception}');
        debugPrint('[startup] ErrorWidget stack:\n${details.stack}');
        return Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                details.exceptionAsString(),
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        );
      };
      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        debugPrint('[startup] PlatformDispatcher.onError: $error');
        debugPrint('[startup] PlatformDispatcher stack:\n$stack');
        return false;
      };

      debugPrint('[startup] FirebaseService.initialize() starting');
      await FirebaseService.initialize();
      debugPrint('[startup] FirebaseService.initialize() completed');

      debugPrint('[startup] runApp() starting');
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => InventoryProvider()),
            ChangeNotifierProvider(create: (_) => SupplierProvider()),
            ChangeNotifierProvider(create: (_) => PurchaseProvider()),
            ChangeNotifierProvider(create: (_) => KitchenProvider()),
            ChangeNotifierProvider(create: (_) => AdminProvider()),
          ],
          child: const CollegeCanteenApp(),
        ),
      );
      debugPrint('[startup] runApp() returned');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[startup] first frame callback reached');
        unawaited(
          DemoSeedService().seedIfEmpty().catchError((
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint('[startup] DemoSeedService failed: $error');
            debugPrint('[startup] DemoSeedService stack:\n$stackTrace');
          }),
        );
      });
    },
    (Object error, StackTrace stackTrace) {
      debugPrint('[startup] Zone error: $error');
      debugPrint('[startup] Zone stack:\n$stackTrace');
    },
  );
}

class CollegeCanteenApp extends StatelessWidget {
  const CollegeCanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[startup] CollegeCanteenApp.build() entered');
    final themeProvider = Provider.of<ThemeProvider>(context);
    debugPrint('[startup] MaterialApp building');

    return MaterialApp(
      title: 'College Canteen Inventory System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
