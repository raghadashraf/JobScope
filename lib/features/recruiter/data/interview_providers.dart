import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/firestore_helpers.dart';
import '../../../data/models/interview_model.dart';
import '../../auth/data/auth_providers.dart';

final _db = appFirestore;

final candidateInterviewsProvider =
    StreamProvider<List<InterviewModel>>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value([]);
  return _db
      .collection('interviews')
      .where('candidateId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(InterviewModel.fromDoc).toList());
});

final recruiterInterviewsProvider =
    StreamProvider<List<InterviewModel>>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value([]);
  return _db
      .collection('interviews')
      .where('recruiterId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(InterviewModel.fromDoc).toList());
});

final applicationInterviewProvider = StreamProvider.autoDispose
    .family<InterviewModel?, String>((ref, applicationId) {
  return _db
      .collection('interviews')
      .where('applicationId', isEqualTo: applicationId)
      .limit(1)
      .snapshots()
      .map((s) =>
          s.docs.isEmpty ? null : InterviewModel.fromDoc(s.docs.first));
});

class InterviewNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> propose(InterviewModel interview) async {
    state = const AsyncLoading();
    try {
      final docRef = _db.collection('interviews').doc();
      await docRef.set(interview.copyWith(id: docRef.id).toMap());
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> confirm(String interviewId, int slotIndex) async {
    state = const AsyncLoading();
    try {
      await _db.collection('interviews').doc(interviewId).update({
        'confirmedSlotIndex': slotIndex,
        'status': InterviewStatus.confirmed.name,
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> cancel(String interviewId) async {
    state = const AsyncLoading();
    try {
      await _db.collection('interviews').doc(interviewId).update(
          {'status': InterviewStatus.cancelled.name});
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final interviewNotifierProvider =
    AsyncNotifierProvider<InterviewNotifier, void>(InterviewNotifier.new);

// Pending interviews count (proposed, not yet confirmed) for the candidate
final pendingInterviewsCountProvider = Provider<int>((ref) {
  final interviews = ref.watch(candidateInterviewsProvider).value ?? [];
  return interviews
      .where((i) => i.status == InterviewStatus.proposed)
      .length;
});
