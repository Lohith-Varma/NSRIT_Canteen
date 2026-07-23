import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_constants.dart';
import '../models/app_settings_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<UserModel>> watchUsers() {
    return _db
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<UserModel>> getUsers() async {
    final snapshot = await _db
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> saveUser(UserModel user) async {
    if (user.uid.trim().isEmpty) {
      throw Exception('User id is required. Create accounts from Firebase Authentication first.');
    }
    final normalizedUser = user.copyWith(updatedAt: DateTime.now());
    await _db
        .collection(AppConstants.usersCollection)
        .doc(normalizedUser.uid)
        .set(normalizedUser.toMap(), SetOptions(merge: true));
  }

  Future<void> deactivateUser(String userId) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> resetPassword(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      throw Exception('Enter a valid email address.');
    }
    await _auth.sendPasswordResetEmail(email: trimmed);
  }

  Future<AppSettingsModel> getSettings() async {
    final doc = await _db.collection(AppConstants.settingsCollection).doc('app').get();
    if (doc.exists && doc.data() != null) {
      return AppSettingsModel.fromMap(doc.data()!);
    }
    final defaults = AppSettingsModel.defaults();
    await saveSettings(defaults);
    return defaults;
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    await _db
        .collection(AppConstants.settingsCollection)
        .doc('app')
        .set(settings.toMap(), SetOptions(merge: true));
  }

  Future<List<NotificationModel>> getNotifications() async {
    final snapshot = await _db
        .collection(AppConstants.notificationsCollection)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> upsertNotifications(List<NotificationModel> notifications) async {
    if (notifications.isEmpty) return;
    final batch = _db.batch();
    for (final notification in notifications.take(100)) {
      batch.set(
        _db.collection(AppConstants.notificationsCollection).doc(notification.id),
        notification.toMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> markNotificationRead(String id) async {
    await _db.collection(AppConstants.notificationsCollection).doc(id).update({
      'isRead': true,
    });
  }
}
