import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cv_parser_service.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/cv_model.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/user_model.dart';
import '../../applications/data/application_providers.dart';
import '../../auth/data/auth_providers.dart';

enum ApplicantFilterStatus { all, pending, shortlisted }

class ApplicantFilterNotifier extends Notifier<ApplicantFilterStatus> {
  @override
  ApplicantFilterStatus build() => ApplicantFilterStatus.all;

  void setFilter(ApplicantFilterStatus f) => state = f;
}

final applicantFilterProvider =
    NotifierProvider<ApplicantFilterNotifier, ApplicantFilterStatus>(
        ApplicantFilterNotifier.new);

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

final sortedApplicantsProvider =
    Provider.family<AsyncValue<List<ApplicationModel>>, String>((ref, jobId) {
  final appsAsync = ref.watch(jobApplicationsStreamProvider(jobId));
  final filter = ref.watch(applicantFilterProvider);

  return appsAsync.whenData((apps) {
    var result = List<ApplicationModel>.from(apps);

    if (filter == ApplicantFilterStatus.pending) {
      result = result
          .where((a) => a.status == ApplicationStatus.pending)
          .toList();
    } else if (filter == ApplicantFilterStatus.shortlisted) {
      result = result
          .where((a) => a.status == ApplicationStatus.shortlisted)
          .toList();
    }

    result.sort((a, b) {
      if (a.matchScore == null && b.matchScore == null) return 0;
      if (a.matchScore == null) return 1;
      if (b.matchScore == null) return -1;
      return b.matchScore!.compareTo(a.matchScore!);
    });

    return result;
  });
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

final candidateCvProvider =
    FutureProvider.autoDispose.family<CvModel?, String>((ref, candidateId) async {
  final service = CvParserService();
  return service.getCv(candidateId);
});

final candidateProfileProvider =
    FutureProvider.autoDispose.family<UserModel?, String>(
        (ref, candidateId) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(candidateId)
      .get();
  if (!doc.exists) return null;
  return UserModel.fromMap(doc.data()!);
});
