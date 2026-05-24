import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_collection_model.dart';

class CollectionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _ref(String uid) =>
      _db.collection('users').doc(uid).collection('collections');

  Stream<List<JobCollectionModel>> collectionsStream(String uid) {
    return _ref(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(JobCollectionModel.fromDoc).toList());
  }

  Future<JobCollectionModel> create(String uid, String name) async {
    final doc = _ref(uid).doc();
    final model = JobCollectionModel(
      id: doc.id,
      name: name.trim(),
      jobIds: const [],
      createdAt: DateTime.now(),
    );
    await doc.set(model.toMap());
    return model;
  }

  Future<void> rename(
      String uid, String collectionId, String newName) async {
    await _ref(uid).doc(collectionId).update({
      'name': newName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String uid, String collectionId) async {
    await _ref(uid).doc(collectionId).delete();
  }

  Future<void> addJob(
      String uid, String collectionId, String jobId) async {
    await _ref(uid).doc(collectionId).update({
      'jobIds': FieldValue.arrayUnion([jobId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeJob(
      String uid, String collectionId, String jobId) async {
    await _ref(uid).doc(collectionId).update({
      'jobIds': FieldValue.arrayRemove([jobId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
