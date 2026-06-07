import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/training_session_model.dart';
import '../../../data/models/user_model.dart';
import '../data/job_providers.dart';
import '../../auth/data/auth_providers.dart';
import '../../applications/data/application_providers.dart';
import '../../ai_features/data/ai_providers.dart';
import '../../cv_management/data/cv_providers.dart';
import '../../applications/data/application_draft_providers.dart';
import '../../../data/models/application_draft_model.dart';
import '../../../data/models/cv_model.dart';
import '../../../core/services/share_service.dart';
import 'widgets/cover_letter_sheet.dart';
import 'widgets/match_badge_widget.dart';
import 'widgets/match_reasons_sheet.dart';
import 'widgets/train_before_apply_sheet.dart';
import '../../ai_features/data/training_providers.dart';

class JobDetailScreen extends ConsumerWidget {
  final JobModel job;
  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cvs = ref.watch(userCvsStreamProvider).value ?? [];
    final cv = ref.watch(cvStreamProvider).value;
    final draft = ref.watch(applicationDraftProvider(job.id)).value;
    final bookmarkedIds = ref.watch(bookmarkedIdsProvider).value ?? {};
    final isBookmarked = bookmarkedIds.contains(job.id);
    final user = ref.watch(firebaseUserProvider).value;

    // Real-time check: has this user already applied?
    final hasAppliedAsync = ref.watch(hasAppliedProvider(job.id));
    final hasApplied = hasAppliedAsync.value ?? false;

    // Apply action state
    final applyState = ref.watch(applyNotifierProvider);

    final currentUser = ref.watch(currentUserProvider).value;
    final isCandidate = currentUser?.role == UserRole.candidate;
    final trainingAsync = isCandidate
        ? ref.watch(latestCompletedTrainingProvider(job.id))
        : const AsyncValue<TrainingSessionModel?>.data(null);
    final completedTraining = trainingAsync.value;
    final trainingBlocksApply = completedTraining != null &&
        !completedTraining.canApply;

