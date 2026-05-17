import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'recruiter_dashboard_screen.dart';
import 'post_job_screen.dart';
import '../../recruiter/presentation/recruiter_analytics_screen.dart';
import '../../recruiter/presentation/recruiter_jobs_screen.dart';
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
  int _currentIndex = 0;

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
    if (i == _currentIndex) return;
    _iconCtrls[_currentIndex].reverse();
    setState(() => _currentIndex = i);
    _iconCtrls[i].forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AppNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: _onTap,
        accent: AppColors.secondary,
        iconScales: _iconScales,
      ),
    );
  }
}
