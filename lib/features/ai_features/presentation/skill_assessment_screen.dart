import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/ai_service.dart';
import '../../cv_management/data/cv_providers.dart';
import '../data/ai_providers.dart';

class SkillAssessmentScreen extends ConsumerWidget {
  const SkillAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cvAsync = ref.watch(cvStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
          'Skill Assessment',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: cvAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, e) =>
            const Center(child: Text('Could not load CV data')),
        data: (cv) {
          if (cv == null || cv.skills.isEmpty) {
            return _NoCvView();
          }
          return _QuizLoader(skills: cv.skills);
        },
      ),
    );
  }
}

// ── No CV uploaded ────────────────────────────────────────────────────────────
class _NoCvView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              child: const Icon(Icons.description_outlined,
                  size: 40, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 20),
            Text('No CV Found',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Upload your CV first so we can generate a quiz based on your skills.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Go Back', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loads quiz from AI ────────────────────────────────────────────────────────
class _QuizLoader extends ConsumerWidget {
  final List<String> skills;
  const _QuizLoader({required this.skills});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(skillQuizProvider(skills));

    return quizAsync.when(
      loading: () => _LoadingQuizView(skills: skills),
      error: (e, _) => _QuizErrorView(
        error: e.toString(),
        onRetry: () => ref.invalidate(skillQuizProvider(skills)),
      ),
      data: (questions) => _QuizView(questions: questions, skills: skills),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────
class _LoadingQuizView extends StatelessWidget {
  final List<String> skills;
  const _LoadingQuizView({required this.skills});

  @override
  Widget build(BuildContext context) {
    final preview = skills.take(3).join(', ');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.school_rounded,
                  size: 40, color: AppColors.accent),
            ),
            const SizedBox(height: 24),
            Text(
              'Building Your Quiz',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Generating questions based on: $preview${skills.length > 3 ? '...' : ''}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────
class _QuizErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _QuizErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to generate quiz',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active quiz ───────────────────────────────────────────────────────────────
class _QuizView extends StatefulWidget {
  final List<QuizQuestion> questions;
  final List<String> skills;
  const _QuizView({required this.questions, required this.skills});

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _score = 0;
  bool _finished = false;

  QuizQuestion get _current => widget.questions[_currentIndex];

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == _current.correctIndex) _score++;
    });
  }

  void _next() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _ResultView(score: _score, total: widget.questions.length);

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1} of ${widget.questions.length}',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Text(
                    'Score: $_score',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.questions.length,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),

        // Question card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _current.question,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Options
                ..._current.options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final option = entry.value;
                  return _OptionTile(
                    option: option,
                    index: idx,
                    selected: _selectedOption == idx,
                    answered: _answered,
                    isCorrect: idx == _current.correctIndex,
                    onTap: () => _selectOption(idx),
                  );
                }),

                // Explanation (after answering)
                if (_answered) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (_selectedOption == _current.correctIndex
                              ? AppColors.success
                              : AppColors.error)
                          .withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_selectedOption == _current.correctIndex
                                ? AppColors.success
                                : AppColors.error)
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _selectedOption == _current.correctIndex
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: _selectedOption == _current.correctIndex
                              ? AppColors.success
                              : AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _current.explanation,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentIndex < widget.questions.length - 1
                            ? 'Next Question'
                            : 'See Results',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Option tile ───────────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final String option;
  final int index;
  final bool selected;
  final bool answered;
  final bool isCorrect;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.index,
    required this.selected,
    required this.answered,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color bgColor = AppColors.surface;
    Color textColor = AppColors.textPrimary;

    if (answered) {
      if (isCorrect) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.07);
        textColor = AppColors.success;
      } else if (selected) {
        borderColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.07);
        textColor = AppColors.error;
      }
    } else if (selected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.05);
    }

    final labels = ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: answered ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (answered && isCorrect)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 18)
              else if (answered && selected)
                const Icon(Icons.cancel_rounded,
                    color: AppColors.error, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Results view ──────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final int score;
  final int total;
  const _ResultView({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (score / total * 100).round();
    final (label, color, icon) = pct >= 80
        ? ('Excellent!', AppColors.success, Icons.emoji_events_rounded)
        : pct >= 60
            ? ('Good Job!', AppColors.primary, Icons.thumb_up_rounded)
            : ('Keep Practicing', AppColors.accent,
                Icons.fitness_center_rounded);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$score / $total correct',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$pct% score',
              style: GoogleFonts.inter(
                  fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text('Done',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
