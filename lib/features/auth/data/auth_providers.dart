import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import 'auth_repository.dart';

// ── Repository singleton ───────────────────────────────────────────────────────
final authRepositoryProvider =
    Provider<AuthRepository>((_) => AuthRepository());

// ── Raw Firebase auth stream ───────────────────────────────────────────────────
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

// ── Auth state notifier ────────────────────────────────────────────────────────
// Holds the resolved UserModel. Can be updated directly from the login/signup
// screens (via setUser) so the role is always correct before the router fires.
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // Re-run whenever the Firebase auth state changes.
    final firebaseUser = await ref.watch(firebaseUserProvider.future);

    if (firebaseUser == null) return null;

    final repo = ref.read(authRepositoryProvider);

    // If the cache already has this user (set by signIn/signUp before this
    // rebuild runs), return it immediately — no Firestore fetch needed.
    final cached = repo.cachedUser;
    if (cached != null && cached.uid == firebaseUser.uid) return cached;

    // Session restore path: fetch the user doc from Firestore.
    return repo.getCurrentUserData();
  }

  /// Call this immediately after signIn() or signUp() returns so the router
  /// sees the correct role before the Firebase stream has a chance to rebuild
  /// this notifier with potentially stale data.
  void setUser(UserModel user) {
    ref.read(authRepositoryProvider).setCachedUser(user);
    state = AsyncValue.data(user);
  }
}

final currentUserProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
