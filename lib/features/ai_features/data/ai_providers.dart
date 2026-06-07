import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/firestore_helpers.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/constants/profile_levels.dart';
import '../../../core/services/job_matching_service.dart';
import '../../../data/models/cv_model.dart';
import '../../../data/models/job_model.dart';
import '../../auth/data/auth_providers.dart';
import '../../cv_management/data/cv_providers.dart';
import '../../job_listing/data/job_providers.dart';

// ─── Service provider ─────────────────────────────────────────────────────────
final aiServiceProvider = Provider<AiService>((_) => AiService());

final jobMatchingServiceProvider =
    Provider<JobMatchingService>((_) => JobMatchingService());

// ─── Job match count (local, no API) ─────────────────────────────────────────
final jobMatchCountProvider = Provider<int>((ref) {
  final jobs = ref.watch(jobsStreamProvider).value ?? [];
  final cv = ref.watch(cvStreamProvider).value;
  if (cv == null) return 0;
  final service = ref.read(jobMatchingServiceProvider);
  return jobs
      .where((job) =>
          job.isActive &&
          !job.isDeleted &&
          service.structuredMatchScore(cv, job) >= 40)
      .length;
});

// ─── Interview questions params ───────────────────────────────────────────────
class InterviewParams {
  final String jobTitle;
  final String? jobDescription;
  final List<String> skills;

  const InterviewParams({
    required this.jobTitle,
    this.jobDescription,
    this.skills = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is InterviewParams &&
      other.jobTitle == jobTitle &&
      other.jobDescription == jobDescription;

  @override
  int get hashCode => Object.hash(jobTitle, jobDescription);
}

// ─── Interview questions ──────────────────────────────────────────────────────
final interviewQuestionsProvider = FutureProvider.autoDispose
    .family<List<InterviewQuestion>, InterviewParams>((ref, params) =>
        ref.read(aiServiceProvider).generateInterviewQuestions(
              jobTitle: params.jobTitle,
              jobDescription: params.jobDescription,
              skills: params.skills,
            ));

// ─── Skill quiz ───────────────────────────────────────────────────────────────
final skillQuizProvider = FutureProvider.autoDispose
    .family<List<QuizQuestion>, List<String>>(
        (ref, skills) =>
            ref.read(aiServiceProvider).generateSkillQuiz(skills));

// ─── Job match (embedding similarity) ─────────────────────────────────────────
final jobMatchResultProvider =
    FutureProvider.autoDispose.family<MatchResult?, String>((ref, jobId) async {
  final cv = ref.watch(cvStreamProvider).value;
  if (cv == null) return null;
  final hasMatchData = cv.skills.isNotEmpty ||
      ProfileLevels.resolveCandidateExperience(cv) != null ||
      ProfileLevels.resolveCandidateEducation(cv) != null;
  if (!hasMatchData) return null;
  final job = await ref.read(jobRepositoryProvider).fetchJob(jobId);
  if (job == null) return null;
  return ref.read(jobMatchingServiceProvider).calculateMatch(cv, job);
});

/// Sorts the job list by local skill/level overlap. Embedding scores stay on job detail only.
final matchSortedJobsProvider = Provider<AsyncValue<List<JobModel>>>((ref) {
  final jobsAsync = ref.watch(filteredJobsProvider);
  return jobsAsync.whenData((jobs) {
    final cv = ref.watch(cvStreamProvider).value;
    if (cv == null || cv.skills.isEmpty) return jobs;

    final service = ref.read(jobMatchingServiceProvider);
    final sorted = List<JobModel>.from(jobs);
    sorted.sort(
      (a, b) => service
          .structuredMatchScore(cv, b)
          .compareTo(service.structuredMatchScore(cv, a)),
    );
    return sorted;
  });
});

class MatchReasonsParams {
  final String jobId;
  final List<String> cvSkills;
  const MatchReasonsParams({required this.jobId, required this.cvSkills});

  @override
  bool operator ==(Object other) => other is MatchReasonsParams && other.jobId == jobId;

  @override
  int get hashCode => jobId.hashCode;
}

final matchReasonsProvider = FutureProvider.autoDispose
    .family<MatchReason?, MatchReasonsParams>((ref, params) async {
  if (params.cvSkills.isEmpty) return null;
  final job = await ref.read(jobRepositoryProvider).fetchJob(params.jobId);
  if (job == null) return null;
  return ref.read(aiServiceProvider).getMatchReasons(
        cvSkills: params.cvSkills,
        jobSkills: job.skills,
        jobRequirements: job.requirements,
        jobTitle: job.title,
      );
});

// ─── Cover Letter ─────────────────────────────────────────────────────────────

class CoverLetterParams {
  final String jobTitle;
  final String company;
  final String jobDescription;
  final List<String> cvSkills;
  final List<WorkExperience> workExperience;

  const CoverLetterParams({
    required this.jobTitle,
    required this.company,
    required this.jobDescription,
    required this.cvSkills,
    this.workExperience = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is CoverLetterParams &&
      other.jobTitle == jobTitle &&
      other.company == company;

  @override
  int get hashCode => Object.hash(jobTitle, company);
}

final coverLetterProvider = FutureProvider.autoDispose
    .family<String, CoverLetterParams>((ref, params) =>
        ref.read(aiServiceProvider).generateCoverLetter(
              jobTitle: params.jobTitle,
              company: params.company,
              jobDescription: params.jobDescription,
              cvSkills: params.cvSkills,
              workExperience: params.workExperience,
            ));

// ─── Save Cover Letter ────────────────────────────────────────────────────────

enum SaveCoverLetterStatus { idle, saving, saved, error }

class SaveCoverLetterState {
  final SaveCoverLetterStatus status;
  final String? errorMessage;
  const SaveCoverLetterState({
    this.status = SaveCoverLetterStatus.idle,
    this.errorMessage,
  });
}

class SaveCoverLetterNotifier extends Notifier<SaveCoverLetterState> {
  @override
  SaveCoverLetterState build() => const SaveCoverLetterState();

  Future<void> save({
    required String jobId,
    required String jobTitle,
    required String company,
    required String letterText,
  }) async {
    final user = ref.read(firebaseUserProvider).value;
    if (user == null) {
      state = const SaveCoverLetterState(
        status: SaveCoverLetterStatus.error,
        errorMessage: 'Not logged in',
      );
      return;
    }

    state = const SaveCoverLetterState(status: SaveCoverLetterStatus.saving);
    try {
      await appFirestore
          .collection('cover_letters')
          .doc('${user.uid}_$jobId')
          .set({
        'candidateId': user.uid,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'company': company,
        'letterText': letterText,
        'savedAt': FieldValue.serverTimestamp(),
      });
      state = const SaveCoverLetterState(status: SaveCoverLetterStatus.saved);
    } catch (e) {
      state = SaveCoverLetterState(
        status: SaveCoverLetterStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const SaveCoverLetterState();
}

final saveCoverLetterProvider =
    NotifierProvider<SaveCoverLetterNotifier, SaveCoverLetterState>(
        SaveCoverLetterNotifier.new);
