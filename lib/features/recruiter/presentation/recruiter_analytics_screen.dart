import 'package:fl_chart/fl_chart.dart';
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

  Widget _legendRow({
    required Color color,
    required String label,
    required int count,
  }) =>
      Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
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
                const SizedBox(height: 24),
                Text(
                  'Application Breakdown',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: analytics.totalApplicants == 0
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.pie_chart_outline_rounded,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No application data yet',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Builder(
                          builder: (_) {
                            final breakdown = analytics.statusBreakdown;
                            final sections = [
                              PieChartSectionData(
                                color: AppColors.warning,
                                value:
                                    breakdown['pending']!.toDouble(),
                                title: '',
                                radius: 28,
                              ),
                              PieChartSectionData(
                                color: AppColors.primary,
                                value: breakdown['shortlisted']!
                                    .toDouble(),
                                title: '',
                                radius: 28,
                              ),
                              PieChartSectionData(
                                color: AppColors.success,
                                value:
                                    breakdown['accepted']!.toDouble(),
                                title: '',
                                radius: 28,
                              ),
                              PieChartSectionData(
                                color: AppColors.error,
                                value:
                                    breakdown['rejected']!.toDouble(),
                                title: '',
                                radius: 28,
                              ),
                            ]
                                .where((s) => s.value > 0)
                                .toList();

                            return Row(
                              children: [
                                SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: PieChart(
                                    PieChartData(
                                      sections: sections,
                                      centerSpaceRadius: 40,
                                      sectionsSpace: 3,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _legendRow(
                                        color: AppColors.warning,
                                        label: 'Under Review',
                                        count:
                                            breakdown['pending'] ?? 0,
                                      ),
                                      const SizedBox(height: 10),
                                      _legendRow(
                                        color: AppColors.primary,
                                        label: 'Shortlisted',
                                        count:
                                            breakdown['shortlisted'] ?? 0,
                                      ),
                                      const SizedBox(height: 10),
                                      _legendRow(
                                        color: AppColors.success,
                                        label: 'Accepted',
                                        count:
                                            breakdown['accepted'] ?? 0,
                                      ),
                                      const SizedBox(height: 10),
                                      _legendRow(
                                        color: AppColors.error,
                                        label: 'Rejected',
                                        count:
                                            breakdown['rejected'] ?? 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Top Skills Demand',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (analytics.topSkills.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'Post jobs with skills to see demand',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SizedBox(
                      height: analytics.topSkills.length * 52.0,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: analytics.topSkills.first.value
                                  .toDouble() +
                              1,
                          barGroups: analytics.topSkills
                              .asMap()
                              .entries
                              .map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.value.toDouble(),
                                  color: AppColors.primary,
                                  width: 20,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 100,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >=
                                          analytics.topSkills.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final skill =
                                      analytics.topSkills[index].key;
                                  final label = skill.isEmpty
                                      ? ''
                                      : '${skill[0].toUpperCase()}${skill.substring(1)}';
                                  return Text(
                                    label,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) => Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
