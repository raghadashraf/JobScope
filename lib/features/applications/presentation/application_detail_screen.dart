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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Company + job header ─────────────────────────────────────
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
                        application.company.isNotEmpty
                            ? application.company[0].toUpperCase()
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
                          application.jobTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.company,
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

            // ── Status card ──────────────────────────────────────────────
            _StatusCard(status: application.status),
            const SizedBox(height: 16),

            // ── Application timeline ─────────────────────────────────────
            _sectionTitle('Application Timeline'),
            const SizedBox(height: 12),
            _TimelineWidget(status: application.status),
            const SizedBox(height: 24),

            // ── Details ──────────────────────────────────────────────────
            _sectionTitle('Application Details'),
            const SizedBox(height: 12),
            _detailRow(Icons.calendar_today_rounded, 'Applied On',
                _formatDate(application.appliedAt)),
            _detailRow(Icons.person_outline_rounded, 'Applicant',
                application.candidateName),
            _detailRow(
                Icons.email_outlined, 'Email', application.candidateEmail),
            if (application.cvUrl != null)
              _detailRow(
                  Icons.description_outlined, 'CV', 'Attached'),
            const SizedBox(height: 32),

            // ── Withdraw button ───────────────────────────────────────────
            if (application.status == ApplicationStatus.pending)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: withdrawing
                      ? null
                      : () => _confirmWithdraw(context, ref),
                  icon: withdrawing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.undo_rounded, size: 18),
                  label: Text(withdrawing ? 'Withdrawing...' : 'Withdraw Application'),
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

  void _confirmWithdraw(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Withdraw Application?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to withdraw your application for ${application.jobTitle} at ${application.company}?',
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
              await ref
                  .read(withdrawNotifierProvider.notifier)
                  .withdraw(application.id);
              if (context.mounted) Navigator.pop(context);
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

// ── Status card ───────────────────────────────────────────────────────────────
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
                        fontSize: 12, color: config.text.withValues(alpha: 0.75))),
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
          description: 'You\'ve been accepted! The recruiter will contact you soon.',
        );
      case ApplicationStatus.rejected:
        return _StatusCardConfig(
          bg: AppColors.error.withValues(alpha: 0.06),
          border: AppColors.error.withValues(alpha: 0.18),
          text: AppColors.error,
          iconColor: AppColors.error,
          description: 'This application was not successful. Keep applying!',
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

// ── Timeline widget ───────────────────────────────────────────────────────────
class _TimelineWidget extends StatelessWidget {
  final ApplicationStatus status;
  const _TimelineWidget({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep('Applied', ApplicationStatus.pending),
      _TimelineStep('Under Review', ApplicationStatus.pending),
      _TimelineStep('Shortlisted', ApplicationStatus.shortlisted),
      _TimelineStep('Final Decision', ApplicationStatus.accepted),
    ];

    final currentIndex = _stepIndex(status);

    return Column(
      children: List.generate(steps.length, (i) {
        final isDone = i <= currentIndex;
        final isRejected =
            status == ApplicationStatus.rejected && i > 1;
        final isActive = i == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle + line
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRejected
                        ? AppColors.error
                        : isDone
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                    border: Border.all(
                      color: isRejected
                          ? AppColors.error
                          : isDone
                              ? AppColors.primary
                              : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isRejected
                        ? const Icon(Icons.close,
                            size: 12, color: Colors.white)
                        : isDone
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 32,
                    color: isDone && !isRejected
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRejected && i > 1 ? 'Not Selected' : steps[i].label,
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
                  if (isActive)
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

  int _stepIndex(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return 1;
      case ApplicationStatus.shortlisted:
        return 2;
      case ApplicationStatus.accepted:
        return 3;
      case ApplicationStatus.rejected:
        return 2;
    }
  }
}

class _TimelineStep {
  final String label;
  final ApplicationStatus status;
  const _TimelineStep(this.label, this.status);
}
