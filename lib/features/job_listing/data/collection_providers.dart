import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/job_collection_model.dart';
import '../../../data/models/job_model.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../auth/data/auth_providers.dart';
import 'job_providers.dart';

// ─── Repository ───────────────────────────────────────────────────────────────
final collectionRepositoryProvider =
    Provider<CollectionRepository>((_) => CollectionRepository());

// ─── Live collections stream ──────────────────────────────────────────────────
final collectionsStreamProvider =
    StreamProvider<List<JobCollectionModel>>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref
      .read(collectionRepositoryProvider)
      .collectionsStream(user.uid);
});

// ─── Jobs inside a specific folder (re-runs when collection updates) ──────────
final folderJobsProvider = FutureProvider.autoDispose
    .family<List<JobModel>, String>((ref, collectionId) async {
  final collections = ref.watch(collectionsStreamProvider).value ?? [];
  final idx = collections.indexWhere((c) => c.id == collectionId);
  if (idx < 0) return [];
  final jobIds = collections[idx].jobIds;
  if (jobIds.isEmpty) return [];
  final results = await Future.wait(
    jobIds.map((id) => ref.read(jobRepositoryProvider).fetchJob(id)),
  );
  return results.whereType<JobModel>().toList();
});

// ─── Create / rename / delete notifier ───────────────────────────────────────
class CollectionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  CollectionRepository get _repo =>
      ref.read(collectionRepositoryProvider);

  String? get _uid => ref.read(firebaseUserProvider).value?.uid;

  Future<JobCollectionModel?> create(String name) async {
    final uid = _uid;
    if (uid == null || name.trim().isEmpty) return null;
    state = true;
    try {
      return await _repo.create(uid, name);
    } finally {
      state = false;
    }
  }

  Future<void> rename(String collectionId, String newName) async {
    final uid = _uid;
    if (uid == null || newName.trim().isEmpty) return;
    state = true;
    try {
      await _repo.rename(uid, collectionId, newName);
    } finally {
      state = false;
    }
  }

  Future<void> delete(String collectionId) async {
    final uid = _uid;
    if (uid == null) return;
    state = true;
    try {
      await _repo.delete(uid, collectionId);
    } finally {
      state = false;
    }
  }
}

final collectionNotifierProvider =
    NotifierProvider<CollectionNotifier, bool>(CollectionNotifier.new);
