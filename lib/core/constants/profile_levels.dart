import '../../data/models/cv_model.dart';

/// Shared experience / education levels for recruiter job posts and candidate CVs.
class ProfileLevels {
  ProfileLevels._();

  static const candidateEducationLevels = [
    'High School',
    "Associate's",
    "Bachelor's",
    "Master's",
    'PhD',
  ];

  static const jobEducationLevels = [
    ...candidateEducationLevels,
    'No degree required',
  ];

  static const experienceOptions = <({String id, String label})>[
    (id: 'junior', label: 'Junior (0–2 years)'),
    (id: 'mid', label: 'Mid-level (2–5 years)'),
    (id: 'senior', label: 'Senior (5+ years)'),
    (id: 'lead', label: 'Lead / Principal'),
  ];

  static String experienceLabel(String? id) {
    if (id == null || id.isEmpty) return 'Not specified';
    return experienceOptions
        .firstWhere(
          (e) => e.id == id,
          orElse: () => (id: id, label: id),
        )
        .label;
  }

  static int _educationRank(String level) {
    final n = level.toLowerCase();
    if (n.contains('phd') || n.contains('doctor')) return 5;
    if (n.contains('master')) return 4;
    if (n.contains('bachelor') || n.contains('bsc') || n.contains('bs ')) {
      return 3;
    }
    if (n.contains('associate')) return 2;
    if (n.contains('high school') || n.contains('diploma')) return 1;
    return 0;
  }

  static int _experienceRank(String level) {
    switch (level) {
      case 'lead':
        return 4;
      case 'senior':
        return 3;
      case 'mid':
        return 2;
      case 'junior':
        return 1;
      default:
        return 0;
    }
  }

  /// Maps free-text degree strings to a canonical education level.
  static String? normalizeEducationLevel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final n = raw.toLowerCase().trim();
    for (final level in candidateEducationLevels) {
      if (n == level.toLowerCase()) return level;
    }
    if (n.contains('phd') || n.contains('doctor')) return 'PhD';
    if (n.contains('master') || n.contains('msc') || n.contains('mba')) {
      return "Master's";
    }
    if (n.contains('bachelor') ||
        n.contains('bsc') ||
        n.contains('bs ') ||
        n.contains('undergrad')) {
      return "Bachelor's";
    }
    if (n.contains('associate')) return "Associate's";
    if (n.contains('high school') || n.contains('secondary')) {
      return 'High School';
    }
    return null;
  }

  static String? inferEducationLevel(List<Education> education) {
    var best = 0;
    String? bestLevel;
    for (final ed in education) {
      final normalized = normalizeEducationLevel(ed.degree);
      if (normalized == null) continue;
      final rank = _educationRank(normalized);
      if (rank > best) {
        best = rank;
        bestLevel = normalized;
      }
    }
    return bestLevel;
  }

  static String? inferExperienceLevel(int workExperienceCount) {
    if (workExperienceCount <= 0) return null;
    if (workExperienceCount == 1) return 'junior';
    if (workExperienceCount == 2) return 'mid';
    if (workExperienceCount == 3) return 'senior';
    return 'lead';
  }

  /// 0–100: candidate meets or exceeds job education requirement.
  static int educationMatchScore(String? candidateLevel, String? jobLevel) {
    if (jobLevel == null ||
        jobLevel.isEmpty ||
        jobLevel == 'No degree required') {
      return 100;
    }
    final normalized =
        normalizeEducationLevel(candidateLevel) ?? candidateLevel;
    if (normalized == null || normalized.isEmpty) return 0;

    final cRank = _educationRank(normalized);
    final jRank = _educationRank(jobLevel);
    if (cRank >= jRank) return 100;
    if (cRank == jRank - 1) return 65;
    if (cRank > 0 && jRank > 0) return 35;
    return 0;
  }

  /// 0–100: candidate meets or exceeds job experience requirement.
  static int experienceMatchScore(String? candidateLevel, String? jobLevel) {
    if (jobLevel == null || jobLevel.isEmpty) return 100;
    if (candidateLevel == null || candidateLevel.isEmpty) return 40;

    final cRank = _experienceRank(candidateLevel);
    final jRank = _experienceRank(jobLevel);
    if (cRank >= jRank) return 100;
    if (cRank == jRank - 1) return 70;
    if (cRank > 0) return 35;
    return 0;
  }

  static String? resolveCandidateEducation(CvModel cv) =>
      normalizeEducationLevel(cv.educationLevel) ??
      inferEducationLevel(cv.education);

  static String? resolveCandidateExperience(CvModel cv) =>
      cv.experienceLevel?.isNotEmpty == true
          ? cv.experienceLevel
          : inferExperienceLevel(cv.workExperience.length);
}
