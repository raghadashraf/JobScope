import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../data/recruiter_providers.dart';

class RecruiterAnalyticsScreen extends ConsumerWidget {
  const RecruiterAnalyticsScreen({super.key});

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
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
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _shimmerCard() => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.surfaceVariant,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(recruiterAllApplicationsStreamProvider);
    final analytics = ref.watch(recruiterAnalyticsProvider);
    final isLoading = appsAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Analytics',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isLoading) ...[
                Row(
                  children: [
                    Expanded(child: _shimmerCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _shimmerCard()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _shimmerCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _shimmerCard()),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    _statCard(
                      icon: Icons.people_rounded,
                      label: 'Total Applicants',
                      value: '${analytics.totalApplicants}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      icon: Icons.work_rounded,
                      label: 'Active Jobs',
                      value: '${analytics.activeJobs}',
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statCard(
                      icon: Icons.analytics_rounded,
                      label: 'Avg Match Score',
                      value: analytics.averageMatchScore == 0
                          ? 'N/A'
                          : '${analytics.averageMatchScore.toStringAsFixed(0)}%',
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Accepted',
                      value:
                          '${analytics.statusBreakdown['accepted'] ?? 0}',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
