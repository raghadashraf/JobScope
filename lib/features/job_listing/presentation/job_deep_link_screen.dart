import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_router.dart';
import '../data/job_providers.dart';

// One-shot provider: fetch a single job by ID for the deep link entry point.
final _deepLinkJobProvider =
    FutureProvider.autoDispose.family<dynamic, String>(
  (ref, jobId) => ref.read(jobRepositoryProvider).fetchJob(jobId),
);

class JobDeepLinkScreen extends ConsumerWidget {
  final String jobId;
  const JobDeepLinkScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(_deepLinkJobProvider(jobId));

    return jobAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: BackButton(color: AppColors.textPrimary,
              onPressed: () => context.go(AppRoutes.jobs)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off_rounded,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text(
                  'Job not found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This job may have been removed or the link has expired.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.jobs),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Browse Jobs',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (job) {
        if (job == null) {
          // Redirect to the error branch by pushing an error trigger
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppRoutes.jobs);
          });
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          );
        }
        // Replace this route with the real job detail screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.replace(AppRoutes.jobDetail, extra: job);
          }
        });
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        );
      },
    );
  }
}
