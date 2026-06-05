import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> showStatusChange({
    required String jobTitle,
    required String company,
    required String newStatus,
  }) async {
    final (title, body) = _buildContent(jobTitle, company, newStatus);
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'application_status',
          'Application Status',
          channelDescription:
              'Updates on your job application status',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showInboxAlert({
    required String title,
    required String body,
  }) async {
    if (body.isEmpty) return;
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'inbox_notifications',
          'Inbox',
          channelDescription: 'JobScope inbox and push alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showInterviewConfirmed({
    required String jobTitle,
    required String company,
    required DateTime slot,
  }) async {
    final formatted = DateFormat('EEE, MMM d · h:mm a').format(slot);
    await _plugin.show(
      id: slot.millisecondsSinceEpoch ~/ 1000,
      title: 'Interview Confirmed! 🎉',
      body: '$jobTitle at $company — $formatted',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'interview_notifications',
          'Interview Notifications',
          channelDescription: 'Interview scheduling confirmations',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  (String, String) _buildContent(
      String jobTitle, String company, String status) {
    switch (status.toLowerCase()) {
      case 'shortlisted':
        return (
          'Shortlisted!',
          'You\'ve been shortlisted for $jobTitle at $company.'
        );
      case 'accepted':
        return (
          'Offer Received!',
          'Congratulations! $company accepted your application for $jobTitle.'
        );
      case 'rejected':
        return (
          'Application Update',
          'Your application for $jobTitle at $company was not selected.'
        );
      default:
        return (
          'Application Update',
          'Your $jobTitle application at $company has been updated.'
        );
    }
  }
}
