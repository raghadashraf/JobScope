import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/firestore_helpers.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (kIsWeb) return;
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() async {
    if (kIsWeb) return null;
    return _messaging.getToken();
  }

  static Future<void> saveTokenForUser(String uid, String token) async {
    await firestoreWrite(
      appFirestore.collection('users').doc(uid).set(
        {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      ),
    );
  }

  /// Requests permission, fetches token, and stores it on `users/{uid}`.
  static Future<void> syncTokenForUser(String uid) async {
    if (kIsWeb) return;
    try {
      final service = NotificationService();
      await service.initialize();
      final token = await service.getToken();
      if (token != null) {
        await saveTokenForUser(uid, token);
      }
    } catch (_) {
      // FCM is optional until Cloud Function push is deployed.
    }
  }
}
