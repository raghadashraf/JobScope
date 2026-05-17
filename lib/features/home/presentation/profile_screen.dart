import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/user_model.dart';
import '../../applications/data/application_providers.dart';
import '../../auth/data/auth_providers.dart';
import '../../cv_management/data/cv_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final cvAsync = ref.watch(cvStreamProvider);
    final appsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          final cv = cvAsync.value;
          final apps = appsAsync.value ?? [];
          final appliedCount = apps.length;
          final shortlistedCount = apps
              .where((a) => a.status == ApplicationStatus.shortlisted)
              .length;
          final strength = cv?.profileStrength ?? 0;
          final isCandidate = user.role == UserRole.candidate;
          final accent =
              isCandidate ? AppColors.primary : AppColors.secondary;
          final gradient = isCandidate
              ? AppColors.primaryGradient
              : AppColors.secondaryGradient;

          return CustomScrollView(
            slivers: [
              // ── Hero header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ProfileHero(
                  user: user,
                  strength: strength,
                  appliedCount: appliedCount,
                  shortlistedCount: shortlistedCount,
                  gradient: gradient,
                  accent: accent,
                  isCandidate: isCandidate,
                ),
              ),

              // ── Menu sections ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account section
                      _sectionHeader('Account'),
                      const SizedBox(height: 10),
                      _MenuGroup(tiles: [
                        _MenuTileData(
                          icon: Icons.person_outline_rounded,
                          iconColor: accent,
                          title: 'Edit Profile',
                          onTap: () => context.push(AppRoutes.editProfile),
                        ),
                        if (isCandidate)
                          _MenuTileData(
                            icon: Icons.description_outlined,
                            iconColor: AppColors.secondary,
                            title: 'My CV',
                            trailing: cv != null
                                ? _StatusBadge(
                                    label: 'Uploaded',
                                    color: AppColors.success)
                                : null,
                            onTap: () => context.push(AppRoutes.cv),
                          ),
                      ]),

                      const SizedBox(height: 20),

                      // Preferences section
                      _sectionHeader('Preferences'),
                      const SizedBox(height: 10),
                      _MenuGroup(tiles: [
                        _MenuTileData(
                          icon: Icons.notifications_outlined,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Notifications',
                          onTap: () {},
                        ),
                        _MenuTileData(
                          icon: Icons.settings_outlined,
                          iconColor: AppColors.textSecondary,
                          title: 'Settings',
                          onTap: () {},
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // Support section
                      _sectionHeader('Support'),
                      const SizedBox(height: 10),
                      _MenuGroup(tiles: [
                        _MenuTileData(
                          icon: Icons.help_outline_rounded,
                          iconColor: AppColors.info,
                          title: 'Help & Support',
                          onTap: () {},
                        ),
                        _MenuTileData(
                          icon: Icons.star_outline_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Rate JobScope',
                          onTap: () {},
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Sign out
                      _SignOutTile(
                          onTap: () => _confirmSignOut(context, ref)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) =>
            const Center(child: Text('Error loading profile')),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1.0,
        ),
      );

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(AppRoutes.roleSelection);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0),
            child: Text('Sign Out', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }
}

// ── Gradient hero ─────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final UserModel user;
  final int strength;
  final int appliedCount;
  final int shortlistedCount;
  final LinearGradient gradient;
  final Color accent;
  final bool isCandidate;

  const _ProfileHero({
    required this.user,
    required this.strength,
    required this.appliedCount,
    required this.shortlistedCount,
    required this.gradient,
    required this.accent,
    required this.isCandidate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 60, left: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      // Avatar + name
                      _avatar(user),
                      const SizedBox(height: 14),
                      Text(
                        user.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (user.headline != null &&
                          user.headline!.isNotEmpty) ...[
                        Text(
                          user.headline!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        user.email,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          isCandidate ? 'Candidate' : 'Recruiter',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Stats row (candidate only)
              if (isCandidate)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      _statItem('$appliedCount', 'Applied'),
                      _dividerLine(),
                      _statItem('$shortlistedCount', 'Shortlisted'),
                      _dividerLine(),
                      _statItem('$strength%', 'CV Score'),
                    ],
                  ),
                ),

              // White rounded top
              const SizedBox(height: 24),
              Container(
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(UserModel user) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
            ? Image.network(user.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _avatarFallback(user.name))
            : _avatarFallback(user.name),
      ),
    );
  }

  Widget _avatarFallback(String name) => Container(
        color: Colors.white.withValues(alpha: 0.25),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
        ),
      );

  Widget _statItem(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75))),
          ],
        ),
      );

  Widget _dividerLine() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.25),
      );
}

// ── Menu group (rounded card containing multiple tiles) ───────────────────────
class _MenuTileData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuTileData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.trailing,
  });
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuTileData> tiles;
  const _MenuGroup({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final i = entry.key;
          final tile = entry.value;
          return Column(
            children: [
              if (i > 0)
                const Divider(
                    height: 1, color: AppColors.divider,
                    indent: 56, endIndent: 0),
              ListTile(
                onTap: tile.onTap,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tile.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(tile.icon, color: tile.iconColor, size: 18),
                ),
                title: Text(tile.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                trailing: tile.trailing ??
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textTertiary),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Sign out tile ─────────────────────────────────────────────────────────────
class _SignOutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout_rounded,
              color: AppColors.error, size: 18),
        ),
        title: Text('Sign Out',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            )),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppColors.error),
      ),
    );
  }
}
