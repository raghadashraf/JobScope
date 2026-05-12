import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/application_model.dart';

class ApplicationStatusBadge extends StatelessWidget {
  final ApplicationStatus status;
  final bool large;

  const ApplicationStatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 8 : 6,
            height: large ? 8 : 6,
            decoration: BoxDecoration(
              color: config.dot,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: large ? 6 : 5),
          Text(
            status.label,
            style: GoogleFonts.inter(
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w600,
              color: config.text,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _config(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return _BadgeConfig(
          bg: const Color(0xFFFFFBEB),
          border: const Color(0xFFFDE68A),
          dot: const Color(0xFFF59E0B),
          text: const Color(0xFFB45309),
        );
      case ApplicationStatus.shortlisted:
        return _BadgeConfig(
          bg: AppColors.primary.withValues(alpha: 0.07),
          border: AppColors.primary.withValues(alpha: 0.2),
          dot: AppColors.primary,
          text: AppColors.primary,
        );
      case ApplicationStatus.accepted:
        return _BadgeConfig(
          bg: AppColors.success.withValues(alpha: 0.08),
          border: AppColors.success.withValues(alpha: 0.2),
          dot: AppColors.success,
          text: AppColors.success,
        );
      case ApplicationStatus.rejected:
        return _BadgeConfig(
          bg: AppColors.error.withValues(alpha: 0.07),
          border: AppColors.error.withValues(alpha: 0.2),
          dot: AppColors.error,
          text: AppColors.error,
        );
    }
  }
}

class _BadgeConfig {
  final Color bg, border, dot, text;
  const _BadgeConfig(
      {required this.bg,
      required this.border,
      required this.dot,
      required this.text});
}

// Extension to add label to ApplicationStatus
extension ApplicationStatusLabel on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Under Review';
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Not Selected';
    }
  }

  IconData get icon {
    switch (this) {
      case ApplicationStatus.pending:
        return Icons.hourglass_empty_rounded;
      case ApplicationStatus.shortlisted:
        return Icons.star_rounded;
      case ApplicationStatus.accepted:
        return Icons.check_circle_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
    }
  }
}