    // AI match score (only shown when CV is uploaded)
    final matchResult = ref.watch(jobMatchResultProvider(job.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
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
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.textPrimary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Share button
              GestureDetector(
                onTap: () => ShareService().shareJob(job),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.share_rounded,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
              // Bookmark button
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    if (user != null) {
                      ref
                          .read(bookmarkNotifierProvider.notifier)
                          .toggle(job.id, isBookmarked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color: isBookmarked
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Company header ───────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Center(
                          child: Text(
                            job.company.isNotEmpty
                                ? job.company[0].toUpperCase()
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
                              job.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job.company,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Match Score card ─────────────────────────────────────
                  if (matchResult != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Match Score',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            MatchBadgeWidget(result: matchResult),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => SizedBox(
                                    height:
                                        MediaQuery.of(ctx).size.height * 0.92,
                                    child: MatchReasonsSheet(
                                      jobId: job.id,
                                      cvSkills: cv?.skills ?? [],
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'See match reasons',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Already applied banner ───────────────────────────────
                  if (hasApplied) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You\'ve already applied to this job',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Info chips ───────────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.location_on_outlined, job.location,
                          AppColors.primary),
                      _infoChip(Icons.work_outline_rounded,
                          _fmt(job.jobType), AppColors.secondary),
                      if (job.salaryMin != null || job.salaryMax != null)
                        _infoChip(Icons.payments_outlined, job.salaryRange,
                            AppColors.success),
                      _infoChip(Icons.access_time_rounded, job.postedAgo,
                          AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Description ──────────────────────────────────────────
                  _sectionHeader('Job Description'),
                  const SizedBox(height: 10),
                  Text(
                    job.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Requirements ─────────────────────────────────────────
                  if (job.requirements.isNotEmpty) ...[
                    _sectionHeader('Requirements'),
                    const SizedBox(height: 10),
                    ...job.requirements.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(
                                    top: 6, right: 10),
                                decoration: BoxDecoration(
          color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  r,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // ── Required Skills ──────────────────────────────────────
                  if (job.skills.isNotEmpty) ...[
                    _sectionHeader('Required Skills'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.skills
                          .map((skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.15)),
                                ),
                                child: Text(
                                  skill,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom bar ────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCandidate && !hasApplied) ...[
              if (cvs.isNotEmpty) ...[
                _CvSelector(
                  jobId: job.id,
                  cvs: cvs,
                  draft: draft,
                ),
                const SizedBox(height: 10),
              ],
              if (draft != null && (draft.hasCv || draft.hasCoverLetter)) ...[
                _AttachmentSummary(draft: draft),
                const SizedBox(height: 10),
              ],
              if (completedTraining != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (completedTraining.canApply
                            ? AppColors.success
                            : AppColors.warning)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (completedTraining.canApply
                              ? AppColors.success
                              : AppColors.warning)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    completedTraining.canApply
                        ? 'Training passed (${completedTraining.readinessScore}%) — ready to apply'
                        : 'Training score ${completedTraining.readinessScore}% — need ${TrainingSessionModel.minReadinessToApply}%+ to apply',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: completedTraining.canApply
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showTrainBeforeApplySheet(context, job),
                  icon: const Icon(Icons.school_rounded, size: 18),
                  label: Text(
                    AppStrings.trainBeforeApply,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
            // Cover Letter button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showCoverLetterSheet(context, ref, cvs, draft),
                icon: const Icon(Icons.description_outlined, size: 17),
                label: Text(
                  'Cover Letter',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Apply / Already Applied button
            Expanded(
              child: hasApplied
                  ? _AlreadyAppliedButton()
                  : ElevatedButton(
                      onPressed: applyState.status == ApplyStatus.loading
                          ? null
                          : trainingBlocksApply
                              ? () => _showTrainingRequired(context)
                              : () => _showApplyConfirm(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: applyState.status == ApplyStatus.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Apply Now',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                    ),
            ),
          ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTrainingRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Complete training with ${TrainingSessionModel.minReadinessToApply}%+ readiness to apply.',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Train',
          textColor: Colors.white,
          onPressed: () => showTrainBeforeApplySheet(context, job),
        ),
      ),
    );
  }

  void _showApplyConfirm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppColors.success, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Apply to ${job.company}?',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Your CV and profile will be sent to ${job.company} for the ${job.title} position.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ref.read(applyNotifierProvider.notifier).apply(
                            jobId: job.id,
                            jobTitle: job.title,
                            company: job.company,
                          );

                      if (!context.mounted) return;
                      final state = ref.read(applyNotifierProvider);

                      if (state.status == ApplyStatus.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                      'Applied to ${job.title} at ${job.company}!')),
                            ]),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        ref.read(applyNotifierProvider.notifier).reset();
                      } else if (state.status == ApplyStatus.error ||
                          state.status == ApplyStatus.alreadyApplied) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                state.errorMessage ?? 'Something went wrong'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        ref.read(applyNotifierProvider.notifier).reset();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Confirm',
                        style:
                            GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCoverLetterSheet(
    BuildContext context,
    WidgetRef ref,
    List<CvModel> cvs,
    draft,
  ) {
    final selected = _resolveSelectedCv(cvs, draft);
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Expanded(
                child: Text(
                    'Please upload a CV first (Profile → My CV)')),
          ]),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: CoverLetterSheet(
          jobId: job.id,
          jobTitle: job.title,
          company: job.company,
          jobDescription: job.description,
          selectedCv: selected,
        ),
      ),
    );
  }

  CvModel? _resolveSelectedCv(
      List<CvModel> cvs, ApplicationDraftModel? draft) {
    if (draft?.cvId != null) {
      for (final c in cvs) {
        if (c.id == draft!.cvId) return c;
      }
    }
    return cvs.isNotEmpty ? cvs.first : null;
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  String _fmt(String type) {
    switch (type.toLowerCase()) {
      case 'full-time':
        return 'Full-time';
      case 'part-time':
        return 'Part-time';
      case 'remote':
        return 'Remote';
      case 'contract':
        return 'Contract';
      default:
        return type;
    }
  }
}

class _CvSelector extends ConsumerStatefulWidget {
  final String jobId;
  final List<CvModel> cvs;
  final ApplicationDraftModel? draft;

  const _CvSelector({
    required this.jobId,
    required this.cvs,
    required this.draft,
  });

  @override
  ConsumerState<_CvSelector> createState() => _CvSelectorState();
}

class _CvSelectorState extends ConsumerState<_CvSelector> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDefaultCv());
  }

  Future<void> _ensureDefaultCv() async {
    if (_initialized || widget.cvs.isEmpty) return;
    if (widget.draft?.cvId != null) {
      _initialized = true;
      return;
    }
    final cv = widget.cvs.first;
    await ref.read(applicationDraftNotifierProvider.notifier).saveCvSelection(
          jobId: widget.jobId,
          cvId: cv.id,
          cvUrl: cv.fileUrl,
          cvFileName: cv.fileName,
        );
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final cvs = widget.cvs;
    final selectedId = draft?.cvId ?? (cvs.isNotEmpty ? cvs.first.id : '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: cvs.any((c) => c.id == selectedId) ? selectedId : cvs.first.id,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, size: 20),
          items: cvs
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      c.fileName.isNotEmpty ? c.fileName : 'CV ${c.id.substring(0, 6)}',
                      style: GoogleFonts.inter(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            final cv = cvs.firstWhere((c) => c.id == id);
            ref
                .read(applicationDraftNotifierProvider.notifier)
                .saveCvSelection(
                  jobId: widget.jobId,
                  cvId: cv.id,
                  cvUrl: cv.fileUrl,
                  cvFileName: cv.fileName,
                );
          },
        ),
      ),
    );
  }
}

class _AttachmentSummary extends StatelessWidget {
  final ApplicationDraftModel draft;
  const _AttachmentSummary({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attached to this application',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          if (draft.hasCv)
            Row(children: [
              const Icon(Icons.description_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CV: ${draft.cvFileName ?? 'Selected CV'}',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          if (draft.hasCoverLetter) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.mail_outline_rounded,
                  size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  draft.coverLetterFileName != null
                      ? 'Cover letter: ${draft.coverLetterFileName}'
                      : 'Cover letter: ${draft.coverLetterText!.length > 40 ? '${draft.coverLetterText!.substring(0, 40)}…' : draft.coverLetterText}',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ── Already applied button ────────────────────────────────────────────────────
class _AlreadyAppliedButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Text(
            'Applied',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
