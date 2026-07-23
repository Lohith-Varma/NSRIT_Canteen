import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _userFromFirebaseUser(user);
    });
  }

  Future<UserModel?> get currentUser async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _userFromFirebaseUser(user);
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Unable to load the signed-in user.',
        );
      }
      final profile = await _userFromFirebaseUser(user);
      if (!profile.isActive) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-disabled',
          message: 'This account has been deactivated.',
        );
      }
      return profile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String role = 'Cashier',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'operation-not-allowed',
          message: 'Unable to create this account.',
        );
      }
      final trimmedName = displayName.trim();
      if (trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
      }
      final model = UserModel(
        uid: user.uid,
        email: user.email ?? email.trim(),
        displayName: trimmedName.isEmpty ? null : trimmedName,
        role: role,
        createdAt: DateTime.now(),
      );
      await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(model.toMap(), SetOptions(merge: true));
      return model;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel> _userFromFirebaseUser(User user) async {
    final ref = _db.collection(AppConstants.usersCollection).doc(user.uid);
    final doc = await ref.get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }

    final model = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      role: 'Administrator',
      createdAt: DateTime.now(),
    );
    await ref.set(model.toMap(), SetOptions(merge: true));
    return model;
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return e.message ?? 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Use a stronger password.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
