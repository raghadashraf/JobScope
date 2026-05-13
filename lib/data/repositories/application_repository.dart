import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';

class ApplicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _applications =>
      _firestore.collection('applications');

  // ─── Submit a new application ─────────────────────────────────────────────
  Future<ApplicationModel> apply({
    required String jobId,
    required String jobTitle,
    required String company,
    required String candidateId,
    required String candidateName,
    required String candidateEmail,
    String? candidatePhotoUrl,
    String? cvUrl,
  }) async {
    // Check for duplicate first
    final existing = await hasApplied(
        jobId: jobId, candidateId: candidateId);
    if (existing) {
      throw Exception('You have already applied to this job.');
    }

    final doc = _applications.doc();
    final application = ApplicationModel(
      id: doc.id,
      jobId: jobId,
      jobTitle: jobTitle,
      company: company,
      candidateId: candidateId,
      candidateName: candidateName,
      candidateEmail: candidateEmail,
      candidatePhotoUrl: candidatePhotoUrl,
      cvUrl: cvUrl,
      status: ApplicationStatus.pending,
      appliedAt: DateTime.now(),
    );

    await doc.set(application.toMap());
    return application;
  }

  // ─── Check if candidate already applied ───────────────────────────────────
  Future<bool> hasApplied({
    required String jobId,
    required String candidateId,
  }) async {
    final snap = await _applications
        .where('jobId', isEqualTo: jobId)
        .where('candidateId', isEqualTo: candidateId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ─── Stream: check applied status in real-time ────────────────────────────
  Stream<bool> hasAppliedStream({
    required String jobId,
    required String candidateId,
  }) {
    return _applications
        .where('jobId', isEqualTo: jobId)
        .where('candidateId', isEqualTo: candidateId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty);
  }

  // ─── Stream: all applications for a candidate ─────────────────────────────
  Stream<List<ApplicationModel>> candidateApplicationsStream(
      String candidateId) {
    return _applications
        .where('candidateId', isEqualTo: candidateId)
        .snapshots()
        .map((snap) {
          final apps = snap.docs.map(ApplicationModel.fromDoc).toList();
          apps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return apps;
        });
  }

  // ─── Stream: all applications for a job (recruiter) ──────────────────────
  Stream<List<ApplicationModel>> jobApplicationsStream(String jobId) {
    return _applications
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snap) {
          final apps = snap.docs.map(ApplicationModel.fromDoc).toList();
          apps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return apps;
        });
  }

  // ─── Update application status (recruiter action) ─────────────────────────
  Future<void> updateStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    await _applications.doc(applicationId).update({
      'status': status.name,
    });
  }

  // ─── Fetch single application ─────────────────────────────────────────────
  Future<ApplicationModel?> fetchApplication(String id) async {
    final doc = await _applications.doc(id).get();
    if (!doc.exists) return null;
    return ApplicationModel.fromDoc(doc);
  }

  // ─── Withdraw application ─────────────────────────────────────────────────
  Future<void> withdraw(String applicationId) async {
    await _applications.doc(applicationId).delete();
  }
}
