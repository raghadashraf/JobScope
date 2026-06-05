import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import 'settings_scaffold.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'How do I apply to a job?',
      'Open Jobs, pick a listing, optionally complete Train Before Apply, then tap Apply. '
          'Track status under Applications.',
    ),
    (
      'What does Under Review mean?',
      'Your application is pending (`pending` in Firestore). You can withdraw while in this state.',
    ),
    (
      'Why is my match score empty?',
      'Upload a CV with skills first. Match score is computed when you apply.',
    ),
    (
      'Where are notifications?',
      'Profile → Notifications, or the bell on the dashboard. Tap an item to open the related screen.',
    ),
    (
      'Recruiter: how do I see applicants?',
      'My Jobs → select a job → view applicants. Shortlist or reject from applicant detail.',
    ),
    (
      'Dark mode or alerts not working?',
      'Profile → Settings. Dark mode persists after restart. Turn off Push & local alerts to silence OS banners.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Help & FAQ',
      child: Column(
        children: [
          for (var i = 0; i < _faqs.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _FaqCard(question: _faqs[i].$1, answer: _faqs[i].$2),
          ],
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqCard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
