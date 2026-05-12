import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/job_model.dart';
import '../../applications/data/application_providers.dart';
import '../../auth/data/auth_providers.dart';

final recruiterJobsStreamProvider = StreamProvider<List<JobModel>>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('recruiterId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) {
        final jobs = snap.docs.map(JobModel.fromDoc).toList();
        jobs.sort((a, b) => b.postedAt.compareTo(a.postedAt));
        return jobs;
      });
});

final jobApplicationsStreamProvider =
    StreamProvider.family<List<ApplicationModel>, String>((ref, jobId) {
  return ref.read(applicationRepositoryProvider).jobApplicationsStream(jobId);
});

final recruiterAllApplicationsStreamProvider =
    StreamProvider<List<ApplicationModel>>((ref) {
  final jobs = ref.watch(recruiterJobsStreamProvider).value ?? [];
  if (jobs.isEmpty) return Stream.value([]);
  final jobIds = jobs.map((j) => j.id).take(30).toList();
  return FirebaseFirestore.instance
      .collection('applications')
      .where('jobId', whereIn: jobIds)
      .snapshots()
      .map((snap) {
        final apps = snap.docs.map(ApplicationModel.fromDoc).toList();
        apps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
        return apps;
      });
});

class RecruiterStats {
  final int activeJobs;
  final int totalApplicants;
  final int shortlisted;

  const RecruiterStats({
    required this.activeJobs,
    required this.totalApplicants,
    required this.shortlisted,
  });
}

final recruiterStatsProvider = Provider<RecruiterStats>((ref) {
  final jobs = ref.watch(recruiterJobsStreamProvider).value ?? [];
  final apps =
      ref.watch(recruiterAllApplicationsStreamProvider).value ?? [];
  return RecruiterStats(
    activeJobs: jobs.where((j) => j.isActive).length,
    totalApplicants: apps.length,
    shortlisted:
        apps.where((a) => a.status == ApplicationStatus.shortlisted).length,
  );
});
