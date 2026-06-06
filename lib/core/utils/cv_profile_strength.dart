import '../../data/models/cv_model.dart';
import '../constants/profile_levels.dart';

/// Shared CV completeness score (0–100). Used on upload, AI parse, and manual edit.
class CvProfileStrength {
  static int calculate({
    required List<String> skills,
    required List<WorkExperience> workExperience,
    required List<Education> education,
    bool hasFile = false,
    String? experienceLevel,
    String? educationLevel,
  }) {
    var score = 0;

    if (hasFile) score += 10;

    if (skills.isNotEmpty) score += 10;
    if (skills.length >= 5) score += 10;
    if (skills.length >= 10) score += 10;

    if (workExperience.isNotEmpty) score += 15;
    if (workExperience.length >= 2) score += 10;
    if (workExperience.length >= 3) score += 5;
    final withDesc = workExperience
        .where((e) => e.description.trim().length > 20)
        .length;
    if (workExperience.isNotEmpty && withDesc == workExperience.length) {
      score += 5;
    }

    if (education.isNotEmpty) score += 15;
    final hasCompleteEntry = education.any((e) =>
        e.degree.isNotEmpty &&
        e.field.isNotEmpty &&
        e.institution.isNotEmpty);
    if (hasCompleteEntry) score += 10;

    if (experienceLevel != null && experienceLevel.isNotEmpty) score += 5;
    if (educationLevel != null && educationLevel.isNotEmpty) score += 5;

    return score.clamp(0, 100);
  }

  static int fromCv(CvModel cv) => calculate(
        skills: cv.skills,
        workExperience: cv.workExperience,
        education: cv.education,
        hasFile: cv.hasFile,
        experienceLevel: cv.experienceLevel ??
            ProfileLevels.inferExperienceLevel(cv.workExperience.length),
        educationLevel:
            cv.educationLevel ?? ProfileLevels.inferEducationLevel(cv.education),
      );
}
