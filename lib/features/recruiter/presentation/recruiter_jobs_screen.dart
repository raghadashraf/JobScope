import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/job_model.dart';
import '../../job_listing/data/job_providers.dart';
import '../../home/presentation/post_job_screen.dart';
import '../data/recruiter_providers.dart';
import 'job_applicants_screen.dart';

class RecruiterJobsScreen extends ConsumerWidget {
  const RecruiterJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(recruiterJobsStreamProvider);
    final allApps = ref.watch(recruiterAllApplicationsStreamProvider).value ?? [];

    final countByJob = <String, int>{};
    for (final app in allApps) {
      countByJob[app.jobId] = (countByJob[app.jobId] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Jobs',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  jobsAsync.when(
                    data: (jobs) {
                      final active = jobs.where((j) => j.isActive).length;
                      return Text(
                        '$active active · ${jobs.length} total',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textSecondary),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── List ─────────────────────────────────────────────────────
            Expanded(
              child: jobsAsync.when(
                data: (jobs) => jobs.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: jobs.length,
                        itemBuilder: (_, i) => _JobCard(
                          job: jobs[i],
                          applicantCount: countByJob[jobs[i].id] ?? 0,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  JobApplicantsScreen(job: jobs[i]),
                            ),
                          ),
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PostJobScreen(jobToEdit: jobs[i]),
                            ),
                          ),
                          onToggleActive: () => jobs[i].isActive
                              ? _confirmDeactivate(context, ref, jobs[i].id)
                              : _reactivate(context, ref, jobs[i]),
                        ),
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeactivate(
      BuildContext context, WidgetRef ref, String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Deactivate Job?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(
          'Candidates will no longer see this listing.',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Deactivate',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(jobRepositoryProvider).deactivateJob(jobId);
    }
  }

  Future<void> _reactivate(
      BuildContext context, WidgetRef ref, JobModel job) async {
    await ref.read(jobRepositoryProvider).updateJob(
          JobModel(
            id: job.id,
            recruiterId: job.recruiterId,
            recruiterName: job.recruiterName,
            recruiterPhotoUrl: job.recruiterPhotoUrl,
            title: job.title,
            company: job.company,
            location: job.location,
            jobType: job.jobType,
            description: job.description,
            requirements: job.requirements,
            skills: job.skills,
            salaryMin: job.salaryMin,
            salaryMax: job.salaryMax,
            salaryCurrency: job.salaryCurrency,
            postedAt: job.postedAt,
            isActive: true,
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job reactivated',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.work_outline_rounded,
                  size: 40, color: AppColors.secondary),
            ),
            const SizedBox(height: 20),
            Text(
              'No jobs posted yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Post Job" to create your first listing.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Job card ─────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final JobModel job;
  final int applicantCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _JobCard({
    required this.job,
    required this.applicantCount,
    required this.onTap,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: job.isActive
                ? AppColors.border
                : AppColors.border.withValues(alpha: 0.5),
          ),
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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      job.company.isNotEmpty
                          ? job.company[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: job.isActive
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${job.company} · ${job.location}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_Action>(
                  onSelected: (a) =>
                      a == _Action.edit ? onEdit() : onToggleActive(),
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 20, color: AppColors.textTertiary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _Action.edit,
                      child: Row(children: [
                        const Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text('Edit', style: GoogleFonts.inter(fontSize: 14)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: _Action.toggle,
                      child: Row(children: [
                        Icon(
                          job.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 16,
                          color: job.isActive
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          job.isActive ? 'Deactivate' : 'Reactivate',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: job.isActive
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _tag(
                  job.isActive ? 'Active' : 'Inactive',
                  job.isActive ? AppColors.success : AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                _tag(_fmtType(job.jobType), AppColors.secondary),
                const Spacer(),
                const Icon(Icons.people_outline_rounded,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '$applicantCount applicant${applicantCount != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      );

  String _fmtType(String type) {
    switch (type.toLowerCase()) {
      case 'full-time': return 'Full-time';
      case 'part-time': return 'Part-time';
      case 'remote':    return 'Remote';
      case 'contract':  return 'Contract';
      default:          return type;
    }
  }
}

enum _Action { edit, toggle }
