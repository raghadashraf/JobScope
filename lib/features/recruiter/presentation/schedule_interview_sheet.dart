import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/interview_model.dart';
import '../../auth/data/auth_providers.dart';
import '../data/interview_providers.dart';

class ScheduleInterviewSheet extends ConsumerStatefulWidget {
  final ApplicationModel application;

  const ScheduleInterviewSheet({super.key, required this.application});

  @override
  ConsumerState<ScheduleInterviewSheet> createState() =>
      _ScheduleInterviewSheetState();
}

class _ScheduleInterviewSheetState
    extends ConsumerState<ScheduleInterviewSheet> {
  final List<DateTime> _slots = [];
  bool _isSending = false;

  Future<void> _pickSlot({int? replaceIndex}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted || time == null) return;

    final slot = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (replaceIndex != null) {
        _slots[replaceIndex] = slot;
      } else {
        _slots.add(slot);
      }
    });
  }

  Future<void> _send() async {
    if (_slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Add at least one time slot.',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isSending = true);
    try {
      final recruiter = ref.read(currentUserProvider).value;
      final app = widget.application;

      final interview = InterviewModel(
        id: '',
        applicationId: app.id,
        jobId: app.jobId,
        jobTitle: app.jobTitle,
        company: app.company,
        recruiterId: recruiter?.uid ?? '',
        recruiterName: recruiter?.name ?? '',
        candidateId: app.candidateId,
        candidateName: app.candidateName,
        candidateEmail: app.candidateEmail,
        slots: List.from(_slots),
        status: InterviewStatus.proposed,
        createdAt: DateTime.now(),
      );

      await ref.read(interviewNotifierProvider.notifier).propose(interview);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Interview slots sent to ${app.candidateName}.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send: $e',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
          color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Schedule Interview',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Propose up to 3 time slots for ${widget.application.candidateName}',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Slot list
          ..._slots.asMap().entries.map((entry) {
            final i = entry.key;
            final slot = entry.value;
            return _SlotRow(
              index: i,
              slot: slot,
              onEdit: () => _pickSlot(replaceIndex: i),
              onRemove: () => setState(() => _slots.removeAt(i)),
            );
          }),

          // Add slot button (max 3)
          if (_slots.length < 3) ...[
            if (_slots.isNotEmpty) const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickSlot(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _slots.isEmpty
                          ? 'Pick a date & time'
                          : 'Add another slot',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Send Proposal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final int index;
  final DateTime slot;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _SlotRow({
    required this.index,
    required this.slot,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d · h:mm a');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Icon(Icons.edit_rounded,
                  size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
