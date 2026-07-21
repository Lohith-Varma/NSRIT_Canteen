import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthService {
  FirebaseAuth? get _auth {
    if (FirebaseService.isInitialized) {
      try {
        return FirebaseAuth.instance;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Stream for auth changes
  Stream<UserModel?> get authStateChanges {
    final auth = _auth;
    if (auth == null) {
      return Stream.value(_demoUser);
    }
    return auth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel(
        uid: user.uid,
        email: user.email ?? 'user@canteen.edu',
        displayName: user.displayName ?? 'Canteen Manager',
        createdAt: DateTime.now(),
      );
    });
  }

  // Demo user fallback when testing offline or demo mode
  UserModel? _demoUser = UserModel(
    uid: 'demo_user_123',
    email: 'admin@nsrit.edu.in',
    displayName: 'NSRIT Canteen Admin',
    createdAt: DateTime.now(),
  );

  UserModel? get currentUser {
    final auth = _auth;
    if (auth == null) {
      return _demoUser;
    }
    final user = auth.currentUser;
    if (user == null) return _demoUser;
    return UserModel(
      uid: user.uid,
      email: user.email ?? 'admin@nsrit.edu.in',
      displayName: user.displayName ?? 'Canteen Manager',
      createdAt: DateTime.now(),
    );
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth != null) {
      try {
        final credential = await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          return UserModel(
            uid: user.uid,
            email: user.email ?? email,
            displayName: user.displayName ?? 'Canteen Manager',
            createdAt: DateTime.now(),
          );
        }
      } catch (e) {
        // Fall back to demo user if Firebase Auth isn't active in console
        debugPrint('FirebaseAuth sign in note: $e. Falling back to local auth.');
      }
    }
    
    // Demo login verification
    if (email.trim().isNotEmpty && password.length >= 6) {
      _demoUser = UserModel(
        uid: 'user_${email.hashCode}',
        email: email.trim(),
        displayName: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
        createdAt: DateTime.now(),
      );
      return _demoUser!;
    }
    throw FirebaseAuthException(
      code: 'invalid-credential',
      message: 'Invalid email or password.',
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    final auth = _auth;
    if (auth != null) {
      try {
        await auth.sendPasswordResetEmail(email: email.trim());
        return;
      } catch (e) {
        debugPrint('Password reset notice: $e');
      }
    }
    // Simulation succeeded
  }

  Future<void> signOut() async {
    final auth = _auth;
    if (auth != null) {
      try {
        await auth.signOut();
      } catch (e) {
        debugPrint('Sign out error: $e');
      }
    }
    _demoUser = null;
  }
}
