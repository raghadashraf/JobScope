import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firestore database in project `flutter-ai-playground-2379c` (not `(default)`).
const String kFirestoreDatabaseId = 'jobscope';

/// Firestore write timeout — long enough for slow networks, short enough to fail visibly.
const Duration kFirestoreWriteTimeout = Duration(seconds: 30);

FirebaseFirestore? _appFirestore;

/// Single Firestore client for the JobScope named database.
FirebaseFirestore get appFirestore {
  _appFirestore ??= FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: kFirestoreDatabaseId,
  );
  return _appFirestore!;
}

/// Removes null fields so Firestore accepts the payload (null values can break web writes).
Map<String, dynamic> firestoreEncode(Map<String, dynamic> data) {
  return Map<String, dynamic>.fromEntries(
    data.entries.where((e) => e.value != null),
  );
}

/// Call once after [Firebase.initializeApp]. Disables web IndexedDB persistence,
/// which can cause hung writes on Chrome for some environments.
Future<void> configureFirestore() async {
  final firestore = appFirestore;
  if (kIsWeb) {
    firestore.settings = const Settings(persistenceEnabled: false);
  }
}

Future<T> firestoreWrite<T>(Future<T> future) {
  return future.timeout(
    kFirestoreWriteTimeout,
    onTimeout: () => throw TimeoutException(
      'Firestore request timed out after ${kFirestoreWriteTimeout.inSeconds}s. '
      'Deploy firestore.rules (firebase deploy --only firestore:rules) and check network.',
    ),
  );
}

String firestoreErrorMessage(Object error) {
  if (error is TimeoutException) {
    return error.message ??
        'Request timed out. Deploy Firestore rules and check your connection.';
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Permission denied. Sign in and deploy firestore.rules to your Firebase project.';
      case 'unavailable':
        return 'Firestore is unavailable. Check network or VPN.';
      case 'failed-precondition':
        return error.message ?? 'Missing Firestore index. Deploy firestore.indexes.json.';
      default:
        return error.message ?? error.code;
    }
  }
  final text = error.toString();
  if (text.contains('permission-denied')) {
    return 'Permission denied. Deploy firestore.rules to flutter-ai-playground-2379c.';
  }
  if (text.contains('TimeoutException')) {
    return 'Request timed out. Deploy Firestore rules and check your connection.';
  }
  return text.replaceFirst('Exception: ', '').replaceFirst('TimeoutException: ', '');
}
