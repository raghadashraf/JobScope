import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/job_model.dart';
import 'ai_providers.dart';
import '../../../data/models/training_session_model.dart';
import '../../../data/repositories/training_repository.dart';
import '../../auth/data/auth_providers.dart';

final trainingRepositoryProvider =
    Provider<TrainingRepository>((_) => TrainingRepository());

class TrainBeforeApplyParams {
  final String jobId;
  final String jobTitle;
  final String company;
  final String jobDescription;
  final List<String> skills;

  const TrainBeforeApplyParams({
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.jobDescription,
    this.skills = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is TrainBeforeApplyParams &&
      other.jobId == jobId &&
      other.jobTitle == jobTitle;

  @override
  int get hashCode => Object.hash(jobId, jobTitle);
}

final trainBeforeApplyQuestionsProvider = FutureProvider.autoDispose
    .family<List<TrainQuestion>, TrainBeforeApplyParams>((ref, params) {
  return ref.read(aiServiceProvider).generateTrainBeforeApplyQuestions(
        jobTitle: params.jobTitle,
        company: params.company,
        jobDescription: params.jobDescription,
        skills: params.skills,
      );
});

final latestCompletedTrainingProvider =
    StreamProvider.autoDispose.family<TrainingSessionModel?, String>(
        (ref, jobId) {
  final uid = ref.watch(firebaseUserProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.read(trainingRepositoryProvider).latestCompletedForJob(
        uid: uid,
        jobId: jobId,
      );
});

TrainBeforeApplyParams trainParamsFromJob(JobModel job) =>
    TrainBeforeApplyParams(
      jobId: job.id,
      jobTitle: job.title,
      company: job.company,
      jobDescription: job.description,
      skills: job.skills,
    );
