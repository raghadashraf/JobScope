import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/firestore_helpers.dart';
import '../../../data/models/user_model.dart';

// SharedPreferences key — stores the role string for the last signed-in UID.
const _kRoleKey = 'user_role';
const _kUidKey  = 'user_uid';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = appFirestore;
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

  // ── Retry helper — channel-error on Flutter Web means the Firebase Auth JS
  // SDK wasn't ready yet; a short delay and retry fixes it reliably.
  Future<UserCredential> _withAuthRetry(
      Future<UserCredential> Function() call) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        return await call();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'channel-error' && attempt < 2) {
          await Future.delayed(Duration(milliseconds: 600 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }
    throw FirebaseAuthException(
      code: 'channel-error',
      message: 'Connection error. Please try again.',
    );
  }

  // ── Sign up ────────────────────────────────────────────────────────────────
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cred = await _withAuthRetry(
      () => _auth
          .createUserWithEmailAndPassword(email: email.trim(), password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw FirebaseAuthException(
              code: 'network-request-failed',
              message: 'Sign up timed out. Check your connection.',
            ),
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

    // 2. Persist role locally — critical fallback if Firestore is unreachable.
    await _saveRoleLocally(user.uid, role);

    // 3. Write to Firestore and update display name. These are best-effort:
    //    if they fail (e.g. slow network), the local cache and SharedPreferences
    //    already have everything needed to navigate and function. A background
    //    sync or next sign-in will restore the Firestore doc via signIn().
    try {
      await firestoreWrite(
        _firestore
            .collection('users')
            .doc(user.uid)
            .set(firestoreEncode(user.toMap())),
      );
      await cred.user!.updateDisplayName(name);
    } catch (_) {
      // Non-fatal: auth account is created, local role is saved.
    }

    return user;
  }

  // ── Sign in ────────────────────────────────────────────────────────────────
  // [fallbackRole] is the role the user selected on the login screen. It is
  // used only when neither Firestore nor local storage has a record — which
  // happens on a fresh web session when Firestore is unreachable. Passing it
  // here means we never lock out a successfully-authenticated user.
  Future<UserModel> signIn({
    required String email,
    required String password,
    required UserRole fallbackRole,
  }) async {
    final cred = await _withAuthRetry(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
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
    final resolvedRole = localRole ?? fallbackRole;

    final user = UserModel(
      uid: uid,
      email: cred.user!.email ?? email.trim(),
      name: cred.user!.displayName ?? email.split('@').first,
      role: resolvedRole,
      createdAt: DateTime.now(),
    );
    _cachedUser = user;
    await _saveRoleLocally(uid, resolvedRole);
    // Backfill Firestore in the background so future logins have a doc.
    firestoreWrite(
      _firestore
          .collection('users')
          .doc(uid)
          .set(firestoreEncode(user.toMap())),
    ).ignore();
    return user;
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
    }).timeout(const Duration(seconds: 10));
    await _auth.currentUser
        ?.updateDisplayName(name)
        .timeout(const Duration(seconds: 10));
    if (photoUrl != null) {
      await _auth.currentUser
          ?.updatePhotoURL(photoUrl)
          .timeout(const Duration(seconds: 10));
    }
  }
}
