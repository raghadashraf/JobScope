import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/cv_model.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/notification_repository.dart';
import 'job_matching_service.dart';

/// Notifies candidates when active jobs match their CV skills (in-app inbox).
class JobMatchNotificationService {
  static const _prefsKey = 'notified_job_match_ids';
  static const int minMatchScore = 40;

  final JobMatchingService _matching = JobMatchingService();

  Future<void> syncMatchNotifications({
    required String candidateId,
    required CvModel? cv,
    required List<JobModel> jobs,
    required NotificationRepository notifications,
  }) async {
    if (cv == null) return;
    final canMatch = cv.skills.isNotEmpty ||
        cv.experienceLevel != null ||
        cv.educationLevel != null ||
        cv.workExperience.isNotEmpty ||
        cv.education.isNotEmpty;
    if (!canMatch) return;

    final prefs = await SharedPreferences.getInstance();
    final notified = prefs.getStringList(_prefsKey)?.toSet() ?? {};

    for (final job in jobs) {
      if (!job.isActive || job.isDeleted) continue;
      if (notified.contains(job.id)) continue;

      final score = _matching.structuredMatchScore(cv, job);
      if (score < minMatchScore) continue;

      await notifications.notifyCandidateJobMatch(
        candidateId: candidateId,
        job: job,
        matchScore: score,
      );
      notified.add(job.id);
    }

    final trimmed = notified.length <= 300
        ? notified.toList()
        : notified.toList().sublist(notified.length - 300);
    await prefs.setStringList(_prefsKey, trimmed);
  }
}
