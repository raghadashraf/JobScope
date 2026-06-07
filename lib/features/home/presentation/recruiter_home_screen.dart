import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'recruiter_dashboard_screen.dart';
import 'post_job_screen.dart';
import '../../recruiter/presentation/recruiter_analytics_screen.dart';
import '../../recruiter/presentation/recruiter_jobs_screen.dart';
import '../../notifications/data/notification_providers.dart';
import '../data/recruiter_home_providers.dart';
import 'profile_screen.dart';
import 'widgets/app_nav_bar.dart';

class RecruiterHomeScreen extends ConsumerStatefulWidget {
  const RecruiterHomeScreen({super.key});

  @override
  ConsumerState<RecruiterHomeScreen> createState() =>
      _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends ConsumerState<RecruiterHomeScreen>
    with TickerProviderStateMixin {
  final Set<int> _visitedTabs = {0};

  static const _navItems = [
    NavItem(icon: Icons.dashboard_rounded, outlinedIcon: Icons.dashboard_outlined, label: 'Dashboard'),
    NavItem(icon: Icons.add_box_rounded, outlinedIcon: Icons.add_box_outlined, label: 'Post Job'),
    NavItem(icon: Icons.people_rounded, outlinedIcon: Icons.people_outline_rounded, label: 'My Jobs'),
    NavItem(icon: Icons.bar_chart_rounded, outlinedIcon: Icons.bar_chart_outlined, label: 'Analytics'),
    NavItem(icon: Icons.person_rounded, outlinedIcon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  final List<Widget> _screens = const [
    RecruiterDashboardScreen(),
    PostJobScreen(),
    RecruiterJobsScreen(),
    RecruiterAnalyticsScreen(),
    ProfileScreen(),
  ];

  late final List<AnimationController> _iconCtrls;
  late final List<Animation<double>> _iconScales;

  @override
  void initState() {
    super.initState();
    _iconCtrls = List.generate(
      _navItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _iconScales = _iconCtrls
        .map((c) => Tween(begin: 1.0, end: 1.25).animate(
              CurvedAnimation(parent: c, curve: Curves.elasticOut),
            ))
        .toList();
    _iconCtrls[0].forward();
  }

  @override
  void dispose() {
    for (final c in _iconCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int i) {
    if (i == ref.read(recruiterTabIndexProvider)) return;
    setState(() => _visitedTabs.add(i));
    ref.read(recruiterTabIndexProvider.notifier).select(i);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(fcmBootstrapProvider);
    final tabIndex = ref.watch(recruiterTabIndexProvider);
    ref.listen(recruiterTabIndexProvider, (prev, next) {
      if (prev != null && prev != next) {
        setState(() => _visitedTabs.add(next));
        _iconCtrls[prev].reverse();
        _iconCtrls[next].forward();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: tabIndex,
        children: List.generate(_screens.length, (i) {
          if (!_visitedTabs.contains(i)) {
            return const SizedBox.shrink();
          }
          return _screens[i];
        }),
      ),
      bottomNavigationBar: AppNavBar(
        items: _navItems,
        currentIndex: tabIndex,
        onTap: _onTap,
        accent: AppColors.secondary,
        iconScales: _iconScales,
      ),
    );
  }
}
