import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/firestore_helpers.dart';
import '../../../data/models/application_draft_model.dart';
import '../../auth/data/auth_providers.dart';

/// Legacy top-level doc id before subcollection migration.
String _legacyDraftDocId(String uid, String jobId) => '${uid}_$jobId';

DocumentReference<Map<String, dynamic>> _draftRef(String uid, String jobId) =>
    appFirestore
        .collection('users')
        .doc(uid)
        .collection('application_drafts')
        .doc(jobId);

Future<ApplicationDraftModel?> _readDraft(String uid, String jobId) async {
  final sub = await _draftRef(uid, jobId).get();
  if (sub.exists) {
    return ApplicationDraftModel.fromMap(sub.data()!);
  }

  final legacy = await appFirestore
      .collection('application_drafts')
      .doc(_legacyDraftDocId(uid, jobId))
      .get();
  if (legacy.exists) {
    return ApplicationDraftModel.fromMap(
        legacy.data() as Map<String, dynamic>);
  }
  return null;
}

final applicationDraftProvider =
    StreamProvider.autoDispose.family<ApplicationDraftModel?, String>((ref, jobId) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value(null);

  final uid = user.uid;
  final subStream = _draftRef(uid, jobId).snapshots();
  final legacyStream = appFirestore
      .collection('application_drafts')
      .doc(_legacyDraftDocId(uid, jobId))
      .snapshots();

  return Stream.multi((controller) {
    ApplicationDraftModel? subDraft;
    ApplicationDraftModel? legacyDraft;

    void emit() {
      controller.add(subDraft ?? legacyDraft);
    }

    final subSub = subStream.listen(
      (doc) {
        subDraft = doc.exists
            ? ApplicationDraftModel.fromMap(doc.data()!)
            : null;
        emit();
      },
      onError: (_) => emit(),
    );
    final legacySub = legacyStream.listen(
      (doc) {
        legacyDraft = doc.exists
            ? ApplicationDraftModel.fromMap(
                doc.data() as Map<String, dynamic>)
            : null;
        if (subDraft == null) emit();
      },
      onError: (_) => emit(),
    );

    controller.onCancel = () async {
      await subSub.cancel();
      await legacySub.cancel();
    };
  });
});

class ApplicationDraftNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> saveCvSelection({
    required String jobId,
    required String cvId,
    required String cvUrl,
    required String cvFileName,
  }) async {
    final user = ref.read(firebaseUserProvider).value;
    if (user == null) return;

    final existing =
        await _readDraft(user.uid, jobId) ??
            ApplicationDraftModel(jobId: jobId);

    final draft = existing.copyWith(
      cvId: cvId,
      cvUrl: cvUrl,
      cvFileName: cvFileName,
    );

    await _persist(user.uid, draft);
  }

  Future<void> saveCoverLetter({
    required String jobId,
    String? letterText,
    String? fileUrl,
    String? fileName,
    required String source,
  }) async {
    final user = ref.read(firebaseUserProvider).value;
    if (user == null) return;

    final existing =
        await _readDraft(user.uid, jobId) ??
            ApplicationDraftModel(jobId: jobId);

    final draft = existing.copyWith(
      coverLetterText: letterText,
      coverLetterFileUrl: fileUrl,
      coverLetterFileName: fileName,
      coverLetterSource: source,
    );

    await _persist(user.uid, draft);
  }

  Future<void> clearDraft(String jobId) async {
    final user = ref.read(firebaseUserProvider).value;
    if (user == null) return;

    try {
      await _draftRef(user.uid, jobId).delete();
    } catch (_) {}
    try {
      await appFirestore
          .collection('application_drafts')
          .doc(_legacyDraftDocId(user.uid, jobId))
          .delete();
    } catch (_) {}
  }

  Future<void> _persist(String uid, ApplicationDraftModel draft) async {
    state = const AsyncLoading();
    try {
      await firestoreWrite(
        _draftRef(uid, draft.jobId).set(
          firestoreEncode(draft.toMap()),
          SetOptions(merge: true),
        ),
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final applicationDraftNotifierProvider =
    NotifierProvider<ApplicationDraftNotifier, AsyncValue<void>>(
        ApplicationDraftNotifier.new);
