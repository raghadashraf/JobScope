import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobscope/data/models/application_model.dart';
import 'package:jobscope/data/models/job_model.dart';
import 'package:jobscope/features/home/data/recruiter_home_providers.dart';

ApplicationModel _app(ApplicationStatus status) => ApplicationModel(
      id: 'a1',
      jobId: 'j1',
      jobTitle: 'Engineer',
      company: 'Co',
      candidateId: 'c1',
      candidateName: 'Alex',
      candidateEmail: 'a@test.com',
      status: status,
      appliedAt: DateTime(2026, 6, 1),
    );

JobModel _job({bool isActive = true, bool isDeleted = false}) => JobModel(
      id: 'j1',
      recruiterId: 'r1',
      recruiterName: 'Rec',
      title: 'Engineer',
      company: 'Co',
      location: 'Remote',
      jobType: 'full-time',
      description: 'Desc',
      requirements: const [],
      skills: const ['Flutter'],
      postedAt: DateTime(2026, 6, 1),
      isActive: isActive,
      isDeleted: isDeleted,
    );

/// Mirrors applicant-count logic in [RecruiterJobsScreen].
int applicantCountForJob(List<ApplicationModel> apps, String jobId) {
  var count = 0;
  for (final app in apps) {
    if (app.jobId != jobId) continue;
    if (!app.countsTowardJobApplicantTotal) continue;
    count++;
  }
  return count;
}

/// Mirrors visible-jobs filter in recruiter jobs list.
List<JobModel> visibleRecruiterJobs(List<JobModel> jobs) =>
    jobs.where((j) => !j.isDeleted).toList();

void main() {
  group('General — applicant counts exclude rejected/withdrawn', () {
    test('rejected does not count toward job applicant total', () {
      expect(_app(ApplicationStatus.rejected).countsTowardJobApplicantTotal,
          isFalse);
    });

    test('withdrawn does not count toward job applicant total', () {
      expect(_app(ApplicationStatus.withdrawn).countsTowardJobApplicantTotal,
          isFalse);
    });

    test('pending, shortlisted, accepted count toward total', () {
      for (final status in [
        ApplicationStatus.pending,
        ApplicationStatus.shortlisted,
        ApplicationStatus.accepted,
      ]) {
        expect(_app(status).countsTowardJobApplicantTotal, isTrue);
      }
    });

    test('per-job count skips rejected but keeps pending', () {
      final apps = [
        _app(ApplicationStatus.pending),
        _app(ApplicationStatus.rejected),
        ApplicationModel(
          id: 'a2',
          jobId: 'j2',
          jobTitle: 'Other',
          company: 'Co',
          candidateId: 'c2',
          candidateName: 'Bob',
          candidateEmail: 'b@test.com',
          status: ApplicationStatus.pending,
          appliedAt: DateTime(2026, 6, 2),
        ),
      ];
      expect(applicantCountForJob(apps, 'j1'), 1);
      expect(applicantCountForJob(apps, 'j2'), 1);
    });
  });

  group('General — job soft delete model', () {
    test('isDeleted defaults to false', () {
      expect(_job().isDeleted, isFalse);
    });

    test('fromMap parses isDeleted and round-trips in toMap', () {
      final map = _job(isActive: false, isDeleted: true).toMap();
      expect(map['isDeleted'], isTrue);
      expect(map['isActive'], isFalse);

      final parsed = JobModel.fromMap(map, docId: 'j1');
      expect(parsed.isDeleted, isTrue);
      expect(parsed.isActive, isFalse);
    });

    test('legacy Firestore docs without isDeleted stay visible', () {
      final legacy = JobModel.fromMap({
        'recruiterId': 'r1',
        'recruiterName': 'Rec',
        'title': 'Engineer',
        'company': 'Co',
        'location': 'Remote',
        'jobType': 'full-time',
        'description': 'Desc',
        'postedAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'isActive': true,
      });
      expect(legacy.isDeleted, isFalse);
    });

    test('visible recruiter jobs filter hides soft-deleted listings', () {
      final jobs = [
        _job(),
        _job(isActive: false, isDeleted: true),
        _job(isActive: false, isDeleted: false),
      ];
      final visible = visibleRecruiterJobs(jobs);
      expect(visible.length, 2);
      expect(visible.every((j) => !j.isDeleted), isTrue);
    });
  });

  group('General — recruiter tab navigation', () {
    test('recruiterTabIndexProvider selects My Jobs tab index 2', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(recruiterTabIndexProvider), 0);
      container.read(recruiterTabIndexProvider.notifier).select(2);
      expect(container.read(recruiterTabIndexProvider), 2);
    });
  });

  group('General — schedule interview guard', () {
    bool canSchedule(ApplicationStatus status) =>
        status != ApplicationStatus.rejected &&
        status != ApplicationStatus.withdrawn;

    test('rejected and withdrawn cannot schedule interview', () {
      expect(canSchedule(ApplicationStatus.rejected), isFalse);
      expect(canSchedule(ApplicationStatus.withdrawn), isFalse);
    });

    test('pending and shortlisted can schedule interview', () {
      expect(canSchedule(ApplicationStatus.pending), isTrue);
      expect(canSchedule(ApplicationStatus.shortlisted), isTrue);
      expect(canSchedule(ApplicationStatus.accepted), isTrue);
    });
  });
}
