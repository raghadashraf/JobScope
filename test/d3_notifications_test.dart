import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobscope/data/models/application_model.dart';
import 'package:jobscope/data/models/notification_model.dart';

void main() {
  group('D3 — notification model', () {
    test('parses new_application type from Firestore map', () {
      final n = AppNotificationModel.fromMap({
        'type': 'newApplication',
        'title': 'New application',
        'body': 'Alice applied to Flutter Developer (Demo).',
        'read': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 6, 5)),
        'relatedId': 'app123',
      }, docId: 'n1');

      expect(n.type, NotificationType.newApplication);
      expect(n.read, isFalse);
      expect(n.relatedId, 'app123');
    });

    test('parses legacy snake_case notification types', () {
      expect(
        AppNotificationModel.fromMap({'type': 'new_message'}).type,
        NotificationType.newMessage,
      );
      expect(
        AppNotificationModel.fromMap({'type': 'application_status'}).type,
        NotificationType.applicationStatus,
      );
      expect(
        AppNotificationModel.fromMap({'type': 'new_job'}).type,
        NotificationType.newJob,
      );
    });

    test('status notification types exclude pending/withdrawn at repo contract', () {
      expect(ApplicationStatus.pending.name, 'pending');
      expect(ApplicationStatus.withdrawn.name, 'withdrawn');
    });
  });
}
