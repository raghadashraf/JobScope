import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import 'auth_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────
final authRepositoryProvider =
    Provider<AuthRepository>((_) => AuthRepository());

// ── Raw Firebase auth stream ──────────────────────────────────────────────────
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

// ── Resolved UserModel (our custom model from Firestore) ──────────────────────
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final firebaseUser = await ref.watch(firebaseUserProvider.future);
  if (firebaseUser == null) return null;
  return ref.read(authRepositoryProvider).getCurrentUserData();
});
