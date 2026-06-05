import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/notification_model.dart';
import '../../applications/data/application_providers.dart';
import '../../job_listing/data/job_providers.dart';
import '../../messaging/data/messaging_providers.dart';

Future<void> openNotificationTarget(
  BuildContext context,
  WidgetRef ref,
  AppNotificationModel notification,
) async {
  switch (notification.type) {
    case NotificationType.newMessage:
      final convId = notification.conversationIdResolved;
      final otherUid = notification.otherUserId;
      if (convId.isEmpty || otherUid == null || otherUid.isEmpty) return;
      if (!context.mounted) return;
      context.push(
        AppRoutes.chat,
        extra: ChatParams(
          convId: convId,
          otherUid: otherUid,
          otherName: notification.otherUserName ?? 'User',
          jobTitle: notification.jobTitle,
          applicationId: notification.applicationId,
        ),
      );
      return;

    case NotificationType.newApplication:
      final appId = notification.applicationIdResolved;
      if (appId.isEmpty) return;
      final app =
          await ref.read(applicationRepositoryProvider).fetchApplication(appId);
      if (app == null || !context.mounted) return;
      context.push(AppRoutes.applicantDetail, extra: app);
      return;

    case NotificationType.applicationStatus:
      final appId = notification.applicationIdResolved;
      if (appId.isEmpty) return;
      final app =
          await ref.read(applicationRepositoryProvider).fetchApplication(appId);
      if (app == null || !context.mounted) return;
      context.push(AppRoutes.applicationDetail, extra: app);
      return;

    case NotificationType.newJob:
      final jobId = notification.jobIdResolved;
      if (jobId.isEmpty) return;
      final job = await ref.read(jobRepositoryProvider).fetchJob(jobId);
      if (job == null || !context.mounted) return;
      context.push(AppRoutes.jobDetail, extra: job);
      return;
  }
}
