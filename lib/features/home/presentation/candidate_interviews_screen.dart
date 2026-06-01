import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../data/models/interview_model.dart';
import '../../recruiter/data/interview_providers.dart';

class CandidateInterviewsScreen extends ConsumerWidget {
  const CandidateInterviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interviewsAsync = ref.watch(candidateInterviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.textPrimary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Interviews',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          interviewsAsync.when(
            data: (interviews) {
              if (interviews.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
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
                          child: const Icon(Icons.calendar_today_rounded,
                              size: 36, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No interviews yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recruiters will send you interview slots here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _InterviewCard(interview: interviews[i]),
                  ),
                  childCount: interviews.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child:
                  Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.error))),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _InterviewCard extends ConsumerStatefulWidget {
  final InterviewModel interview;

  const _InterviewCard({required this.interview});

  @override
  ConsumerState<_InterviewCard> createState() => _InterviewCardState();
}

class _InterviewCardState extends ConsumerState<_InterviewCard> {
  bool _isConfirming = false;

  Color get _statusColor {
    return switch (widget.interview.status) {
      InterviewStatus.proposed => AppColors.accent,
      InterviewStatus.confirmed => AppColors.success,
      InterviewStatus.cancelled => AppColors.textTertiary,
    };
  }

  String get _statusLabel {
    return switch (widget.interview.status) {
      InterviewStatus.proposed => 'Awaiting Confirmation',
      InterviewStatus.confirmed => 'Confirmed',
      InterviewStatus.cancelled => 'Cancelled',
    };
  }

  Future<void> _confirmSlot(int index, DateTime slot) async {
    setState(() => _isConfirming = true);
    try {
      await ref
          .read(interviewNotifierProvider.notifier)
          .confirm(widget.interview.id, index);

      // Add to device calendar with a 30-min iOS reminder
      final event = Event(
        title: 'Interview: ${widget.interview.jobTitle}',
        description:
            'Interview for ${widget.interview.jobTitle} at ${widget.interview.company} with ${widget.interview.recruiterName}.',
        startDate: slot,
        endDate: slot.add(const Duration(hours: 1)),
        iosParams: const IOSParams(reminder: Duration(minutes: 30)),
      );
      await Add2Calendar.addEvent2Cal(event);

      // Show local notification
      await LocalNotificationService().showInterviewConfirmed(
        jobTitle: widget.interview.jobTitle,
        company: widget.interview.company,
        slot: slot,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Interview confirmed and added to calendar!',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final interview = widget.interview;
    final fmt = DateFormat('EEE, MMM d · h:mm a');
    final isConfirmed = interview.status == InterviewStatus.confirmed;
    final isCancelled = interview.status == InterviewStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _statusColor.withValues(alpha: isConfirmed ? 0.3 : 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.video_call_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interview.jobTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      interview.company,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (isConfirmed && interview.confirmedSlot != null) ...[
            // Confirmed slot
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fmt.format(interview.confirmedSlot!),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final event = Event(
                    title: 'Interview: ${interview.jobTitle}',
                    description: 'Interview at ${interview.company}',
                    startDate: interview.confirmedSlot!,
                    endDate: interview.confirmedSlot!
                        .add(const Duration(hours: 1)),
                    iosParams:
                        const IOSParams(reminder: Duration(minutes: 30)),
                  );
                  await Add2Calendar.addEvent2Cal(event);
                },
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: const Text('Add to Calendar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else if (!isCancelled) ...[
            Text(
              'Select a time slot:',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            if (_isConfirming)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
              )
            else
              ...interview.slots.asMap().entries.map((e) {
                final i = e.key;
                final slot = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _confirmSlot(i, slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fmt.format(slot),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ] else ...[
            Text(
              'This interview was cancelled.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
