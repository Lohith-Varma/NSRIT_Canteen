import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      debugPrint('[startup] FirebaseService.initialize() entered');
      if (Firebase.apps.isNotEmpty) {
        debugPrint('[startup] Firebase already initialized');
        _isInitialized = true;
        return;
      }
      debugPrint('[startup] Firebase.initializeApp() starting');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[startup] Firebase.initializeApp() completed');
      _isInitialized = true;
      if (kDebugMode) {
        print('Firebase successfully initialized!');
      }
    } catch (e, stackTrace) {
      debugPrint('[startup] Firebase initialization failed: $e');
      debugPrint('[startup] Firebase initialization stack:\n$stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }
}
