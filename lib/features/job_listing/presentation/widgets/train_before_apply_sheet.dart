import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/job_model.dart';
import '../../../../data/models/training_session_model.dart';
import '../../../ai_features/data/ai_providers.dart';
import '../../../ai_features/data/training_providers.dart';
import '../../../auth/data/auth_providers.dart';

/// Per-job interview practice before applying. Distinct from dashboard Interview Training.
class TrainBeforeApplySheet extends ConsumerStatefulWidget {
  final JobModel job;

  const TrainBeforeApplySheet({super.key, required this.job});

  @override
  ConsumerState<TrainBeforeApplySheet> createState() =>
      _TrainBeforeApplySheetState();
}

class _TrainBeforeApplySheetState extends ConsumerState<TrainBeforeApplySheet> {
  final _answerCtrl = TextEditingController();
  List<TrainQuestion>? _questions;
  final List<TrainAnswerRecord> _answers = [];
  String? _sessionId;
  int _questionIndex = 0;
  bool _loadingQuestions = true;
  bool _evaluating = false;
  String? _error;
  bool _showFeedback = false;
  TrainAnswerRecord? _lastEvaluation;
  bool _finished = false;
  int? _readinessScore;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loadingQuestions = true;
      _error = null;
      _finished = false;
      _answers.clear();
      _questionIndex = 0;
      _showFeedback = false;
      _readinessScore = null;
    });
    try {
      final questions = await ref
          .read(aiServiceProvider)
          .generateTrainBeforeApplyQuestions(
            jobTitle: widget.job.title,
            company: widget.job.company,
            jobDescription: widget.job.description,
            skills: widget.job.skills,
          );
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loadingQuestions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingQuestions = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty || _questions == null) return;

    setState(() {
      _evaluating = true;
      _error = null;
    });

    try {
      final q = _questions![_questionIndex];
      final evaluation = await ref.read(aiServiceProvider).evaluateTrainAnswer(
            jobTitle: widget.job.title,
            question: q.question,
            scenario: q.scenario,
            userAnswer: text,
          );

      final record = TrainAnswerRecord(
        answer: text,
        feedback: evaluation.feedback,
        score: evaluation.score,
      );

      _answers.add(record);

      final uid = ref.read(firebaseUserProvider).value!.uid;
      final repo = ref.read(trainingRepositoryProvider);

      if (_sessionId == null) {
        final session = await repo.createSession(TrainingSessionModel(
          id: '',
          uid: uid,
          jobId: widget.job.id,
          jobTitle: widget.job.title,
          company: widget.job.company,
          questions: _questions!,
          answers: List.from(_answers),
          isComplete: false,
          createdAt: DateTime.now(),
        ));
        _sessionId = session.id;
      } else {
        await repo.updateSession(TrainingSessionModel(
          id: _sessionId!,
          uid: uid,
          jobId: widget.job.id,
          jobTitle: widget.job.title,
          company: widget.job.company,
          questions: _questions!,
          answers: List.from(_answers),
          isComplete: false,
          createdAt: DateTime.now(),
        ));
      }

      if (!mounted) return;
      setState(() {
        _lastEvaluation = record;
        _showFeedback = true;
        _evaluating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _evaluating = false;
      });
    }
  }

  void _nextQuestion() {
    if (_questions == null) return;
    if (_questionIndex < _questions!.length - 1) {
      setState(() {
        _questionIndex++;
        _answerCtrl.clear();
        _showFeedback = false;
        _lastEvaluation = null;
      });
    } else {
      _completeSession();
    }
  }

  Future<void> _completeSession() async {
    if (_answers.isEmpty || _sessionId == null) return;
    final avg =
        (_answers.map((a) => a.score).reduce((a, b) => a + b) / _answers.length)
            .round();

    final uid = ref.read(firebaseUserProvider).value!.uid;
    await ref.read(trainingRepositoryProvider).updateSession(
          TrainingSessionModel(
            id: _sessionId!,
            uid: uid,
            jobId: widget.job.id,
            jobTitle: widget.job.title,
            company: widget.job.company,
            questions: _questions!,
            answers: List.from(_answers),
            readinessScore: avg,
            isComplete: true,
            createdAt: DateTime.now(),
          ),
        );

    if (!mounted) return;
    setState(() {
      _readinessScore = avg;
      _finished = true;
    });
  }

  void _retry() {
    _sessionId = null;
    _answerCtrl.clear();
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.trainBeforeApply,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.job.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingQuestions) {
      return _centerMessage(
        icon: Icons.psychology_rounded,
        title: 'Preparing questions',
        subtitle: 'Gemini is building 5 role-specific scenarios…',
        loading: true,
      );
    }
    if (_error != null && _questions == null) {
      return _centerMessage(
        icon: Icons.error_outline_rounded,
        title: 'Could not load training',
        subtitle: _error!,
        action: TextButton(onPressed: _loadQuestions, child: const Text('Retry')),
      );
    }
    if (_finished && _readinessScore != null) {
      return _resultView();
    }
    if (_questions == null || _questions!.isEmpty) {
      return _centerMessage(
        icon: Icons.info_outline_rounded,
        title: 'No questions',
        subtitle: 'Try again.',
        action: TextButton(onPressed: _retry, child: const Text('Retry')),
      );
    }

    final total = _questions!.length;
    final progress = (_questionIndex + (_showFeedback ? 1 : 0)) / total;
    final q = _questions![_questionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question ${_questionIndex + 1} of $total',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.05, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            q.scenario,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            q.question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          if (!_showFeedback) ...[
            TextField(
              controller: _answerCtrl,
              maxLines: 5,
              enabled: !_evaluating,
              decoration: InputDecoration(
                hintText: 'Type your answer…',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _evaluating ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _evaluating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Submit answer',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ] else if (_lastEvaluation != null) ...[
            _feedbackCard(_lastEvaluation!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _questionIndex < total - 1 ? 'Next question' : 'See results',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _feedbackCard(TrainAnswerRecord record) {
    final color = record.score >= 60 ? AppColors.success : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Score: ${record.score}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.feedback,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultView() {
    final score = _readinessScore!;
    final passed = score >= TrainingSessionModel.minReadinessToApply;
    final color = passed ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Readiness score',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            passed
                ? 'You meet the ${TrainingSessionModel.minReadinessToApply}% threshold. You can apply to this job.'
                : 'Score below ${TrainingSessionModel.minReadinessToApply}%. Retry training before applying.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _retry,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Retry training',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, passed),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                passed ? 'Done' : 'Close',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    bool loading = false,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const CircularProgressIndicator(color: AppColors.primary)
          else
            Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 20),
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary)),
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    );
  }
}

void showTrainBeforeApplySheet(BuildContext context, JobModel job) {
  showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TrainBeforeApplySheet(job: job),
  );
}
