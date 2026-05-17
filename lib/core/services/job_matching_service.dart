import 'dart:math' show sqrt;

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
    return "Skills: ${cv.skills.join(', ')}. Experience: ${cv.workExperience.map((e) => '${e.title} at ${e.company}: ${e.description}').join('. ')}. Education: ${cv.education.map((e) => '${e.degree} in ${e.field}').join(', ')}";
  }

  String buildJobText(JobModel job) {
    return "Job title: ${job.title}. Requirements: ${job.requirements.join(', ')}. Skills needed: ${job.skills.join(', ')}. Description: ${job.description}";
  }

  Future<MatchResult> calculateMatch(CvModel cv, JobModel job) async {
    final embed = GeminiEmbeddingService();
    final cvVec =
        await embed.getCachedEmbedding('cv_${cv.uid}', buildCvText(cv));
    final jobVec =
        await embed.getCachedEmbedding('job_${job.id}', buildJobText(job));
    final similarity = cosineSimilarity(cvVec, jobVec);
    final score =
        (similarity * 100).round().clamp(0, 100);
    return MatchResult(score: score, category: categorise(score));
  }
}
