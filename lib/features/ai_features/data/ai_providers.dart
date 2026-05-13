import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_service.dart';
import '../../cv_management/data/cv_providers.dart';
import '../../job_listing/data/job_providers.dart';

// ─── Service provider ─────────────────────────────────────────────────────────
final aiServiceProvider = Provider<AiService>((_) => AiService());

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

// ─── Job match score ──────────────────────────────────────────────────────────
final jobMatchScoreProvider =
    FutureProvider.autoDispose.family<int?, String>((ref, jobId) async {
  final cv = ref.watch(cvStreamProvider).value;
  if (cv == null || cv.skills.isEmpty) return null;
  final job = await ref.read(jobRepositoryProvider).fetchJob(jobId);
  if (job == null || job.skills.isEmpty) return null;
  return ref.read(aiServiceProvider).matchJob(
        jobSkills: job.skills,
        cvSkills: cv.skills,
        jobDescription: job.description,
      );
});
