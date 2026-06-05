import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/job_model.dart';
import '../../../data/repositories/application_repository.dart';
import '../../ai_features/data/ai_providers.dart';
import '../../auth/data/auth_providers.dart';
import '../../cv_management/data/cv_providers.dart';
import '../../job_listing/data/job_providers.dart';
import '../../notifications/data/notification_providers.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final applicationRepositoryProvider =
    Provider<ApplicationRepository>((_) => ApplicationRepository());

// ─── Stream: current candidate's applications ─────────────────────────────────
/// Live application doc (status / timeline updates without leaving detail screen).
final applicationByIdProvider =
    StreamProvider.autoDispose.family<ApplicationModel?, String>((ref, id) {
  return ref.read(applicationRepositoryProvider).applicationStream(id);
});

final myApplicationsProvider =
    StreamProvider<List<ApplicationModel>>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref
      .read(applicationRepositoryProvider)
      .candidateApplicationsStream(user.uid);
});

// ─── Stream: has this candidate applied to a specific job ─────────────────────
final hasAppliedProvider =
    StreamProvider.family<bool, String>((ref, jobId) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value(false);
  return ref.read(applicationRepositoryProvider).hasAppliedStream(
        jobId: jobId,
        candidateId: user.uid,
      );
});

// ─── Apply action state ───────────────────────────────────────────────────────
enum ApplyStatus { idle, loading, success, alreadyApplied, error }

class ApplyState {
  final ApplyStatus status;
  final String? errorMessage;
  final ApplicationModel? application;

  const ApplyState({
    this.status = ApplyStatus.idle,
    this.errorMessage,
    this.application,
  });

  ApplyState copyWith({
    ApplyStatus? status,
    String? errorMessage,
    ApplicationModel? application,
  }) =>
      ApplyState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        application: application ?? this.application,
      );
}

// ─── Apply notifier ───────────────────────────────────────────────────────────
class ApplyNotifier extends Notifier<ApplyState> {
  @override
  ApplyState build() => const ApplyState();

  Future<void> apply({
    required String jobId,
    required String jobTitle,
    required String company,
  }) async {
    final user = ref.read(firebaseUserProvider).value;
    if (user == null) {
      state =
          const ApplyState(status: ApplyStatus.error, errorMessage: 'Not logged in');
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    final cv = ref.read(cvStreamProvider).value;

    state = state.copyWith(status: ApplyStatus.loading);

    try {
      int? matchScore;
      JobModel? job;
      if (cv != null && cv.skills.isNotEmpty) {
        job = await ref.read(jobRepositoryProvider).fetchJob(jobId);
        if (job != null) {
          try {
            final result = await ref
                .read(jobMatchingServiceProvider)
                .calculateMatch(cv, job);
            matchScore = result.score;
          } catch (_) {
            // Apply proceeds without matchScore if embedding/API fails.
          }
        }
      }
      job ??= await ref.read(jobRepositoryProvider).fetchJob(jobId);

      final application = await ref
          .read(applicationRepositoryProvider)
          .apply(
            jobId: jobId,
            jobTitle: jobTitle,
            company: company,
            candidateId: user.uid,
            candidateName: currentUser?.name ?? user.displayName ?? '',
            candidateEmail: user.email ?? '',
            candidatePhotoUrl: currentUser?.photoUrl,
            cvUrl: cv?.fileUrl,
            matchScore: matchScore,
          );

      if (job != null) {
        try {
          await ref
              .read(notificationActionsProvider)
              .notifyRecruiterNewApplication(job: job, application: application);
        } catch (_) {
          // In-app notification is best-effort; apply already succeeded.
        }
      }

      state = ApplyState(
          status: ApplyStatus.success, application: application);
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final isAlreadyApplied = msg.contains('already applied');
      state = ApplyState(
        status: isAlreadyApplied
            ? ApplyStatus.alreadyApplied
            : ApplyStatus.error,
        errorMessage: msg,
      );
    }
  }

  void reset() => state = const ApplyState();
}

final applyNotifierProvider =
    NotifierProvider<ApplyNotifier, ApplyState>(ApplyNotifier.new);

// ─── Withdraw notifier ────────────────────────────────────────────────────────
class WithdrawNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<String?> withdraw(String applicationId) async {
    final user = ref.read(firebaseUserProvider).value;
    if (user == null) return 'Not logged in';

    state = true;
    try {
      await ref.read(applicationRepositoryProvider).withdraw(
            applicationId: applicationId,
            candidateId: user.uid,
          );
      return null;
    } on Exception catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      state = false;
    }
  }
}

final withdrawNotifierProvider =
    NotifierProvider<WithdrawNotifier, bool>(WithdrawNotifier.new);
