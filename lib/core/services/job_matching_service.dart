import 'dart:math' show sqrt;

import '../../core/constants/profile_levels.dart';
import '../../data/models/cv_model.dart';
import '../../data/models/job_model.dart';
import 'gemini_embedding_service.dart';

enum MatchCategory { excellent, good, fair, low }

class MatchResult {
  final int score;
  final MatchCategory category;
  const MatchResult({required this.score, required this.category});
}

class JobMatchingService {
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    var dot = 0.0;
    var magA = 0.0;
    var magB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    if (magA == 0 || magB == 0) return 0.0;
    return dot / (sqrt(magA) * sqrt(magB));
  }

  MatchCategory categorise(int score) {
    if (score >= 80) return MatchCategory.excellent;
    if (score >= 60) return MatchCategory.good;
    if (score >= 40) return MatchCategory.fair;
    return MatchCategory.low;
  }

  String buildCvText(CvModel cv) {
    final exp = ProfileLevels.resolveCandidateExperience(cv);
    final edu = ProfileLevels.resolveCandidateEducation(cv);
    final expLabel = exp != null ? ProfileLevels.experienceLabel(exp) : '';
    return 'Skills: ${cv.skills.join(', ')}. '
        'Experience level: $expLabel. '
        'Education level: ${edu ?? ''}. '
        'Work history: ${cv.workExperience.map((e) => '${e.title} at ${e.company}: ${e.description}').join('. ')}. '
        'Education: ${cv.education.map((e) => '${e.degree} in ${e.field} at ${e.institution}').join(', ')}';
  }

  String buildJobText(JobModel job) {
    final education = job.educationLevel != null
        ? 'Education required: ${job.educationLevel}. '
        : '';
    final experience = job.experienceLevel != null
        ? 'Experience required: ${ProfileLevels.experienceLabel(job.experienceLevel)}. '
        : '';
    final benefits = job.benefits.isNotEmpty
        ? 'Benefits: ${job.benefits.join(', ')}. '
        : '';
    return 'Job title: ${job.title}. '
        'Requirements: ${job.requirements.join(', ')}. '
        'Skills needed: ${job.skills.join(', ')}. '
        '$experience$education$benefits'
        'Description: ${job.description}';
  }

  /// Skill overlap only (0–100).
  int skillOverlapScore(CvModel cv, JobModel job) {
    final cvTerms = cv.skills
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.length > 1)
        .toList();
    if (cvTerms.isEmpty) return 0;

    final jobTerms = (job.skills.isNotEmpty ? job.skills : job.requirements)
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.length > 1)
        .toSet();

    if (jobTerms.isEmpty) return 0;

    var matched = 0;
    for (final term in jobTerms) {
      if (cvTerms.any((cvSkill) =>
          cvSkill == term ||
          cvSkill.contains(term) ||
          term.contains(cvSkill))) {
        matched++;
      }
    }

    return ((matched / jobTerms.length) * 100).round().clamp(0, 100);
  }

  /// Skills + experience level + education level (0–100).
  int structuredMatchScore(CvModel cv, JobModel job) {
    final skillScore = skillOverlapScore(cv, job);
    final candidateEdu = ProfileLevels.resolveCandidateEducation(cv);
    final candidateExp = ProfileLevels.resolveCandidateExperience(cv);
    final eduScore = ProfileLevels.educationMatchScore(
      candidateEdu,
      job.educationLevel,
    );
    final expScore = ProfileLevels.experienceMatchScore(
      candidateExp,
      job.experienceLevel,
    );

    final jobHasSkills =
        job.skills.isNotEmpty || job.requirements.isNotEmpty;
    final jobHasLevels =
        job.experienceLevel != null || job.educationLevel != null;

    if (skillScore > 0 && jobHasSkills) {
      return ((skillScore * 0.55) + (expScore * 0.25) + (eduScore * 0.20))
          .round()
          .clamp(0, 100);
    }

    if (jobHasLevels) {
      return ((expScore * 0.5) + (eduScore * 0.5)).round().clamp(0, 100);
    }

    return skillScore;
  }

  Future<MatchResult> calculateMatch(CvModel cv, JobModel job) async {
    final structured = structuredMatchScore(cv, job);

    try {
      final embed = GeminiEmbeddingService();
      final cvVec =
          await embed.getCachedEmbedding('cv_${cv.uid}', buildCvText(cv));
      final jobVec =
          await embed.getCachedEmbedding('job_${job.id}', buildJobText(job));
      final similarity = cosineSimilarity(cvVec, jobVec);
      final embeddingScore = (similarity * 100).round().clamp(0, 100);

      if (structured == 0) {
        return MatchResult(
          score: embeddingScore,
          category: categorise(embeddingScore),
        );
      }

      final blended =
          ((embeddingScore * 0.45) + (structured * 0.55)).round();
      return MatchResult(
        score: blended.clamp(0, 100),
        category: categorise(blended),
      );
    } catch (_) {
      return MatchResult(
        score: structured,
        category: categorise(structured),
      );
    }
  }
}
