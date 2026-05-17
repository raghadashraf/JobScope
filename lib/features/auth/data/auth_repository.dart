import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cred = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Sign up timed out. Check your connection and try again.',
          ),
        );

    final user = UserModel(
      uid: cred.user!.uid,
      email: email.trim(),
      name: name.trim(),
      role: role,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    await cred.user!.updateDisplayName(name);
    return user;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists) return UserModel.fromMap(doc.data()!);

      // Firestore doc missing — create it from Auth data and return.
      final fallback = UserModel(
        uid: uid,
        email: cred.user!.email ?? email.trim(),
        name: cred.user!.displayName ?? email.split('@').first,
        role: UserRole.candidate,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(fallback.toMap());
      return fallback;
    } catch (_) {
      // Firestore unreachable — build a minimal user from Auth data so login
      // still succeeds; the full profile will load once connectivity returns.
      return UserModel(
        uid: uid,
        email: cred.user!.email ?? email.trim(),
        name: cred.user!.displayName ?? email.split('@').first,
        role: UserRole.candidate,
        createdAt: DateTime.now(),
      );
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists) return UserModel.fromMap(doc.data()!);

      // Firestore doc missing but user IS authenticated — create & return fallback.
      final fallback = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? user.email?.split('@').first ?? 'User',
        role: UserRole.candidate,
        createdAt: DateTime.now(),
      );
      _firestore.collection('users').doc(user.uid).set(fallback.toMap());
      return fallback;
    } catch (_) {
      // Firestore unreachable — return minimal user so the router doesn't
      // redirect an authenticated user back to onboarding.
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? user.email?.split('@').first ?? 'User',
        role: UserRole.candidate,
        createdAt: DateTime.now(),
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List imageBytes,
  }) async {
    final ref = _storage.ref().child('profile_photos').child('$uid.jpg');

    final uploadTask = await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String? phone,
    required String? photoUrl,
    String? bio,
    String? headline,
    String? location,
    String? linkedinUrl,
    String? website,
    String? company,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': bio,
      'headline': headline,
      'location': location,
      'linkedinUrl': linkedinUrl,
      'website': website,
      'company': company,
    });

    await _auth.currentUser?.updateDisplayName(name);
    if (photoUrl != null) {
      await _auth.currentUser?.updatePhotoURL(photoUrl);
    }
  }

  Future<void> signOut() => _auth.signOut();
}
