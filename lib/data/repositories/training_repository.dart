import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/firestore_helpers.dart';
import '../models/training_session_model.dart';

class TrainingRepository {
  final FirebaseFirestore _firestore = appFirestore;

  CollectionReference _sessions(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('training_sessions');

  Future<TrainingSessionModel> createSession(TrainingSessionModel session) async {
    final ref = session.id.isEmpty
        ? _sessions(session.uid).doc()
        : _sessions(session.uid).doc(session.id);
    final data = {...session.toMap(), 'id': ref.id};
    await ref.set(data).timeout(const Duration(seconds: 10));
    return TrainingSessionModel.fromMap(data, docId: ref.id);
  }

  Future<void> updateSession(TrainingSessionModel session) async {
    await _sessions(session.uid)
        .doc(session.id)
        .set(session.toMap(), SetOptions(merge: true))
        .timeout(const Duration(seconds: 10));
  }

  /// Latest completed session for a job (for apply gate).
  Stream<TrainingSessionModel?> latestCompletedForJob({
    required String uid,
    required String jobId,
  }) {
    return _sessions(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          for (final doc in snap.docs) {
            final s = TrainingSessionModel.fromDoc(doc);
            if (s.jobId == jobId && s.isComplete) return s;
          }
          return null;
        });
  }
}
