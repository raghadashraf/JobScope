import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_router.dart';
import '../data/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: settingsAsync.when(
        data: (settings) => _SettingsBody(settings: settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final AppSettings settings;
  const _SettingsBody({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final surface = Theme.of(context).colorScheme.surface;
    final border = Theme.of(context).dividerColor;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Theme.of(context).colorScheme.onSurface),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _sectionTitle(context, 'Appearance'),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    title: Text('Dark mode',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Uses dark theme across Material widgets',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: settings.isDarkMode,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => notifier.setDarkMode(v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Notifications'),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    title: Text('Push & local alerts',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'OS banners and FCM when enabled. In-app inbox always on.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: settings.notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => notifier.setNotificationsEnabled(v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'About & legal'),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  _linkTile(context, 'About JobScope', AppRoutes.about),
                  const Divider(height: 1),
                  _linkTile(context, 'Help & FAQ', AppRoutes.help),
                  const Divider(height: 1),
                  _linkTile(context, 'Privacy policy', AppRoutes.privacy),
                  const Divider(height: 1),
                  _linkTile(context, 'Terms of service', AppRoutes.terms),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

  Widget _linkTile(BuildContext context, String title, String route) {
    return ListTile(
      title: Text(title,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppColors.textTertiary),
      onTap: () => context.push(route),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(children: children),
    );
  }
}
