import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../data/cv_providers.dart';
import '../../../data/models/cv_model.dart';

class CvScreen extends ConsumerWidget {
  const CvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cvAsync = ref.watch(cvStreamProvider);
    final uploadState = ref.watch(cvUploadProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My CV',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Upload status messages ────────────────────────────────────
            if (uploadState.status == CvUploadStatus.uploading ||
                uploadState.status == CvUploadStatus.parsing)
              _UploadProgressCard(status: uploadState.status),

            if (uploadState.status == CvUploadStatus.error)
              _ErrorCard(
                message: uploadState.errorMessage ?? 'An error occurred',
                onDismiss: () =>
                    ref.read(cvUploadProvider.notifier).reset(),
              ),

            if (uploadState.status == CvUploadStatus.done)
              _SuccessBanner(
                onDismiss: () =>
                    ref.read(cvUploadProvider.notifier).reset(),
              ),

            // ── CV content ────────────────────────────────────────────────
            cvAsync.when(
              data: (cv) => cv == null
                  ? _EmptyState(
                      onUpload: () =>
                          ref.read(cvUploadProvider.notifier).pickAndUpload(),
                      isLoading:
                          uploadState.status != CvUploadStatus.idle &&
                              uploadState.status != CvUploadStatus.error &&
                              uploadState.status != CvUploadStatus.done,
                    )
                  : _CvContent(
                      cv: cv,
                      onReplace: () =>
                          ref.read(cvUploadProvider.notifier).pickAndUpload(),
                      isLoading:
                          uploadState.status != CvUploadStatus.idle &&
                              uploadState.status != CvUploadStatus.error &&
                              uploadState.status != CvUploadStatus.done,
                    ),
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style:
                          const TextStyle(color: AppColors.error))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state: no CV yet ────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onUpload;
  final bool isLoading;
  const _EmptyState({required this.onUpload, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_outlined,
                size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text('No CV uploaded yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Upload your CV to let AI parse your skills, experience and education automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          _UploadButton(onTap: onUpload, isLoading: isLoading),
          const SizedBox(height: 12),
          Text('Supports PDF and DOCX',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

// ── CV content: shows parsed data ────────────────────────────────────────────
class _CvContent extends StatelessWidget {
  final CvModel cv;
  final VoidCallback onReplace;
  final bool isLoading;

  const _CvContent(
      {required this.cv, required this.onReplace, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile strength card
        _ProfileStrengthCard(strength: cv.profileStrength),
        const SizedBox(height: 20),

        // File info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cv.fileName,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                        'Uploaded ${_formatDate(cv.uploadedAt)}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              _UploadButton(
                  onTap: onReplace,
                  isLoading: isLoading,
                  isCompact: true,
                  label: 'Replace'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Skills section
        if (cv.skills.isNotEmpty) ...[
          _sectionTitle('Skills', Icons.psychology_rounded, AppColors.primary),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cv.skills
                .map((s) => _SkillChip(label: s))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Work experience
        if (cv.workExperience.isNotEmpty) ...[
          _sectionTitle('Work Experience', Icons.work_rounded,
              AppColors.secondary),
          const SizedBox(height: 12),
          ...cv.workExperience
              .map((e) => _ExperienceCard(experience: e)),
          const SizedBox(height: 24),
        ],

        // Education
        if (cv.education.isNotEmpty) ...[
          _sectionTitle(
              'Education', Icons.school_rounded, AppColors.accent),
          const SizedBox(height: 12),
          ...cv.education.map((e) => _EducationCard(education: e)),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ── Profile strength card ─────────────────────────────────────────────────────
class _ProfileStrengthCard extends StatelessWidget {
  final int strength;
  const _ProfileStrengthCard({required this.strength});

  @override
  Widget build(BuildContext context) {
    String strengthLabel;
    if (strength < 40) {
      strengthLabel = 'Needs Improvement';
    } else if (strength < 70) {
      strengthLabel = 'Good';
    } else {
      strengthLabel = 'Excellent';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile Strength',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(strengthLabel,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$strength',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  )),
              Text('%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          )),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final WorkExperience experience;
  const _ExperienceCard({required this.experience});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business_rounded,
                color: AppColors.secondary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(experience.title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(experience.company,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(experience.duration,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textTertiary)),
                if (experience.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(experience.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  final Education education;
  const _EducationCard({required this.education});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${education.degree} in ${education.field}',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(education.institution,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(education.year,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared upload button ──────────────────────────────────────────────────────
class _UploadButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final bool isCompact;
  final String label;

  const _UploadButton({
    required this.onTap,
    required this.isLoading,
    this.isCompact = false,
    this.label = 'Upload CV',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
          width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.upload_file_rounded,
          size: isCompact ? 14 : 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: isCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 10 : 14)),
        textStyle: GoogleFonts.inter(
            fontSize: isCompact ? 12 : 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Upload progress card ──────────────────────────────────────────────────────
class _UploadProgressCard extends StatelessWidget {
  final CvUploadStatus status;
  const _UploadProgressCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final msg = status == CvUploadStatus.uploading
        ? 'Uploading your CV...'
        : 'AI is parsing your CV...';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary)),
          const SizedBox(width: 14),
          Text(msg,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorCard({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.error))),
          GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 18, color: AppColors.error)),
        ],
      ),
    );
  }
}

// ── Success banner ────────────────────────────────────────────────────────────
class _SuccessBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _SuccessBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text('CV uploaded and parsed successfully!',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.success,
                      fontWeight: FontWeight.w500))),
          GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close,
                  size: 18, color: AppColors.success)),
        ],
      ),
    );
  }
}
