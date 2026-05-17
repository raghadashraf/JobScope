import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cv_parser_service.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/cv_model.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/user_model.dart';
import '../../applications/data/application_providers.dart';
import '../../auth/data/auth_providers.dart';
import '../../job_listing/data/job_providers.dart';

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
  return ref.read(jobRepositoryProvider).recruiterJobsStream(user.uid);
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

class RecruiterAnalytics {
  final int totalApplicants;
  final int activeJobs;
  final double acceptanceRate;
  final double averageMatchScore;
  final List<MapEntry<String, int>> topSkills;
  final Map<String, int> statusBreakdown;
  final List<ApplicationModel> recentActivity;

  const RecruiterAnalytics({
    required this.totalApplicants,
    required this.activeJobs,
    required this.acceptanceRate,
    required this.averageMatchScore,
    required this.topSkills,
    required this.statusBreakdown,
    required this.recentActivity,
  });
}

final recruiterAnalyticsProvider = Provider<RecruiterAnalytics>((ref) {
  final apps = ref.watch(recruiterAllApplicationsStreamProvider).value ?? [];
  final jobs = ref.watch(recruiterJobsStreamProvider).value ?? [];

  final statusBreakdown = {
    'pending': apps.where((a) => a.status == ApplicationStatus.pending).length,
    'shortlisted':
        apps.where((a) => a.status == ApplicationStatus.shortlisted).length,
    'accepted': apps.where((a) => a.status == ApplicationStatus.accepted).length,
    'rejected': apps.where((a) => a.status == ApplicationStatus.rejected).length,
  };

  final accepted = statusBreakdown['accepted']!;
  final acceptanceRate =
      apps.isEmpty ? 0.0 : (accepted / apps.length) * 100;

  final scored = apps.where((a) => a.matchScore != null).toList();
  final averageMatchScore = scored.isEmpty
      ? 0.0
      : scored.map((a) => a.matchScore!).reduce((a, b) => a + b) /
            scored.length;

  final skillCount = <String, int>{};
  for (final job in jobs) {
    for (final skill in job.skills) {
      final key = skill.toLowerCase().trim();
      skillCount[key] = (skillCount[key] ?? 0) + 1;
    }
  }
  final topSkills = skillCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top5 = topSkills.take(5).toList();

  final sorted = List<ApplicationModel>.from(apps)
    ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
  final recentActivity = sorted.take(8).toList();

  return RecruiterAnalytics(
    totalApplicants: apps.length,
    activeJobs: jobs.where((j) => j.isActive).length,
    acceptanceRate: acceptanceRate,
    averageMatchScore: averageMatchScore,
    topSkills: top5,
    statusBreakdown: statusBreakdown,
    recentActivity: recentActivity,
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
