import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/firestore_helpers.dart';
import '../models/application_model.dart';
import 'notification_repository.dart';
import 'user_stats_repository.dart';

class ApplicationRepository {
  final FirebaseFirestore _firestore = appFirestore;
  final NotificationRepository _notifications = NotificationRepository();
  final UserStatsRepository _userStats = UserStatsRepository();

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
    String? cvId,
    String? cvFileName,
    String? coverLetterText,
    String? coverLetterFileUrl,
    String? coverLetterFileName,
    String? coverLetterSource,
    int? matchScore,
  }) async {
    final existing = await hasApplied(jobId: jobId, candidateId: candidateId);
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
      cvId: cvId,
      cvFileName: cvFileName,
      coverLetterText: coverLetterText,
      coverLetterFileUrl: coverLetterFileUrl,
      coverLetterFileName: coverLetterFileName,
      coverLetterSource: coverLetterSource,
      status: ApplicationStatus.pending,
      appliedAt: DateTime.now(),
      matchScore: matchScore,
    );

    await firestoreWrite(
      doc.set(firestoreEncode(application.toMap())),
    );
    try {
      await _userStats.refreshApplicationStats(candidateId);
    } catch (_) {}
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
    if (snap.docs.isEmpty) return false;
    return ApplicationModel.fromDoc(snap.docs.first).isActive;
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
        .map((snap) {
          if (snap.docs.isEmpty) return false;
          return ApplicationModel.fromDoc(snap.docs.first).isActive;
        });
  }

  // ─── Stream: single application (live updates for detail + timeline) ───────
  Stream<ApplicationModel?> applicationStream(String applicationId) {
    return _applications.doc(applicationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ApplicationModel.fromDoc(doc);
    });
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

  // ─── Stream: all applications for a job (recruiter view) ─────────────────
  Stream<List<ApplicationModel>> jobApplicationsStream(String jobId) {
    return _applications
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snap) {
          final apps = snap.docs
              .map(ApplicationModel.fromDoc)
              .where((a) => a.isActive)
              .toList();
          apps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return apps;
        });
  }

  // ─── Stream: live application count for a job ─────────────────────────────
  Stream<int> applicationsCountStream(String jobId) {
    return _applications
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snap) => snap.docs
            .map(ApplicationModel.fromDoc)
            .where((a) => a.isActive)
            .length);
  }

  // ─── Update application status (recruiter action) ─────────────────────────
  Future<void> updateStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    final snap = await _applications.doc(applicationId).get();
    if (!snap.exists) return;
    final application = ApplicationModel.fromDoc(snap);

    await firestoreWrite(_applications.doc(applicationId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }));

    try {
      await _notifications.notifyCandidateStatusChange(
        application: application,
        newStatus: status,
      );
    } catch (_) {}

    try {
      await _userStats.refreshApplicationStats(application.candidateId);
    } catch (_) {}
  }

  // ─── Update recruiter notes on an application ─────────────────────────────
  Future<void> updateNotes({
    required String applicationId,
    required String notes,
  }) async {
    await firestoreWrite(_applications.doc(applicationId).update({
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }));
  }

  // ─── Fetch single application ─────────────────────────────────────────────
  Future<ApplicationModel?> fetchApplication(String id) async {
    final doc = await _applications.doc(id).get();
    if (!doc.exists) return null;
    return ApplicationModel.fromDoc(doc);
  }

  // ─── Withdraw application (pending only; soft — keeps history) ───────────
  Future<void> withdraw({
    required String applicationId,
    required String candidateId,
  }) async {
    final snap = await _applications.doc(applicationId).get();
    if (!snap.exists) {
      throw Exception('Application not found.');
    }
    final app = ApplicationModel.fromDoc(snap);
    if (app.candidateId != candidateId) {
      throw Exception('You can only withdraw your own applications.');
    }
    if (!app.canWithdraw) {
      throw Exception(
        'Only applications under review can be withdrawn. '
        'Shortlisted or decided applications cannot be withdrawn.',
      );
    }

    await firestoreWrite(_applications.doc(applicationId).update({
      'status': ApplicationStatus.withdrawn.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }));

    try {
      await _userStats.refreshApplicationStats(candidateId);
    } catch (_) {}
  }
}
