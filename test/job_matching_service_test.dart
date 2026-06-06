import 'package:flutter_test/flutter_test.dart';
import 'package:jobscope/core/services/job_matching_service.dart';
import 'package:jobscope/data/models/cv_model.dart';
import 'package:jobscope/data/models/job_model.dart';

CvModel _cv(List<String> skills) => CvModel(
      uid: 'u1',
      fileName: 'cv.pdf',
      fileUrl: 'https://example.com/cv.pdf',
      uploadedAt: DateTime(2026, 6, 1),
      skills: skills,
      workExperience: const [],
      education: const [],
      profileStrength: 80,
    );

JobModel _job({List<String> skills = const ['Flutter', 'Dart', 'Firebase']}) =>
    JobModel(
      id: 'j1',
      recruiterId: 'r1',
      recruiterName: 'Rec',
      title: 'Flutter Developer',
      company: 'Co',
      location: 'Remote',
      jobType: 'full-time',
      description: 'Build mobile apps',
      requirements: const [],
      skills: skills,
      postedAt: DateTime(2026, 6, 1),
    );

void main() {
  final service = JobMatchingService();

  group('JobMatchingService.skillOverlapScore', () {
    test('full overlap returns 100', () {
      expect(
        service.skillOverlapScore(
          _cv(['Flutter', 'Dart', 'Firebase']),
          _job(),
        ),
        100,
      );
    });

    test('partial overlap returns proportional score', () {
      expect(
        service.skillOverlapScore(
          _cv(['Flutter']),
          _job(),
        ),
        33,
      );
    });

    test('no cv skills returns 0', () {
      expect(service.skillOverlapScore(_cv([]), _job()), 0);
    });

    test('fuzzy match handles case and substring', () {
      expect(
        service.skillOverlapScore(
          _cv(['flutter development']),
          _job(skills: const ['Flutter']),
        ),
        100,
      );
    });
  });

  group('JobMatchingService.categorise', () {
    test('maps score bands to categories', () {
      expect(service.categorise(85), MatchCategory.excellent);
      expect(service.categorise(70), MatchCategory.good);
      expect(service.categorise(50), MatchCategory.fair);
      expect(service.categorise(20), MatchCategory.low);
    });
  });
}
