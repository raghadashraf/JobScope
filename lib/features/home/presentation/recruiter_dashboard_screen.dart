import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../../applications/presentation/widgets/application_status_badge.dart';
import '../../auth/data/auth_providers.dart';
import '../../recruiter/data/recruiter_providers.dart';

class RecruiterDashboardScreen extends ConsumerStatefulWidget {
  const RecruiterDashboardScreen({super.key});

  @override
  ConsumerState<RecruiterDashboardScreen> createState() =>
      _RecruiterDashboardScreenState();
}

class _RecruiterDashboardScreenState
    extends ConsumerState<RecruiterDashboardScreen>
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
      final start = i * 0.13;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOut));
    });

    _slideAnims = List.generate(_sections, (i) {
      final start = i * 0.13;
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

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _fadeAnims[i],
        child: SlideTransition(position: _slideAnims[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final stats = ref.watch(recruiterStatsProvider);
    final recentAsync = ref.watch(recruiterAllApplicationsStreamProvider);

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
                    // ── Header ──────────────────────────────────────────────
                    _animated(
                      0,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back 👋',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              userAsync.when(
                                data: (user) => Text(
                                  user?.name ?? 'Recruiter',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                loading: () => const SizedBox(height: 26),
                                error: (_, _) => const Text('Recruiter'),
                              ),
                              if (userAsync.value?.company != null &&
                                  userAsync.value!.company!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.business_rounded,
                                        size: 12,
                                        color: AppColors.textTertiary),
                                    const SizedBox(width: 4),
                                    Text(
                                      userAsync.value!.company!,
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textTertiary),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Active jobs banner ──────────────────────────────────
                    _animated(
                      1,
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppColors.secondaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Job Postings',
                                    style: GoogleFonts.inter(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${stats.activeJobs}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    stats.activeJobs == 0
                                        ? 'Post your first job to start hiring'
                                        : '${stats.activeJobs} job${stats.activeJobs != 1 ? 's' : ''} receiving applications',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color:
                                          Colors.white.withValues(alpha: 0.80),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.work_rounded,
                                  color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Stats row ───────────────────────────────────────────
                    _animated(
                      2,
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              icon: Icons.people_rounded,
                              label: 'Total Applicants',
                              value: '${stats.totalApplicants}',
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              icon: Icons.star_rounded,
                              label: 'Shortlisted',
                              value: '${stats.shortlisted}',
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Recent Activity header ──────────────────────────────
                    _animated(
                      3,
                      Text(
                        'Recent Activity',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Activity list ───────────────────────────────────────
                    _animated(
                      4,
                      recentAsync.when(
                        data: (apps) {
                          final recent = apps.take(5).toList();
                          if (recent.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(36),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.inbox_outlined,
                                        size: 30,
                                        color: AppColors.textTertiary),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No activity yet',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Applications will appear here',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: recent.asMap().entries.map((entry) {
                                return Column(
                                  children: [
                                    if (entry.key > 0)
                                      const Divider(
                                          height: 1,
                                          color: AppColors.divider,
                                          indent: 16,
                                          endIndent: 16),
                                    _activityTile(entry.value),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                            height: 60,
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.secondary))),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(ApplicationModel app) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
              child: Text(
                app.candidateName.isNotEmpty
                    ? app.candidateName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.candidateName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Applied to ${app.jobTitle}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ApplicationStatusBadge(status: app.status),
          ],
        ),
      );

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) =>
      Container(
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
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      );
}
