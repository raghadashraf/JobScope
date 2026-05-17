import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back arrow
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Header
                      Text(
                        'What brings\nyou here?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -1.4,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose the experience that fits your goals.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),

              // Candidate card
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _RoleCard(
                    gradient: AppColors.primaryGradient,
                    shadowColor: AppColors.primary,
                    icon: Icons.person_search_rounded,
                    role: 'candidate',
                    title: 'Job Seeker',
                    subtitle: 'Find your dream role',
                    description:
                        'AI-matched job listings tailored to your skills. Upload your CV once and let our intelligence do the rest.',
                    features: const [
                      (Icons.auto_awesome_rounded, 'AI Job Matching'),
                      (Icons.description_rounded, 'Smart CV Analysis'),
                      (Icons.school_rounded, 'Interview Training'),
                    ],
                  ),
                ),
              ),

              // Recruiter card
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: _RoleCard(
                    gradient: AppColors.secondaryGradient,
                    shadowColor: AppColors.secondary,
                    icon: Icons.business_center_rounded,
                    role: 'recruiter',
                    title: 'Recruiter',
                    subtitle: 'Hire top talent faster',
                    description:
                        'Post jobs, rank candidates automatically with AI, and manage your entire hiring pipeline in one place.',
                    features: const [
                      (Icons.post_add_rounded, 'Post Unlimited Jobs'),
                      (Icons.leaderboard_rounded, 'AI Candidate Ranking'),
                      (Icons.analytics_rounded, 'Hiring Analytics'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role card ──────────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final LinearGradient gradient;
  final Color shadowColor;
  final IconData icon;
  final String role;
  final String title;
  final String subtitle;
  final String description;
  final List<(IconData, String)> features;

  const _RoleCard({
    required this.gradient,
    required this.shadowColor,
    required this.icon,
    required this.role,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween(begin: 1.0, end: 0.975)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _navigate(String destination) {
    context.push(destination, extra: widget.role);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(gradient: widget.gradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Row(
                    children: [
                      // Icon badge
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Icon(widget.icon,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Description ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text(
                    widget.description,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.55,
                    ),
                  ),
                ),

                // ── Feature chips ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.features.map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(f.$1,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.85)),
                            const SizedBox(width: 6),
                            Text(
                              f.$2,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.90),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── Divider ───────────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),

                // ── Action buttons ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    children: [
                      // Sign In
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) => _pressCtrl.forward(),
                          onTapUp: (_) {
                            _pressCtrl.reverse();
                            _navigate(AppRoutes.login);
                          },
                          onTapCancel: () => _pressCtrl.reverse(),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Center(
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Get Started (solid white)
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) => _pressCtrl.forward(),
                          onTapUp: (_) {
                            _pressCtrl.reverse();
                            _navigate(AppRoutes.register);
                          },
                          onTapCancel: () => _pressCtrl.reverse(),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: widget.shadowColor,
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}
