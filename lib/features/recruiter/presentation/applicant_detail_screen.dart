import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/job_matching_service.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/application_model.dart';
import '../../applications/data/application_providers.dart';
import '../../applications/presentation/widgets/application_status_badge.dart';
import '../../auth/data/auth_providers.dart';
import '../../job_listing/presentation/widgets/match_badge_widget.dart';
import '../../job_listing/presentation/widgets/match_reasons_sheet.dart';
import '../../../core/utils/open_file_url.dart';
import '../../messaging/data/messaging_providers.dart';
import '../data/recruiter_providers.dart';
import 'schedule_interview_sheet.dart';

class ApplicantDetailScreen extends ConsumerStatefulWidget {
  final ApplicationModel application;

  const ApplicantDetailScreen({super.key, required this.application});

  @override
  ConsumerState<ApplicantDetailScreen> createState() =>
      _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends ConsumerState<ApplicantDetailScreen> {
  bool _isUpdating = false;

  MatchCategory _categorise(int score) {
    if (score >= 80) return MatchCategory.excellent;
    if (score >= 60) return MatchCategory.good;
    if (score >= 40) return MatchCategory.fair;
    return MatchCategory.low;
  }

  String _appliedAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  Future<void> _updateStatus(ApplicationStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await ref.read(applicationRepositoryProvider).updateStatus(
            applicationId: widget.application.id,
            status: newStatus,
          );
      if (mounted) Navigator.pop(context);
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

  Widget _skillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        skill,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _cvShimmer() {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
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
      );

  @override
  Widget build(BuildContext context) {
    final liveAsync =
        ref.watch(applicationByIdProvider(widget.application.id));
    final app = liveAsync.value ?? widget.application;
    final canSchedule = app.status != ApplicationStatus.rejected &&
        app.status != ApplicationStatus.withdrawn;
    final cvAsync = ref.watch(candidateCvForApplicationProvider(app));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
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
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              app.candidateName.isNotEmpty ? app.candidateName : 'Applicant',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: (app.candidatePhotoUrl?.isNotEmpty ??
                              false)
                          ? NetworkImage(app.candidatePhotoUrl!)
                          : null,
                      child: (app.candidatePhotoUrl?.isEmpty ?? true)
                          ? Text(
                              app.candidateName.isNotEmpty
                                  ? app.candidateName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.candidateName.isNotEmpty
                                          ? app.candidateName
                                          : 'Unknown',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      app.candidateEmail,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ApplicationStatusBadge(
                                status: app.status,
                                large: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Applied ${_appliedAgo(app.appliedAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (app.matchScore != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Match Score',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      MatchBadgeWidget(
                        result: MatchResult(
                          score: app.matchScore!,
                          category: _categorise(app.matchScore!),
                        ),
                      ),
                      ...cvAsync.maybeWhen(
                        data: (cv) {
                          if (cv == null || cv.skills.isEmpty) {
                            return const <Widget>[];
                          }
                          return [
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: TextButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => MatchReasonsSheet(
                                      jobId: app.jobId,
                                      cvSkills: cv.skills,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.insights_rounded,
                                    size: 18),
                                label: const Text('Why this match?'),
                              ),
                            ),
                          ];
                        },
                        orElse: () => const <Widget>[],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.textTertiary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Match score unavailable — candidate applied without a parsed CV or before scoring was enabled.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application Documents',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (app.cvUrl != null && app.cvUrl!.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_rounded,
                            color: AppColors.primary),
                        title: Text(
                          app.cvFileName ?? 'Candidate CV',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        trailing: TextButton(
                          onPressed: () => openFileUrl(app.cvUrl!),
                          child: const Text('View CV'),
                        ),
                      )
                    else
                      Text(
                        'No CV attached to this application.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    if (app.hasCoverLetter) ...[
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded,
                              size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Cover Letter',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (app.coverLetterFileUrl != null &&
                          app.coverLetterFileUrl!.isNotEmpty)
                        TextButton.icon(
                          onPressed: () =>
                              openFileUrl(app.coverLetterFileUrl!),
                          icon: const Icon(Icons.attach_file_rounded, size: 16),
                          label: Text(app.coverLetterFileName ?? 'View file'),
                        ),
                      if (app.coverLetterText != null &&
                          app.coverLetterText!.trim().isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            app.coverLetterText!,
                            style: GoogleFonts.inter(
                                fontSize: 13, height: 1.5),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: cvAsync.when(
                  loading: () => _cvShimmer(),
                  error: (_, _) => Text(
                    'Could not load CV data.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  data: (cv) {
                    if (cv == null) {
                      return Text(
                        'No CV data available for this candidate.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skills',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (cv.skills.isEmpty)
                          Text(
                            '—',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                cv.skills.map((s) => _skillChip(s)).toList(),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Experience',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (cv.workExperience.isEmpty)
                          Text(
                            '—',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          ...cv.workExperience.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${e.title} · ${e.company}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (e.duration.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        e.duration,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (e.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        e.description,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )),
                        const SizedBox(height: 4),
                        Text(
                          'Education',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (cv.education.isEmpty)
                          Text(
                            '—',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          ...cv.education.map((ed) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${ed.degree} · ${ed.field}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ed.institution}${ed.year.isNotEmpty ? ' · ${ed.year}' : ''}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // ── Schedule Interview + Message ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  if (canSchedule) ...[
                    _actionBtn(
                      'Schedule Interview',
                      Icons.calendar_month_rounded,
                      AppColors.primary,
                      () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            ScheduleInterviewSheet(application: app),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _actionBtn(
                    'Message',
                    Icons.chat_bubble_outline_rounded,
                    AppColors.secondary,
                    () {
                      final me = ref.read(currentUserProvider).value;
                      if (me == null) return;
                      context.push(
                        AppRoutes.chat,
                        extra: ChatParams(
                          convId: buildConvId(me.uid, app.candidateId),
                          otherUid: app.candidateId,
                          otherName: app.candidateName,
                          jobTitle: app.jobTitle,
                          applicationId: app.id,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          if (app.status == ApplicationStatus.pending ||
              app.status == ApplicationStatus.shortlisted)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _isUpdating
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          if (app.status == ApplicationStatus.pending) ...[
                            _actionBtn(
                              'Shortlist',
                              Icons.star_rounded,
                              AppColors.accent,
                              () => _updateStatus(
                                  ApplicationStatus.shortlisted),
                            ),
                            const SizedBox(width: 8),
                            _actionBtn(
                              'Reject',
                              Icons.cancel_rounded,
                              AppColors.error,
                              () =>
                                  _updateStatus(ApplicationStatus.rejected),
                            ),
                          ],
                          if (app.status == ApplicationStatus.shortlisted) ...[
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
                              () =>
                                  _updateStatus(ApplicationStatus.rejected),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}
