import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/interview_model.dart';
import '../../applications/data/application_providers.dart';
import '../../recruiter/data/interview_providers.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

Set<DateTime> _interviewDays(List<InterviewModel> interviews) {
  final days = <DateTime>{};
  for (final interview in interviews) {
    final confirmed = interview.confirmedSlot;
    if (confirmed != null) days.add(_dateOnly(confirmed));
    for (final slot in interview.slots) {
      days.add(_dateOnly(slot));
    }
  }
  return days;
}

List<InterviewModel> _filterByDay(
    List<InterviewModel> all, DateTime? day) {
  if (day == null) return all;
  final target = _dateOnly(day);
  return all.where((interview) {
    final confirmed = interview.confirmedSlot;
    if (confirmed != null && _dateOnly(confirmed) == target) return true;
    return interview.slots.any((s) => _dateOnly(s) == target);
  }).toList();
}

class CandidateInterviewsScreen extends ConsumerStatefulWidget {
  const CandidateInterviewsScreen({super.key});

  @override
  ConsumerState<CandidateInterviewsScreen> createState() =>
      _CandidateInterviewsScreenState();
}

class _CandidateInterviewsScreenState
    extends ConsumerState<CandidateInterviewsScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
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
                child: Icon(Icons.arrow_back_ios_new_rounded,
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
                          child: Icon(Icons.calendar_today_rounded,
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

              final markedDays = _interviewDays(interviews);
              final filtered = _filterByDay(interviews, _selectedDay);

              return SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _InterviewMonthCalendar(
                      focusedMonth: _focusedMonth,
                      markedDays: markedDays,
                      selectedDay: _selectedDay,
                      onDaySelected: (day) => setState(() {
                        _selectedDay =
                            _selectedDay != null &&
                                    _dateOnly(_selectedDay!) == _dateOnly(day)
                                ? null
                                : day;
                      }),
                      onPrevMonth: () => setState(() {
                        _focusedMonth = DateTime(
                            _focusedMonth.year, _focusedMonth.month - 1);
                      }),
                      onNextMonth: () => setState(() {
                        _focusedMonth = DateTime(
                            _focusedMonth.year, _focusedMonth.month + 1);
                      }),
                    ),
                  ),
                  if (_selectedDay != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d')
                                .format(_selectedDay!),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                setState(() => _selectedDay = null),
                            child: Text('Show all',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No interviews on this day.',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...filtered.map(
                      (interview) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _InterviewCard(interview: interview),
                      ),
                    ),
                ]),
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

  Future<void> _openApplication(BuildContext context, WidgetRef ref) async {
    final appId = widget.interview.applicationId;
    if (appId.isEmpty) return;

    ApplicationModel? app = ref.read(applicationByIdProvider(appId)).value;
    app ??=
        await ref.read(applicationRepositoryProvider).fetchApplication(appId);

    if (!context.mounted) return;
    if (app == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load application',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.push(AppRoutes.applicationDetail, extra: app);
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

          const SizedBox(height: 12),
          if (interview.applicationId.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openApplication(context, ref),
                icon: const Icon(Icons.work_outline_rounded, size: 16),
                label: const Text('View Application'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(
                      color: AppColors.secondary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
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
                  side: BorderSide(color: AppColors.primary),
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

class _InterviewMonthCalendar extends StatelessWidget {
  final DateTime focusedMonth;
  final Set<DateTime> markedDays;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _InterviewMonthCalendar({
    required this.focusedMonth,
    required this.markedDays,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(focusedMonth);
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.textSecondary,
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, index) {
              if (index < startWeekday) return const SizedBox.shrink();
              final day = index - startWeekday + 1;
              final date =
                  DateTime(focusedMonth.year, focusedMonth.month, day);
              final dateKey = _dateOnly(date);
              final isMarked = markedDays.contains(dateKey);
              final isSelected = selectedDay != null &&
                  _dateOnly(selectedDay!) == dateKey;
              final isToday = _dateOnly(DateTime.now()) == dateKey;

              return GestureDetector(
                onTap: isMarked ? () => onDaySelected(date) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isMarked
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppColors.secondary)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isMarked
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                        ),
                      ),
                      if (isMarked)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
