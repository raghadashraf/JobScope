import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/cv_model.dart';
import '../../auth/data/auth_providers.dart';

const _kPurple = Color(0xFF7C3AED);
const _kIndigo = Color(0xFF4F46E5);
const _kGradient = LinearGradient(colors: [_kPurple, _kIndigo]);
const _kApiKey = 'AIzaSyBYfVm5yXmz_x2vU6WZCFZR-H30_9lKxr4';
const _kGeminiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

// ── Data classes ──────────────────────────────────────────────────────────────
class _Exp {
  String role, company, startYear, endYear, description;
  _Exp({this.role='', this.company='', this.startYear='', this.endYear='', this.description=''});
}
class _Edu {
  String institution, degree, field, year;
  _Edu({this.institution='', this.degree='', this.field='', this.year=''});
}

// ── Main screen ───────────────────────────────────────────────────────────────
class AiCvBuilderScreen extends ConsumerStatefulWidget {
  const AiCvBuilderScreen({super.key});
  @override
  ConsumerState<AiCvBuilderScreen> createState() => _AiCvBuilderScreenState();
}

class _AiCvBuilderScreenState extends ConsumerState<AiCvBuilderScreen> {
  int _step = 0;
  bool _isGenerating = false;
  static const _total = 4;

  // Personal
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _summary = TextEditingController();
  // Experience
  final List<_Exp> _exps = [];
  // Education
  final List<_Edu> _edus = [];
  // Skills
  final _skillCtrl = TextEditingController();
  final List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final u = ref.read(currentUserProvider).value;
      if (u != null) {
        _name.text = u.name;
        _email.text = u.email;
        _phone.text = u.phone ?? '';
        _location.text = u.location ?? '';
        _title.text = u.headline ?? '';
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _title, _email, _phone, _location, _summary, _skillCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(children: [
          _header(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: KeyedSubtree(key: ValueKey(_step), child: _stepBody()),
            ),
          ),
          _nextBtn(),
        ]),
      ),
    );
  }

  Widget _header() => Container(
    decoration: const BoxDecoration(gradient: _kGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _backBtn(),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Build CV with AI', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              Text(_titles[_step], style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
              child: Text('${_step+1}/$_total', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / _total,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 5,
            ),
          ),
        ]),
      ),
    ),
  );

  Widget _backBtn() => GestureDetector(
    onTap: () => _step > 0 ? setState(() => _step--) : context.pop(),
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
    ),
  );

  static const _titles = [
    'Step 1 · Personal Information',
    'Step 2 · Work Experience',
    'Step 3 · Education',
    'Step 4 · Skills',
  ];

  Widget _stepBody() => switch (_step) {
    0 => _PersonalStep(name: _name, title: _title, email: _email, phone: _phone, location: _location, summary: _summary),
    1 => _ListStep<_Exp>(
        icon: Icons.work_rounded,
        heading: 'Work Experience',
        subtitle: 'Add your relevant work history.',
        items: _exps,
        cardTitle: (e) => e.role,
        cardSub: (e) => '${e.company} · ${e.startYear}–${e.endYear.isEmpty ? "Present" : e.endYear}',
        onRemove: (i) => setState(() => _exps.removeAt(i)),
        formBuilder: (onDismiss) => _ExpForm(
          onSave: (e) { setState(() => _exps.add(e)); onDismiss(); },
          onCancel: onDismiss,
        ),
      ),
    2 => _ListStep<_Edu>(
        icon: Icons.school_rounded,
        heading: 'Education',
        subtitle: 'Add your academic background.',
        items: _edus,
        cardTitle: (e) => '${e.degree} in ${e.field}',
        cardSub: (e) => '${e.institution} · ${e.year}',
        onRemove: (i) => setState(() => _edus.removeAt(i)),
        formBuilder: (onDismiss) => _EduForm(
          onSave: (e) { setState(() => _edus.add(e)); onDismiss(); },
          onCancel: onDismiss,
        ),
      ),
    3 => _SkillsStep(skills: _skills, ctrl: _skillCtrl,
        onAdd: (s) { if (s.isNotEmpty && !_skills.contains(s)) setState(() => _skills.add(s)); },
        onRemove: (s) => setState(() => _skills.remove(s))),
    _ => const SizedBox.shrink(),
  };

  Widget _nextBtn() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
    child: SizedBox(
      width: double.infinity, height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _kGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: TextButton(
          onPressed: _isGenerating ? null : _onNext,
          style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: _isGenerating
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  const SizedBox(width: 12),
                  Text('Generating your CV…', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ])
              : Text(_step < _total - 1 ? 'Continue →' : '✨ Generate My CV',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    ),
  );

  Future<void> _onNext() async {
    if (_step < _total - 1) { setState(() => _step++); return; }
    await _generate();
  }

  Future<void> _generate() async {
    final uid = ref.read(firebaseUserProvider).value?.uid;
    if (uid == null) return;
    setState(() => _isGenerating = true);
    try {
      final prompt = _buildPrompt();
      final res = await http.post(
        Uri.parse('$_kGeminiUrl?key=$_kApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.4, 'responseMimeType': 'application/json'}}),
      );
      if (res.statusCode != 200) throw Exception('AI error (${res.statusCode})');
      final data = jsonDecode(
        jsonDecode(res.body)['candidates'][0]['content']['parts'][0]['text'] as String,
      ) as Map<String, dynamic>;

      final aiSkills = (data['skills'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? _skills;
      final aiSummary = data['summary'] as String? ?? _summary.text;

      int score = 30;
      if (_exps.isNotEmpty) score += 25;
      if (_edus.isNotEmpty) score += 20;
      if (aiSkills.length >= 5) score += 15;
      if (aiSummary.isNotEmpty) score += 10;

      final cv = CvModel(
        uid: uid, fileUrl: '', fileName: 'AI-Generated CV',
        uploadedAt: DateTime.now(), skills: aiSkills,
        workExperience: _exps.map((e) => WorkExperience(
          company: e.company, title: e.role,
          duration: '${e.startYear}–${e.endYear.isEmpty ? "Present" : e.endYear}',
          description: e.description,
        )).toList(),
        education: _edus.map((e) => Education(
          institution: e.institution, degree: e.degree, field: e.field, year: e.year,
        )).toList(),
        profileStrength: score.clamp(0, 100),
      );

      await FirebaseFirestore.instance.collection('cvs').doc(uid).set(cv.toMap(), SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('CV created! 🎉', style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  String _buildPrompt() {
    final b = StringBuffer()
      ..writeln('You are a professional CV writer. Return JSON with "summary" (3-4 sentence first-person professional summary) and "skills" (expanded skill array).')
      ..writeln('Name: ${_name.text}, Title: ${_title.text}, Location: ${_location.text}')
      ..writeln('Draft summary: ${_summary.text}')
      ..writeln('Experience: ${_exps.map((e) => "${e.role} at ${e.company} (${e.startYear}–${e.endYear.isEmpty ? "Present" : e.endYear}): ${e.description}").join("; ")}')
      ..writeln('Education: ${_edus.map((e) => "${e.degree} in ${e.field} from ${e.institution} (${e.year})").join("; ")}')
      ..writeln('Skills: ${_skills.join(", ")}')
      ..writeln('Return ONLY valid JSON.');
    return b.toString();
  }
}

// ── Step 0 ────────────────────────────────────────────────────────────────────
class _PersonalStep extends StatelessWidget {
  final TextEditingController name, title, email, phone, location, summary;
  const _PersonalStep({required this.name, required this.title, required this.email, required this.phone, required this.location, required this.summary});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Column(children: [
      _StepHeader(icon: Icons.person_rounded, title: 'Personal Info', subtitle: 'Tell us about yourself.'),
      const SizedBox(height: 20),
      _Card(children: [
        _Field(ctrl: name, label: 'Full Name', hint: 'Sara Ahmed', icon: Icons.person_outline_rounded),
        _Field(ctrl: title, label: 'Job Title', hint: 'Flutter Developer', icon: Icons.badge_outlined),
        _Field(ctrl: email, label: 'Email', hint: 'you@email.com', icon: Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress),
        _Field(ctrl: phone, label: 'Phone', hint: '+20 10 1234 5678', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
        _Field(ctrl: location, label: 'Location', hint: 'Cairo, Egypt', icon: Icons.location_on_outlined),
        _Field(ctrl: summary, label: 'Brief Summary (optional)', hint: 'A short intro…', icon: Icons.notes_rounded, maxLines: 3),
      ]),
    ]),
  );
}

// ── Generic list step ─────────────────────────────────────────────────────────
class _ListStep<T> extends StatefulWidget {
  final IconData icon;
  final String heading, subtitle;
  final List<T> items;
  final String Function(T) cardTitle;
  final String Function(T) cardSub;
  final void Function(int) onRemove;
  final Widget Function(VoidCallback onSave) formBuilder;

  const _ListStep({required this.icon, required this.heading, required this.subtitle,
    required this.items, required this.cardTitle, required this.cardSub,
    required this.onRemove, required this.formBuilder});

  @override
  State<_ListStep<T>> createState() => _ListStepState<T>();
}

class _ListStepState<T> extends State<_ListStep<T>> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Column(children: [
      _StepHeader(icon: widget.icon, title: widget.heading, subtitle: widget.subtitle),
      const SizedBox(height: 20),
      ...widget.items.asMap().entries.map((e) => _EntryCard(
        title: widget.cardTitle(e.value),
        sub: widget.cardSub(e.value),
        onDelete: () => widget.onRemove(e.key),
      )),
      if (_showForm)
        widget.formBuilder(() => setState(() => _showForm = false))
      else
        _AddBtn(label: 'Add ${widget.heading}', onTap: () => setState(() => _showForm = true)),
    ]),
  );
}

// ── Experience form ───────────────────────────────────────────────────────────
class _ExpForm extends StatefulWidget {
  final void Function(_Exp) onSave;
  final VoidCallback onCancel;
  const _ExpForm({required this.onSave, required this.onCancel});
  @override
  State<_ExpForm> createState() => _ExpFormState();
}
class _ExpFormState extends State<_ExpForm> {
  final _r = TextEditingController(), _c = TextEditingController(),
      _s = TextEditingController(), _e = TextEditingController(), _d = TextEditingController();
  @override
  void dispose() {
    for (final x in [_r, _c, _s, _e, _d]) { x.dispose(); }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    _Card(children: [
      _Field(ctrl: _r, label: 'Job Title', hint: 'Senior Developer', icon: Icons.work_outline_rounded),
      _Field(ctrl: _c, label: 'Company', hint: 'Google', icon: Icons.business_rounded),
      Row(children: [
        Expanded(child: _Field(ctrl: _s, label: 'Start', hint: '2021', icon: Icons.calendar_today_outlined, keyboard: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _Field(ctrl: _e, label: 'End', hint: 'Present', icon: Icons.calendar_month_outlined)),
      ]),
      _Field(ctrl: _d, label: 'Description', hint: 'Key responsibilities…', icon: Icons.notes_rounded, maxLines: 3),
    ]),
    const SizedBox(height: 12),
    _FormButtons(
      onCancel: widget.onCancel,
      onSave: () { if (_r.text.isEmpty || _c.text.isEmpty) return;
        widget.onSave(_Exp(role: _r.text.trim(), company: _c.text.trim(), startYear: _s.text.trim(), endYear: _e.text.trim(), description: _d.text.trim()));
      },
    ),
  ]);
}

// ── Education form ────────────────────────────────────────────────────────────
class _EduForm extends StatefulWidget {
  final void Function(_Edu) onSave;
  final VoidCallback onCancel;
  const _EduForm({required this.onSave, required this.onCancel});
  @override
  State<_EduForm> createState() => _EduFormState();
}
class _EduFormState extends State<_EduForm> {
  final _i = TextEditingController(), _d = TextEditingController(),
      _f = TextEditingController(), _y = TextEditingController();
  @override
  void dispose() {
    for (final x in [_i, _d, _f, _y]) { x.dispose(); }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    _Card(children: [
      _Field(ctrl: _i, label: 'Institution', hint: 'Cairo University', icon: Icons.business_rounded),
      _Field(ctrl: _d, label: 'Degree', hint: "Bachelor's", icon: Icons.school_outlined),
      _Field(ctrl: _f, label: 'Field of Study', hint: 'Computer Science', icon: Icons.subject_rounded),
      _Field(ctrl: _y, label: 'Graduation Year', hint: '2024', icon: Icons.calendar_today_outlined, keyboard: TextInputType.number),
    ]),
    const SizedBox(height: 12),
    _FormButtons(
      onCancel: widget.onCancel,
      onSave: () { if (_i.text.isEmpty || _d.text.isEmpty) return;
        widget.onSave(_Edu(institution: _i.text.trim(), degree: _d.text.trim(), field: _f.text.trim(), year: _y.text.trim()));
      },
    ),
  ]);
}

// ── Skills step ───────────────────────────────────────────────────────────────
class _SkillsStep extends StatelessWidget {
  final List<String> skills;
  final TextEditingController ctrl;
  final void Function(String) onAdd;
  final void Function(String) onRemove;
  const _SkillsStep({required this.skills, required this.ctrl, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Column(children: [
      _StepHeader(icon: Icons.auto_awesome_rounded, title: 'Skills', subtitle: 'AI will suggest more based on your experience.'),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Row(children: [
            Expanded(child: TextField(
              controller: ctrl,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              onSubmitted: (v) { onAdd(v.trim()); ctrl.clear(); },
              decoration: InputDecoration(
                hintText: 'e.g. Flutter, Python…',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
                filled: true, fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPurple, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () { onAdd(ctrl.text.trim()); ctrl.clear(); },
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(gradient: _kGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ]),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: skills.map((s) => _Chip(label: s, onRemove: () => onRemove(s))).toList()),
          ] else ...[
            const SizedBox(height: 14),
            Text('Type a skill and press Enter.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary), textAlign: TextAlign.center),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _kPurple.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: _kPurple.withValues(alpha: 0.2))),
        child: Row(children: [
          const Icon(Icons.auto_fix_high_rounded, color: _kPurple, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('AI will suggest additional skills based on your experience.', style: GoogleFonts.inter(fontSize: 12, color: _kPurple, height: 1.4))),
        ]),
      ),
    ]),
  );
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _StepHeader({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 48, height: 48, decoration: BoxDecoration(gradient: _kGradient, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 24)),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.4)),
      const SizedBox(height: 3),
      Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
    ])),
  ]);
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
    child: Column(children: children.expand((w) => [w, const SizedBox(height: 14)]).toList()..removeLast()),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl; final String label, hint; final IconData icon;
  final TextInputType? keyboard; final int maxLines;
  const _Field({required this.ctrl, required this.label, required this.hint, required this.icon, this.keyboard, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    const SizedBox(height: 6),
    TextField(
      controller: ctrl, keyboardType: keyboard, maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
        prefixIcon: maxLines == 1 ? Padding(padding: const EdgeInsets.all(13), child: Icon(icon, size: 18, color: AppColors.textTertiary)) : null,
        filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPurple, width: 1.5)),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 12 : 0),
      ),
    ),
  ]);
}

