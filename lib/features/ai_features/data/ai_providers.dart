import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/job_matching_service.dart';
import '../../../data/models/job_model.dart';
import '../../cv_management/data/cv_providers.dart';
import '../../job_listing/data/job_providers.dart';

// ─── Service provider ─────────────────────────────────────────────────────────
final aiServiceProvider = Provider<AiService>((_) => AiService());

final jobMatchingServiceProvider =
    Provider<JobMatchingService>((_) => JobMatchingService());

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
  if (cv == null || cv.skills.isEmpty) return null;
  final job = await ref.read(jobRepositoryProvider).fetchJob(jobId);
  if (job == null) return null;
  return ref.read(jobMatchingServiceProvider).calculateMatch(cv, job);
});

final matchSortedJobsProvider =
    FutureProvider.autoDispose<List<JobModel>>((ref) async {
  final jobsAsync = ref.watch(filteredJobsProvider);
  final jobs = jobsAsync.value ?? [];
  final cv = ref.watch(cvStreamProvider).value;
  if (cv == null || cv.skills.isEmpty) return jobs;

  final service = ref.read(jobMatchingServiceProvider);
  final scored = await Future.wait(
    jobs.map((job) async {
      try {
        final result = await service.calculateMatch(cv, job);
        return (job: job, score: result.score);
      } catch (_) {
        return (job: job, score: 0);
      }
    }),
  );
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.map((e) => e.job).toList();
});

class MatchReasonsParams {
  final String jobId;
  final List<String> cvSkills;
  const MatchReasonsParams({required this.jobId, required this.cvSkills});

  @override
  bool operator ==(Object o) => o is MatchReasonsParams && o.jobId == jobId;

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
