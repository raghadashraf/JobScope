import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_model.dart';

// SharedPreferences key — stores the role string for the last signed-in UID.
const _kRoleKey = 'user_role';
const _kUidKey  = 'user_uid';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UserModel? _cachedUser;
  UserModel? get cachedUser => _cachedUser;
  void setCachedUser(UserModel user) => _cachedUser = user;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Persist role locally so login works even when Firestore is unreachable ──
  Future<void> _saveRoleLocally(String uid, UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUidKey, uid);
    await prefs.setString(_kRoleKey, role.name);
  }

  Future<UserRole?> _loadRoleLocally(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString(_kUidKey);
    if (savedUid != uid) return null;
    final roleStr = prefs.getString(_kRoleKey);
    if (roleStr == null) return null;
    return UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.candidate,
    );
  }

  // ── Sign up ────────────────────────────────────────────────────────────────
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cred = await _auth
        .createUserWithEmailAndPassword(email: email.trim(), password: password)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Sign up timed out. Check your connection.',
          ),
        );

    final user = UserModel(
      uid: cred.user!.uid,
      email: email.trim(),
      name: name.trim(),
      role: role,
      createdAt: DateTime.now(),
    );

    // 1. Cache in memory immediately (before any await).
    _cachedUser = user;

    // 2. Persist role to disk so it survives app restarts.
    await _saveRoleLocally(user.uid, role);

    // 3. Write to Firestore (source of truth for all devices).
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    await cred.user!.updateDisplayName(name);

    return user;
  }

  // ── Sign in ────────────────────────────────────────────────────────────────
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    // 1. Memory cache hit (same session as signup).
    if (_cachedUser != null && _cachedUser!.uid == uid) {
      return _cachedUser!;
    }

    // 2. Try Firestore (primary source of truth).
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!);
        _cachedUser = user;
        await _saveRoleLocally(uid, user.role);
        return user;
      }
    } catch (_) {
      // Firestore unreachable — fall through to local cache below.
    }

    // 3. Firestore failed or doc missing — try locally persisted role.
    final localRole = await _loadRoleLocally(uid);
    if (localRole != null) {
      final user = UserModel(
        uid: uid,
        email: cred.user!.email ?? email.trim(),
        name: cred.user!.displayName ?? email.split('@').first,
        role: localRole,
        createdAt: DateTime.now(),
      );
      _cachedUser = user;
      return user;
    }

    // 4. No data anywhere — sign out and surface a clear error.
    await _auth.signOut();
    throw FirebaseAuthException(
      code: 'network-request-failed',
      message:
          'Could not load your account. Check your connection and try again.',
    );
  }

  // ── Get current user (session restore on app start) ────────────────────────
  Future<UserModel?> getCurrentUserData() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    // Memory cache hit.
    if (_cachedUser != null && _cachedUser!.uid == firebaseUser.uid) {
      return _cachedUser;
    }

    // Try Firestore.
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists) {
        _cachedUser = UserModel.fromMap(doc.data()!);
        await _saveRoleLocally(firebaseUser.uid, _cachedUser!.role);
        return _cachedUser;
      }
    } catch (_) {
      // Firestore unreachable — fall through.
    }

    // Firestore unavailable — fall back to locally persisted role.
    final localRole = await _loadRoleLocally(firebaseUser.uid);
    if (localRole != null) {
      _cachedUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User',
        role: localRole,
        createdAt: DateTime.now(),
      );
      return _cachedUser;
    }

    return null;
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _cachedUser = null;
    // Keep the role in SharedPreferences — _loadRoleLocally already guards by
    // UID, so a different user will never pick up this entry, and it lets the
    // same user fall back to the local role if Firestore is slow on next login.
    await _auth.signOut();
  }

  // ── Password reset ─────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Profile photo ──────────────────────────────────────────────────────────
  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List imageBytes,
  }) async {
    final ref = _storage.ref().child('profile_photos').child('$uid.jpg');
    final task = await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  // ── Profile update ─────────────────────────────────────────────────────────
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
    if (photoUrl != null) await _auth.currentUser?.updatePhotoURL(photoUrl);
  }
}