class _EntryCard extends StatelessWidget {
  final String title, sub; final VoidCallback onDelete;
  const _EntryCard({required this.title, required this.sub, required this.onDelete});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: _kPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.check_rounded, color: _kPurple, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        Text(sub, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      ])),
      GestureDetector(onTap: onDelete, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16))),
    ]),
  );
}

class _AddBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _AddBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: _kPurple.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: _kPurple.withValues(alpha: 0.25))),
      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.add_circle_outline_rounded, color: _kPurple, size: 20),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _kPurple)),
      ])),
    ),
  );
}

class _FormButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  const _FormButtons({required this.onCancel, required this.onSave});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: OutlinedButton(
      onPressed: onCancel,
      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
      child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
    )),
    const SizedBox(width: 12),
    Expanded(child: ElevatedButton(
      onPressed: onSave,
      style: ElevatedButton.styleFrom(backgroundColor: _kPurple, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
      child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
    )),
  ]);
}

class _Chip extends StatelessWidget {
  final String label; final VoidCallback onRemove;
  const _Chip({required this.label, required this.onRemove});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: _kPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: _kPurple.withValues(alpha: 0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _kPurple)),
      const SizedBox(width: 6),
      GestureDetector(onTap: onRemove, child: const Icon(Icons.close_rounded, size: 14, color: _kPurple)),
    ]),
  );
}
