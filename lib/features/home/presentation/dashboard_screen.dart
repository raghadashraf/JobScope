import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/application_model.dart';
import '../../auth/data/auth_providers.dart';
import '../../applications/data/application_providers.dart';
import '../../cv_management/data/cv_providers.dart';
import '../../ai_features/data/ai_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  static const _sections = 5;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnims = List.generate(_sections, (i) {
      final start = i * 0.12;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(_sections, (i) {
      final start = i * 0.12;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween(begin: const Offset(0, 0.18), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic)),
      );
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) => FadeTransition(
        opacity: _fadeAnims[index],
        child: SlideTransition(position: _slideAnims[index], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final cvAsync = ref.watch(cvStreamProvider);
    final uploadState = ref.watch(cvUploadProvider);
    final appsAsync = ref.watch(myApplicationsProvider);
    final apps = appsAsync.value ?? const <ApplicationModel>[];
    final appliedCount = apps.length;
    final shortlistedCount =
        apps.where((a) => a.status == ApplicationStatus.shortlisted).length;
    final hasCv = cvAsync.value != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting ─────────────────────────────────────────
                    _animated(
                      0,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              userAsync.when(
                                data: (user) => Text(
                                  user?.name ?? 'Welcome back',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                loading: () => _shimmer(150, 26),
                                error: (_, e) => Text('Welcome',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800)),
                              ),
                              if (userAsync.value?.headline != null &&
                                  userAsync.value!.headline!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  userAsync.value!.headline!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          _notificationBell(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── CV / AI Builder card ──────────────────────────────
                    _animated(
                      1,
                      cvAsync.when(
                        data: (cv) => _cvCard(
                          context: context,
                          ref: ref,
                          strength: cv?.profileStrength ?? 0,
                          hasCv: cv != null,
                          isUploading:
                              uploadState.status != CvUploadStatus.idle &&
                              uploadState.status != CvUploadStatus.error &&
                              uploadState.status != CvUploadStatus.done,
                        ),
                        loading: () => _shimmer(double.infinity, 200),
                        error: (_, e) => _cvCard(
                            context: context,
                            ref: ref,
                            strength: 0,
                            hasCv: false,
                            isUploading: false),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Stats row ─────────────────────────────────────────
                    _animated(
                      2,
                      Row(
                        children: [
                          Expanded(
                              child: _statCard(
                                  icon: Icons.work_rounded,
                                  label: 'Job Matches',
                                  value: '–',
                                  color: AppColors.primary)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _statCard(
                                  icon: Icons.send_rounded,
                                  label: 'Applied',
                                  value: '$appliedCount',
                                  color: AppColors.secondary)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _statCard(
                                  icon: Icons.check_circle_rounded,
                                  label: 'Shortlisted',
                                  value: '$shortlistedCount',
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Quick actions header ──────────────────────────────
                    _animated(
                      3,
                      Text('Quick Actions',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4)),
                    ),
                    const SizedBox(height: 14),

                    // ── Action tiles ─────────────────────────────────────
                    _animated(
                      4,
                      Column(
                        children: [
                          if (!hasCv)
                            _actionTile(
                              icon: Icons.auto_fix_high_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              ),
                              title: 'Build CV with AI',
                              subtitle: 'Let AI create your professional CV',
                              badge: 'New',
                              onTap: () =>
                                  context.push(AppRoutes.aiCvBuilder),
                            ),
                          if (!hasCv) const SizedBox(height: 12),
                          _actionTile(
                            icon: Icons.psychology_rounded,
                            iconColor: AppColors.primary,
                            title: 'Train with AI Questions',
                            subtitle: 'Practice scenario-based interviews',
                            onTap: () {
                              final cv = cvAsync.value;
                              final params = InterviewParams(
                                jobTitle: 'Software Engineer',
                                skills: cv?.skills ?? const [],
                              );
                              context.push(AppRoutes.interviewTraining,
                                  extra: params);
                            },
                          ),
                          const SizedBox(height: 12),
                          _actionTile(
                            icon: Icons.search_rounded,
                            iconColor: AppColors.secondary,
                            title: 'Browse Jobs',
                            subtitle: 'Find your perfect match',
                            onTap: () => context.push(AppRoutes.jobs),
                          ),
                          const SizedBox(height: 12),
                          _actionTile(
                            icon: Icons.school_rounded,
                            iconColor: AppColors.accent,
                            title: 'Skill Assessment',
                            subtitle: 'Test your technical skills',
                            onTap: () =>
                                context.push(AppRoutes.skillAssessment),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  Widget _notificationBell() => Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
        ],
      );

  Widget _cvCard({
    required BuildContext context,
    required WidgetRef ref,
    required int strength,
    required bool hasCv,
    required bool isUploading,
  }) {
    return GestureDetector(
      onTap: hasCv ? () => context.push(AppRoutes.cv) : null,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'CV Profile Strength',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9)),
                ),
                if (hasCv) ...[
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      strength >= 80
                          ? 'Strong'
                          : strength >= 50
                              ? 'Good'
                              : 'Weak',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$strength',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1),
                ),
                Text(
                  '%',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
            if (hasCv) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 5,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              hasCv
                  ? 'Tap to view your parsed CV'
                  : 'Upload or build your CV with AI',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 18),
            if (hasCv)
              // Single "View CV" button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.cv),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('View CV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () =>
                              ref.read(cvUploadProvider.notifier).pickAndUpload(),
                      icon: isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary))
                          : const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(isUploading ? 'Uploading…' : 'Upload CV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        disabledBackgroundColor:
                            Colors.white.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.aiCvBuilder),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: const Text('Build with AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.4))),
                        textStyle: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.1)),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    LinearGradient? gradient,
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: gradient != null
                    ? iconColor.withValues(alpha: 0.25)
                    : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: gradient == null
                      ? iconColor.withValues(alpha: 0.1)
                      : null,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon,
                    color: gradient != null ? Colors.white : iconColor,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(badge,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmer(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
        ),
      );
}
