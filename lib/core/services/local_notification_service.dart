import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
