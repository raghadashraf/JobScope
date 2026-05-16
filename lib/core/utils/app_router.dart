import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/application_model.dart';
import '../../data/models/job_model.dart';
import '../../data/models/user_model.dart';
import '../../features/ai_features/data/ai_providers.dart';
import '../../features/ai_features/presentation/interview_training_screen.dart';
import '../../features/ai_features/presentation/skill_assessment_screen.dart';
import '../../features/applications/presentation/application_detail_screen.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/presentation/edit_profile_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/cv_management/presentation/cv_screen.dart';
import '../../features/home/presentation/candidate_home_screen.dart';
import '../../features/home/presentation/post_job_screen.dart';
import '../../features/home/presentation/recruiter_home_screen.dart';
import '../../features/job_listing/presentation/job_detail_screen.dart';
import '../../features/job_listing/presentation/jobs_screen.dart';
import '../../features/recruiter/presentation/applicant_detail_screen.dart';
import '../../features/recruiter/presentation/job_applicants_screen.dart';

// ─── Route paths ──────────────────────────────────────────────────────────────
class AppRoutes {
  static const roleSelection = '/role-selection';
  static const login = '/login';
  static const register = '/register';
  static const candidateHome = '/candidate-home';
  static const recruiterHome = '/recruiter-home';
  static const jobDetail = '/job-detail';
  static const applicationDetail = '/application-detail';
  static const editProfile = '/edit-profile';
  static const cv = '/cv';
  static const postJob = '/post-job';
  static const jobApplicants = '/job-applicants';
  static const applicantDetail = '/applicant-detail';
  static const interviewTraining = '/interview-training';
  static const skillAssessment = '/skill-assessment';
  static const jobs = '/jobs';
}

// ─── Auth guard notifier ──────────────────────────────────────────────────────
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (_, _) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(currentUserProvider);

    // Still resolving auth — don't redirect yet
    if (authState.isLoading) return null;

    final user = authState.value;
    final loc = state.matchedLocation;

    final isPublic = loc == '/' ||
        loc.startsWith(AppRoutes.roleSelection) ||
        loc.startsWith(AppRoutes.login) ||
        loc.startsWith(AppRoutes.register);

    if (user == null) {
      return isPublic ? null : AppRoutes.roleSelection;
    }

    // Logged in — redirect away from public/root routes
    if (isPublic) {
      return user.role == UserRole.recruiter
          ? AppRoutes.recruiterHome
          : AppRoutes.candidateHome;
    }

    return null;
  }
}

// ─── Router provider ──────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: AppRoutes.roleSelection,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, _) => AppRoutes.roleSelection,
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (_, _) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) =>
            LoginScreen(role: state.extra as String? ?? 'candidate'),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, state) =>
            SignupScreen(role: state.extra as String? ?? 'candidate'),
      ),
      GoRoute(
        path: AppRoutes.candidateHome,
        builder: (_, _) => const CandidateHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.recruiterHome,
        builder: (_, _) => const RecruiterHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.jobDetail,
        redirect: (_, state) =>
            state.extra is JobModel ? null : AppRoutes.jobs,
        builder: (_, state) =>
            JobDetailScreen(job: state.extra as JobModel),
      ),
      GoRoute(
        path: AppRoutes.applicationDetail,
        redirect: (_, state) => state.extra is ApplicationModel
            ? null
            : AppRoutes.candidateHome,
        builder: (_, state) => ApplicationDetailScreen(
            application: state.extra as ApplicationModel),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.cv,
        builder: (_, _) => const CvScreen(),
      ),
      GoRoute(
        path: AppRoutes.postJob,
        builder: (_, state) =>
            PostJobScreen(jobToEdit: state.extra as JobModel?),
      ),
      GoRoute(
        path: AppRoutes.jobApplicants,
        redirect: (_, state) =>
            state.extra is JobModel ? null : AppRoutes.recruiterHome,
        builder: (_, state) =>
            JobApplicantsScreen(job: state.extra as JobModel),
      ),
      GoRoute(
        path: AppRoutes.applicantDetail,
        redirect: (_, state) =>
            state.extra is ApplicationModel ? null : AppRoutes.recruiterHome,
        builder: (_, state) => ApplicantDetailScreen(
            application: state.extra as ApplicationModel),
      ),
      GoRoute(
        path: AppRoutes.interviewTraining,
        builder: (_, state) => InterviewTrainingScreen(
            params: state.extra as InterviewParams?),
      ),
      GoRoute(
        path: AppRoutes.skillAssessment,
        builder: (_, _) => const SkillAssessmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.jobs,
        builder: (_, _) => const JobsScreen(),
      ),
    ],
  );
});
