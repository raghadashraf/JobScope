import 'package:flutter_test/flutter_test.dart';
import 'package:jobscope/core/constants/profile_levels.dart';
import 'package:jobscope/core/services/job_matching_service.dart';
import 'package:jobscope/data/models/cv_model.dart';
import 'package:jobscope/data/models/job_model.dart';

CvModel _cv({
  List<String> skills = const [],
  String? experienceLevel,
  String? educationLevel,
}) =>
    CvModel(
      uid: 'u1',
      fileUrl: '',
      fileName: 'profile',
      uploadedAt: DateTime(2026, 6, 1),
      skills: skills,
      workExperience: const [],
      education: const [],
      experienceLevel: experienceLevel,
      educationLevel: educationLevel,
      profileStrength: 0,
    );

JobModel _job({
  List<String> skills = const ['Flutter'],
  String? experienceLevel,
  String? educationLevel,
}) =>
    JobModel(
      id: 'j1',
      recruiterId: 'r1',
      recruiterName: 'Rec',
      title: 'Developer',
      company: 'Co',
      location: 'Remote',
      jobType: 'full-time',
      description: 'Build apps',
      requirements: const [],
      skills: skills,
      experienceLevel: experienceLevel,
      educationLevel: educationLevel,
      postedAt: DateTime(2026, 6, 1),
    );

void main() {
  final matching = JobMatchingService();

  group('ProfileLevels', () {
    test('education match when candidate meets requirement', () {
      expect(
        ProfileLevels.educationMatchScore("Bachelor's", "Bachelor's"),
        100,
      );
      expect(
        ProfileLevels.educationMatchScore("Master's", "Bachelor's"),
        100,
      );
    });

    test('experience match penalizes under-qualified candidate', () {
      expect(
        ProfileLevels.experienceMatchScore('junior', 'senior'),
        35,
      );
      expect(
        ProfileLevels.experienceMatchScore('senior', 'mid'),
        100,
      );
    });
  });

  group('JobMatchingService.structuredMatchScore', () {
    test('combines skills with level requirements', () {
      final score = matching.structuredMatchScore(
        _cv(
          skills: const ['Flutter', 'Dart'],
          experienceLevel: 'mid',
          educationLevel: "Bachelor's",
        ),
        _job(
          skills: const ['Flutter', 'Dart'],
          experienceLevel: 'mid',
          educationLevel: "Bachelor's",
        ),
      );
      expect(score, greaterThanOrEqualTo(90));
    });

    test('levels-only match when no skills listed on job', () {
      final score = matching.structuredMatchScore(
        _cv(
          experienceLevel: 'senior',
          educationLevel: "Master's",
        ),
        _job(
          skills: const [],
          experienceLevel: 'mid',
          educationLevel: "Bachelor's",
        ),
      );
      expect(score, 100);
    });
  });
}
