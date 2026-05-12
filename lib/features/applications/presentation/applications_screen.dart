import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../data/application_providers.dart';
import 'widgets/application_card_widget.dart';
import 'application_detail_screen.dart';

class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ConsumerState<ApplicationsScreen> createState() =>
      _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(myApplicationsProvider);

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
                  Text('My Applications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  appsAsync.when(
                    data: (apps) => Text(
                      '${apps.length} application${apps.length != 1 ? 's' : ''} total',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, e) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats row ────────────────────────────────────────────────
            appsAsync.when(
              data: (apps) => _StatsRow(applications: apps),
              loading: () => _shimmerRow(),
              error: (_, e) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // ── Tab bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabCtrl,
                labelStyle: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: AppColors.border,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Review'),
                  Tab(text: 'Shortlisted'),
                  Tab(text: 'Decided'),
                ],
              ),
            ),

            // ── Tab content ──────────────────────────────────────────────
            Expanded(
              child: appsAsync.when(
                data: (apps) => TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _AppList(
                        apps: apps,
                        onTap: (a) => _openDetail(context, a)),
                    _AppList(
                        apps: apps
                            .where((a) =>
                                a.status == ApplicationStatus.pending)
                            .toList(),
                        onTap: (a) => _openDetail(context, a)),
                    _AppList(
                        apps: apps
                            .where((a) =>
                                a.status == ApplicationStatus.shortlisted)
                            .toList(),
                        onTap: (a) => _openDetail(context, a)),
                    _AppList(
                        apps: apps
                            .where((a) =>
                                a.status == ApplicationStatus.accepted ||
                                a.status == ApplicationStatus.rejected)
                            .toList(),
                        onTap: (a) => _openDetail(context, a)),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style:
                            const TextStyle(color: AppColors.error))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, ApplicationModel app) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ApplicationDetailScreen(application: app)),
    );
  }

  Widget _shimmerRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(
              4,
              (_) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )),
        ),
      );
}

// ── Stats row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<ApplicationModel> applications;
  const _StatsRow({required this.applications});

  @override
  Widget build(BuildContext context) {
    final counts = {
      ApplicationStatus.pending:
          applications.where((a) => a.status == ApplicationStatus.pending).length,
      ApplicationStatus.shortlisted:
          applications.where((a) => a.status == ApplicationStatus.shortlisted).length,
      ApplicationStatus.accepted:
          applications.where((a) => a.status == ApplicationStatus.accepted).length,
      ApplicationStatus.rejected:
          applications.where((a) => a.status == ApplicationStatus.rejected).length,
    };

    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _StatChip(
            label: 'Total',
            count: applications.length,
            color: AppColors.primary,
          ),
          _StatChip(
            label: 'Review',
            count: counts[ApplicationStatus.pending]!,
            color: const Color(0xFFF59E0B),
          ),
          _StatChip(
            label: 'Shortlisted',
            count: counts[ApplicationStatus.shortlisted]!,
            color: AppColors.primary,
          ),
          _StatChip(
            label: 'Accepted',
            count: counts[ApplicationStatus.accepted]!,
            color: AppColors.success,
          ),
          _StatChip(
            label: 'Rejected',
            count: counts[ApplicationStatus.rejected]!,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Applications list ─────────────────────────────────────────────────────────
class _AppList extends StatelessWidget {
  final List<ApplicationModel> apps;
  final void Function(ApplicationModel) onTap;
  const _AppList({required this.apps, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
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
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.assignment_outlined,
                    size: 40, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 20),
              Text('No applications here',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 8),
              Text(
                'Applications in this category will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: apps.length,
      itemBuilder: (_, i) => ApplicationCardWidget(
        application: apps[i],
        onTap: () => onTap(apps[i]),
      ),
    );
  }
}
