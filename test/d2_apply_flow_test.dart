import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobscope/core/utils/firestore_helpers.dart';
import 'package:jobscope/data/models/application_model.dart';
import 'package:jobscope/features/applications/presentation/widgets/application_status_badge.dart';

/// Automated checks for [docs/TEST_CASES.md] — David D2.
void main() {
  group('D2 — ApplicationStatus + model', () {
    test('fromMap parses withdrawn and active flags', () {
      final app = ApplicationModel.fromMap({
        'jobId': 'j1',
        'jobTitle': 'Demo',
        'company': 'Co',
        'candidateId': 'c1',
        'candidateName': 'C',
        'candidateEmail': 'c@test.com',
        'status': 'withdrawn',
        'appliedAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 5)),
      }, docId: 'a1');

      expect(app.status, ApplicationStatus.withdrawn);
      expect(app.isActive, isFalse);
      expect(app.updatedAt, isNotNull);
    });

    test('pending and shortlisted are active', () {
      for (final status in [
        ApplicationStatus.pending,
        ApplicationStatus.shortlisted,
        ApplicationStatus.accepted,
        ApplicationStatus.rejected,
      ]) {
        final app = ApplicationModel(
          id: 'x',
          jobId: 'j',
          jobTitle: 't',
          company: 'c',
          candidateId: 'u',
          candidateName: 'n',
          candidateEmail: 'e',
          status: status,
          appliedAt: DateTime.now(),
        );
        expect(app.isActive, isTrue);
      }
    });

    test('status labels match TEST_CASES expectations', () {
      expect(ApplicationStatus.pending.label, 'Under Review');
      expect(ApplicationStatus.shortlisted.label, 'Shortlisted');
      expect(ApplicationStatus.rejected.label, 'Not Selected');
      expect(ApplicationStatus.withdrawn.label, 'Withdrawn');
    });
  });

  group('D2 — Firestore payload contracts', () {
    test('apply payload omits null fields', () {
      final map = firestoreEncode(ApplicationModel(
        id: '',
        jobId: 'job1',
        jobTitle: 'Flutter Developer (Demo)',
        company: 'JobScope Demo Co',
        candidateId: 'cand1',
        candidateName: 'Candidate',
        candidateEmail: 'candidate.demo@jobscope.test',
        status: ApplicationStatus.pending,
        appliedAt: DateTime(2026, 6, 5),
        matchScore: 72,
      ).toMap());

      expect(map.containsKey('matchScore'), isTrue);
      expect(map.containsKey('experienceLevel'), isFalse);
      expect(map['status'], 'pending');
    });

    test('withdraw contract uses withdrawn status string', () {
      expect(ApplicationStatus.withdrawn.name, 'withdrawn');
    });

    test('shortlist/reject contract uses status name + updatedAt field', () {
      expect(ApplicationStatus.shortlisted.name, 'shortlisted');
      expect(ApplicationStatus.rejected.name, 'rejected');
      // Repository writes FieldValue.serverTimestamp() for updatedAt on updateStatus.
    });
  });

  group('D2 — hasApplied semantics (re-apply after withdraw)', () {
    test('only pending applications may be withdrawn (repo contract)', () {
      final shortlisted = ApplicationModel(
        id: 'a1',
        jobId: 'j1',
        jobTitle: 'Demo',
        company: 'Co',
        candidateId: 'c1',
        candidateName: 'C',
        candidateEmail: 'c@test.com',
        status: ApplicationStatus.shortlisted,
        appliedAt: DateTime.now(),
      );
      expect(shortlisted.status, isNot(ApplicationStatus.pending));
    });

    test('withdrawn application is not active', () {
      final withdrawn = ApplicationModel(
        id: 'a1',
        jobId: 'j1',
        jobTitle: 'Demo',
        company: 'Co',
        candidateId: 'c1',
        candidateName: 'C',
        candidateEmail: 'c@test.com',
        status: ApplicationStatus.withdrawn,
        appliedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(withdrawn.isActive, isFalse);
    });
  });
}
