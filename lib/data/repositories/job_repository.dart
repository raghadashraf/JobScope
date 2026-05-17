import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobPage {
  final List<JobModel> jobs;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const JobPage({
    required this.jobs,
    required this.lastDoc,
    required this.hasMore,
  });
}

class JobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _pageSize = 10;

  CollectionReference get _jobs => _firestore.collection('jobs');

  // ─── Real-time stream of all active jobs ───────────────────────────────────
  Stream<List<JobModel>> jobsStream() {
    return _jobs
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final jobs = snap.docs.map(JobModel.fromDoc).toList();
          jobs.sort((a, b) => b.postedAt.compareTo(a.postedAt));
          return jobs;
        });
  }

  // ─── Real-time stream of a specific recruiter's jobs ──────────────────────
  Stream<List<JobModel>> recruiterJobsStream(String recruiterId) {
    return _jobs
        .where('recruiterId', isEqualTo: recruiterId)
        .snapshots()
        .map((snap) {
          final jobs = snap.docs.map(JobModel.fromDoc).toList();
          jobs.sort((a, b) => b.postedAt.compareTo(a.postedAt));
          return jobs;
        });
  }

  // ─── Cursor-based paginated fetch ─────────────────────────────────────────
  Future<JobPage> fetchJobs({DocumentSnapshot? lastDoc}) async {
    Query query = _jobs
        .where('isActive', isEqualTo: true)
        .orderBy('postedAt', descending: true)
        .limit(_pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snap = await query.get();
    final jobs = snap.docs.map(JobModel.fromDoc).toList();

    return JobPage(
      jobs: jobs,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length == _pageSize,
    );
  }

  // ─── Fetch single job ──────────────────────────────────────────────────────
  Future<JobModel?> fetchJob(String id) async {
    final doc = await _jobs.doc(id).get();
    if (!doc.exists) return null;
    return JobModel.fromDoc(doc);
  }

  // ─── Real-time stream of a single job ─────────────────────────────────────
  Stream<JobModel?> jobStream(String id) {
    return _jobs.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return JobModel.fromDoc(doc);
    });
  }

  // ─── Search by title / company / location ────────────────────────────────
  Future<List<JobModel>> searchJobs(String query) async {
    final lower = query.toLowerCase();
    final snap = await _jobs.where('isActive', isEqualTo: true).get();

    final results = snap.docs
        .map(JobModel.fromDoc)
        .where((j) =>
            j.title.toLowerCase().contains(lower) ||
            j.company.toLowerCase().contains(lower) ||
            j.location.toLowerCase().contains(lower))
        .toList();
    results.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return results;
  }

  // ─── Filter jobs ──────────────────────────────────────────────────────────
  Future<List<JobModel>> filterJobs({
    List<String>? skills,
    String? location,
    double? minSalary,
    double? maxSalary,
  }) async {
    final snap = await _jobs.where('isActive', isEqualTo: true).get();

    final filtered = snap.docs.map(JobModel.fromDoc).where((job) {
      if (skills != null && skills.isNotEmpty) {
        final jobSkillsLower = job.skills.map((s) => s.toLowerCase()).toSet();
        if (!skills.any((s) => jobSkillsLower.contains(s.toLowerCase()))) {
          return false;
        }
      }
      if (location != null && location.isNotEmpty) {
        if (!job.location.toLowerCase().contains(location.toLowerCase())) {
          return false;
        }
      }
      if (minSalary != null && job.salaryMin != null) {
        if (job.salaryMin! < minSalary) return false;
      }
      if (maxSalary != null && job.salaryMax != null) {
        if (job.salaryMax! > maxSalary) return false;
      }
      return true;
    }).toList();
    filtered.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return filtered;
  }

  // ─── Recruiter: Create job ─────────────────────────────────────────────────
  Future<JobModel> createJob(JobModel job) async {
    final doc = await _jobs.add(job.toMap());
    await doc.update({'id': doc.id});
    return JobModel.fromMap({...job.toMap(), 'id': doc.id}, docId: doc.id);
  }

  // ─── Recruiter: Update job ─────────────────────────────────────────────────
  Future<void> updateJob(JobModel job) async {
    await _jobs.doc(job.id).update(job.toMap());
  }

  // ─── Recruiter: Deactivate job (soft delete) ──────────────────────────────
  Future<void> deactivateJob(String id) async {
    await _jobs.doc(id).update({'isActive': false});
  }

  // ─── Recruiter: Re-activate job ───────────────────────────────────────────
  Future<void> activateJob(String id) async {
    await _jobs.doc(id).update({'isActive': true});
  }

  // ─── Recruiter: Hard-delete job ───────────────────────────────────────────
  Future<void> deleteJob(String id) async {
    await _jobs.doc(id).delete();
  }

  // ─── Bookmarks ────────────────────────────────────────────────────────────
  Future<void> bookmarkJob(String uid, String jobId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(jobId)
        .set({'jobId': jobId, 'savedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeBookmark(String uid, String jobId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(jobId)
        .delete();
  }

  Stream<Set<String>> bookmarkedJobIdsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Future<List<JobModel>> fetchBookmarkedJobs(String uid) async {
    final bookmarkSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .get();

    final ids = bookmarkSnap.docs.map((d) => d.id).toList();
    if (ids.isEmpty) return [];

    final results = await Future.wait(ids.map(fetchJob));
    return results.whereType<JobModel>().toList();
  }
}
