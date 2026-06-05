import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import 'auth_repository.dart';
import 'profile_photo_providers.dart';
import 'profile_photo_storage.dart';

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
    // Only react to sign-in / sign-out (uid change), not displayName/photoURL
    // updates — those were overwriting profile edits after save.
    final uid = ref.watch(
      firebaseUserProvider.select((async) => async.value?.uid),
    );

    if (uid == null) return null;

    // Wait for Firebase Auth session restore to finish (critical on Chrome reload).
    await ref.watch(firebaseUserProvider.future);

    final user = await ref.read(authRepositoryProvider).getCurrentUserData();
    if (user != null) {
      final persisted = await ProfilePhotoStorage.load(user.uid);
      if (persisted != null && persisted.isNotEmpty) {
        ref.read(profilePhotoLocalCacheProvider.notifier).cache(user.uid, persisted);
      } else {
        // One-time download from Storage → save locally for future reloads.
        ref.read(profilePhotoBytesProvider(user.uid).future).ignore();
      }
    }
    return user;
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
