import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../data/models/application_model.dart';
import '../../applications/data/application_providers.dart';
import 'dashboard_screen.dart';
import '../../job_listing/presentation/jobs_screen.dart';
import '../../applications/presentation/applications_screen.dart';
import 'profile_screen.dart';
import 'widgets/app_nav_bar.dart';

class CandidateHomeScreen extends ConsumerStatefulWidget {
  const CandidateHomeScreen({super.key});

  @override
  ConsumerState<CandidateHomeScreen> createState() =>
      _CandidateHomeScreenState();
}

class _CandidateHomeScreenState extends ConsumerState<CandidateHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<String, String> _lastStatuses = {};

  late final List<AnimationController> _iconCtrls;
  late final List<Animation<double>> _iconScales;

  static const _navItems = [
    NavItem(icon: Icons.home_rounded, outlinedIcon: Icons.home_outlined, label: 'Home'),
    NavItem(icon: Icons.work_rounded, outlinedIcon: Icons.work_outline_rounded, label: 'Jobs'),
    NavItem(icon: Icons.assignment_rounded, outlinedIcon: Icons.assignment_outlined, label: 'Apply'),
    NavItem(icon: Icons.person_rounded, outlinedIcon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    JobsScreen(),
    ApplicationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    LocalNotificationService().init();

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
    ref.listen<AsyncValue<List<ApplicationModel>>>(myApplicationsProvider,
        (_, next) {
      next.whenData((apps) {
        for (final app in apps) {
          final prev = _lastStatuses[app.id];
          final current = app.status.name;
          if (prev != null && prev != current && current != 'pending') {
            LocalNotificationService().showStatusChange(
              jobTitle: app.jobTitle,
              company: app.company,
              newStatus: current,
            );
          }
          _lastStatuses[app.id] = current;
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AppNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: _onTap,
        accent: AppColors.primary,
        iconScales: _iconScales,
      ),
    );
  }
}
