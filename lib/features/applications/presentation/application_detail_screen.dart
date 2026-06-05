import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../data/application_providers.dart';
import 'widgets/application_status_badge.dart';

class ApplicationDetailScreen extends ConsumerWidget {
  final ApplicationModel application;
  const ApplicationDetailScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(applicationByIdProvider(application.id));
    final app = liveAsync.value ?? application;
    final withdrawing = ref.watch(withdrawNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Application Details',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: false,
        actions: [
          if (app.canWithdraw)
            IconButton(
              tooltip: 'Withdraw application',
              onPressed: withdrawing
                  ? null
                  : () => _confirmWithdraw(context, ref, app),
              icon: withdrawing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.undo_rounded, color: AppColors.error),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Center(
                      child: Text(
                        app.company.isNotEmpty
                            ? app.company[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.jobTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.company,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _StatusCard(status: app.status),
            const SizedBox(height: 16),
            _sectionTitle('Application Timeline'),
            const SizedBox(height: 12),
            _TimelineWidget(application: app),
            const SizedBox(height: 24),
            _sectionTitle('Application Details'),
            const SizedBox(height: 12),
            _detailRow(Icons.calendar_today_rounded, 'Applied On',
                _formatDate(app.appliedAt)),
            if (app.updatedAt != null &&
                app.status != ApplicationStatus.pending)
              _detailRow(Icons.update_rounded, 'Last Updated',
                  _formatDate(app.updatedAt!)),
            _detailRow(Icons.person_outline_rounded, 'Applicant',
                app.candidateName),
            _detailRow(Icons.email_outlined, 'Email', app.candidateEmail),
            if (app.cvUrl != null)
              _detailRow(Icons.description_outlined, 'CV', 'Attached'),
            const SizedBox(height: 32),
            if (app.canWithdraw)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: withdrawing
                      ? null
                      : () => _confirmWithdraw(context, ref, app),
                  icon: withdrawing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.undo_rounded, size: 18),
                  label: Text(withdrawing
                      ? 'Withdrawing...'
                      : 'Withdraw (Under Review only)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textTertiary)),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmWithdraw(
      BuildContext context, WidgetRef ref, ApplicationModel app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Withdraw Application?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Your application for ${app.jobTitle} at ${app.company} will be marked withdrawn. You can apply again later.',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await ref
                  .read(withdrawNotifierProvider.notifier)
                  .withdraw(app.id);
              if (!context.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0),
            child: Text('Withdraw', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _StatusCard extends StatelessWidget {
  final ApplicationStatus status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(status.icon, color: config.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: config.text,
                    )),
                const SizedBox(height: 2),
                Text(config.description,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: config.text.withValues(alpha: 0.75))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusCardConfig _statusConfig(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return _StatusCardConfig(
          bg: const Color(0xFFFFFBEB),
          border: const Color(0xFFFDE68A),
          text: const Color(0xFFB45309),
          iconColor: const Color(0xFFF59E0B),
          description: 'Your application is being reviewed by the recruiter.',
        );
      case ApplicationStatus.shortlisted:
        return _StatusCardConfig(
          bg: AppColors.primary.withValues(alpha: 0.06),
          border: AppColors.primary.withValues(alpha: 0.18),
          text: AppColors.primary,
          iconColor: AppColors.primary,
          description: 'Congratulations! You\'ve been shortlisted.',
        );
      case ApplicationStatus.accepted:
        return _StatusCardConfig(
          bg: AppColors.success.withValues(alpha: 0.07),
          border: AppColors.success.withValues(alpha: 0.2),
          text: AppColors.success,
          iconColor: AppColors.success,
          description:
              'You\'ve been accepted! The recruiter will contact you soon.',
        );
      case ApplicationStatus.rejected:
        return _StatusCardConfig(
          bg: AppColors.error.withValues(alpha: 0.06),
          border: AppColors.error.withValues(alpha: 0.18),
          text: AppColors.error,
          iconColor: AppColors.error,
          description: 'This application was not successful. Keep applying!',
        );
      case ApplicationStatus.withdrawn:
        return _StatusCardConfig(
          bg: AppColors.surfaceVariant,
          border: AppColors.border,
          text: AppColors.textSecondary,
          iconColor: AppColors.textTertiary,
          description: 'You withdrew this application. You may apply again.',
        );
    }
  }
}

class _StatusCardConfig {
  final Color bg, border, text, iconColor;
  final String description;
  const _StatusCardConfig({
    required this.bg,
    required this.border,
    required this.text,
    required this.iconColor,
    required this.description,
  });
}

class _TimelineWidget extends StatelessWidget {
  final ApplicationModel application;
  const _TimelineWidget({required this.application});

  @override
  Widget build(BuildContext context) {
    final status = application.status;
    final steps = <_TimelineStepData>[
      _TimelineStepData(
        label: 'Applied',
        date: application.appliedAt,
        reached: true,
      ),
      _TimelineStepData(
        label: 'Under Review',
        date: status == ApplicationStatus.pending
            ? null
            : application.updatedAt,
        reached: status != ApplicationStatus.withdrawn,
      ),
      _TimelineStepData(
        label: status == ApplicationStatus.rejected
            ? 'Not Selected'
            : 'Shortlisted',
        date: _statusDate(
          status,
          const {
            ApplicationStatus.shortlisted,
            ApplicationStatus.accepted,
            ApplicationStatus.rejected,
          },
        ),
        reached: const {
          ApplicationStatus.shortlisted,
          ApplicationStatus.accepted,
          ApplicationStatus.rejected,
        }.contains(status),
      ),
      _TimelineStepData(
        label: status == ApplicationStatus.withdrawn
            ? 'Withdrawn'
            : 'Final Decision',
        date: _statusDate(
          status,
          const {
            ApplicationStatus.accepted,
            ApplicationStatus.rejected,
            ApplicationStatus.withdrawn,
          },
        ),
        reached: const {
          ApplicationStatus.accepted,
          ApplicationStatus.rejected,
          ApplicationStatus.withdrawn,
        }.contains(status),
      ),
    ];

    final currentIndex = steps.lastIndexWhere((s) => s.reached);
    final isRejected = status == ApplicationStatus.rejected;
    final isWithdrawn = status == ApplicationStatus.withdrawn;

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isDone = step.reached;
        final isActive = i == currentIndex;
        final showRejectStyle = isRejected && i >= 2;
        final showWithdrawStyle = isWithdrawn && i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: showRejectStyle || showWithdrawStyle
                        ? (showWithdrawStyle
                            ? AppColors.textTertiary
                            : AppColors.error)
                        : isDone
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                    border: Border.all(
                      color: showRejectStyle || showWithdrawStyle
                          ? (showWithdrawStyle
                              ? AppColors.textTertiary
                              : AppColors.error)
                          : isDone
                              ? AppColors.primary
                              : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: showRejectStyle || showWithdrawStyle
                        ? Icon(
                            showWithdrawStyle
                                ? Icons.undo_rounded
                                : Icons.close,
                            size: 12,
                            color: Colors.white,
                          )
                        : isDone
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isDone && !showRejectStyle
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.textPrimary
                          : isDone
                              ? AppColors.textSecondary
                              : AppColors.textTertiary,
                    ),
                  ),
                  if (step.date != null)
                    Text(_formatDate(step.date!),
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textTertiary)),
                  if (isActive && step.date == null)
                    Text('Current stage',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  DateTime? _statusDate(
      ApplicationStatus current, Set<ApplicationStatus> match) {
    if (!match.contains(current)) return null;
    return application.updatedAt ?? application.appliedAt;
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _TimelineStepData {
  final String label;
  final DateTime? date;
  final bool reached;
  const _TimelineStepData({
    required this.label,
    required this.date,
    required this.reached,
  });
}
