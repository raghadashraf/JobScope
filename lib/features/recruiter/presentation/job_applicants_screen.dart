import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/job_model.dart';
import '../../applications/data/application_providers.dart';
import '../../applications/presentation/widgets/application_status_badge.dart';
import '../data/recruiter_providers.dart';

class JobApplicantsScreen extends ConsumerWidget {
  final JobModel job;
  const JobApplicantsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(jobApplicationsStreamProvider(job.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
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
          ),

          // ── Header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.company,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  appsAsync.when(
                    data: (apps) {
                      final shortlisted = apps
                          .where((a) =>
                              a.status == ApplicationStatus.shortlisted)
                          .length;
                      return Row(
                        children: [
                          _statChip(
                              '${apps.length} Applied', AppColors.primary),
                          const SizedBox(width: 8),
                          _statChip(
                              '$shortlisted Shortlisted', AppColors.accent),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // ── Applicant list ─────────────────────────────────────────────
          appsAsync.when(
            data: (apps) {
              if (apps.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'No applicants yet',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Applications will appear here when candidates apply.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ApplicantCard(application: apps[i]),
                  ),
                  childCount: apps.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _statChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
      );
}

// ── Applicant card ────────────────────────────────────────────────────────────
class _ApplicantCard extends ConsumerStatefulWidget {
  final ApplicationModel application;
  const _ApplicantCard({required this.application});

  @override
  ConsumerState<_ApplicantCard> createState() => _ApplicantCardState();
}

class _ApplicantCardState extends ConsumerState<_ApplicantCard> {
  bool _isUpdating = false;

  Future<void> _updateStatus(ApplicationStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await ref.read(applicationRepositoryProvider).updateStatus(
            applicationId: widget.application.id,
            status: newStatus,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final hasCV = app.cvUrl != null && app.cvUrl!.isNotEmpty;
    final canAct = app.status == ApplicationStatus.pending ||
        app.status == ApplicationStatus.shortlisted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: (app.candidatePhotoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(app.candidatePhotoUrl!)
                    : null,
                child: (app.candidatePhotoUrl?.isEmpty ?? true)
                    ? Text(
                        app.candidateName.isNotEmpty
                            ? app.candidateName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.candidateName.isNotEmpty
                          ? app.candidateName
                          : 'Unknown',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      app.candidateEmail,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ApplicationStatusBadge(status: app.status),
            ],
          ),

          const SizedBox(height: 12),

          // ── Applied date + CV ─────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                _appliedAgo(app.appliedAt),
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
              const Spacer(),
              if (hasCV)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: app.cvUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('CV link copied',
                          style: GoogleFonts.inter(color: Colors.white)),
                      backgroundColor: AppColors.secondary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 12, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'Copy CV',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ── Action buttons ────────────────────────────────────────
          if (canAct) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            if (_isUpdating)
              const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Row(
                children: [
                  if (app.status == ApplicationStatus.pending)
                    _actionBtn(
                      'Shortlist',
                      Icons.star_rounded,
                      AppColors.accent,
                      () => _updateStatus(ApplicationStatus.shortlisted),
                    ),
                  if (app.status == ApplicationStatus.shortlisted)
                    _actionBtn(
                      'Accept',
                      Icons.check_circle_rounded,
                      AppColors.success,
                      () => _updateStatus(ApplicationStatus.accepted),
                    ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    'Reject',
                    Icons.cancel_rounded,
                    AppColors.error,
                    () => _updateStatus(ApplicationStatus.rejected),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(
          String label, IconData icon, Color color, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
        ),
      );

  String _appliedAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}
