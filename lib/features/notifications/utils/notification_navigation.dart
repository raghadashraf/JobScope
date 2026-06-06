import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/user_model.dart';
import '../../applications/data/application_providers.dart';
import '../../auth/data/auth_providers.dart';
import '../../messaging/data/messaging_providers.dart';

/// Opens the screen for [notification]. Returns `true` if navigation started.
Future<bool> openNotificationTarget(
  BuildContext context,
  WidgetRef ref,
  AppNotificationModel notification,
) async {
  try {
    switch (notification.type) {
      case NotificationType.newMessage:
        return _openMessage(context, ref, notification);

      case NotificationType.newApplication:
        return _openApplication(
          context,
          ref,
          notification,
          recruiterView: true,
        );

      case NotificationType.applicationStatus:
        return _openApplication(
          context,
          ref,
          notification,
          recruiterView: false,
        );

      case NotificationType.newJob:
        return _openJob(context, ref, notification);
    }
  } catch (e) {
    _showNavError(context, 'Could not open notification.');
    return false;
  }
}

Future<bool> _openMessage(
  BuildContext context,
  WidgetRef ref,
  AppNotificationModel notification,
) async {
  final me = ref.read(firebaseUserProvider).value;
  if (me == null) {
    _showNavError(context, 'Sign in to open messages.');
    return false;
  }

  var otherUid = notification.otherUserId?.trim() ?? '';
  if (otherUid.isEmpty) {
    _showNavError(context, 'Open Messages from the menu to continue this chat.');
    if (context.mounted) context.push(AppRoutes.conversations);
    return false;
  }

  var convId = notification.conversationIdResolved.trim();
  if (convId.isEmpty) {
    convId = buildConvId(me.uid, otherUid);
  }

  if (!context.mounted) return false;
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
  return true;
}

Future<bool> _openApplication(
  BuildContext context,
  WidgetRef ref,
  AppNotificationModel notification, {
  required bool recruiterView,
}) async {
  var appId = notification.applicationIdResolved.trim();
  if (appId.isEmpty) {
    final jobId = notification.jobIdResolved.trim();
    if (jobId.isNotEmpty) {
      return _openJobById(context, jobId);
    }
    _showNavError(context, 'This notification has no application link.');
    return false;
  }

  final app =
      await ref.read(applicationRepositoryProvider).fetchApplication(appId);
  if (!context.mounted) return false;
  if (app == null) {
    _showNavError(context, 'Application not found. It may have been removed.');
    return false;
  }

  final role = ref.read(currentUserProvider).value?.role;
  final openRecruiter =
      recruiterView || role == UserRole.recruiter;
  context.push(
    openRecruiter ? AppRoutes.applicantDetail : AppRoutes.applicationDetail,
    extra: app,
  );
  return true;
}

Future<bool> _openJob(
  BuildContext context,
  WidgetRef ref,
  AppNotificationModel notification,
) async {
  final jobId = notification.jobIdResolved.trim();
  if (jobId.isEmpty) {
    _showNavError(context, 'This notification has no job link.');
    return false;
  }
  return _openJobById(context, jobId);
}

Future<bool> _openJobById(BuildContext context, String jobId) async {
  if (!context.mounted) return false;
  context.push('/jobs/$jobId');
  return true;
}

void _showNavError(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
