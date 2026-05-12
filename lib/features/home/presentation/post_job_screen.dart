import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/job_model.dart';
import '../../auth/data/auth_providers.dart';
import '../../job_listing/data/job_providers.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  final JobModel? jobToEdit;

  const PostJobScreen({super.key, this.jobToEdit});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _reqCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();

  String _jobType = 'full-time';
  final List<String> _requirements = [];
  final List<String> _skills = [];
  bool _hasSalary = false;
  bool _isLoading = false;

  bool get _isEditMode => widget.jobToEdit != null;

  @override
  void initState() {
    super.initState();
    final job = widget.jobToEdit;
    if (job != null) {
      _titleCtrl.text = job.title;
      _companyCtrl.text = job.company;
      _locationCtrl.text = job.location;
      _descriptionCtrl.text = job.description;
      _jobType = job.jobType;
      _requirements.addAll(job.requirements);
      _skills.addAll(job.skills);
      _hasSalary = job.salaryMin != null || job.salaryMax != null;
      if (_hasSalary) {
        _salaryMinCtrl.text = job.salaryMin?.toStringAsFixed(0) ?? '';
        _salaryMaxCtrl.text = job.salaryMax?.toStringAsFixed(0) ?? '';
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _reqCtrl.dispose();
    _skillCtrl.dispose();
    _salaryMinCtrl.dispose();
    _salaryMaxCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, {String? label}) =>
      InputDecoration(
        hintText: hint,
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isEditMode ? AppColors.secondary : AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );

  void _addRequirement() {
    final text = _reqCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _requirements.add(text);
        _reqCtrl.clear();
      });
    }
  }

  void _addSkill() {
    final text = _skillCtrl.text.trim();
    if (text.isNotEmpty && !_skills.contains(text)) {
      setState(() {
        _skills.add(text);
        _skillCtrl.clear();
      });
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _companyCtrl.clear();
    _locationCtrl.clear();
    _descriptionCtrl.clear();
    _salaryMinCtrl.clear();
    _salaryMaxCtrl.clear();
    setState(() {
      _jobType = 'full-time';
      _requirements.clear();
      _skills.clear();
      _hasSalary = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(firebaseUserProvider).value!;
      final currentUser = await ref.read(currentUserProvider.future);
      final repo = ref.read(jobRepositoryProvider);

      final job = JobModel(
        id: widget.jobToEdit?.id ?? '',
        recruiterId: user.uid,
        recruiterName: currentUser?.name ?? user.displayName ?? '',
        recruiterPhotoUrl: currentUser?.photoUrl ?? '',
        title: _titleCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        jobType: _jobType,
        description: _descriptionCtrl.text.trim(),
        requirements: List<String>.from(_requirements),
        skills: List<String>.from(_skills),
        salaryMin: _hasSalary ? double.tryParse(_salaryMinCtrl.text) : null,
        salaryMax: _hasSalary ? double.tryParse(_salaryMaxCtrl.text) : null,
        postedAt: widget.jobToEdit?.postedAt ?? DateTime.now(),
        isActive: widget.jobToEdit?.isActive ?? true,
      );

      if (_isEditMode) {
        await repo.updateJob(job);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_snackbar('Job updated', AppColors.success));
          Navigator.pop(context);
        }
      } else {
        await repo.createJob(job);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_snackbar('Job posted!', AppColors.success));
          _clearForm();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_snackbar('Failed: $e', AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  SnackBar _snackbar(String msg, Color color) => SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  @override
  Widget build(BuildContext context) {
    final accent = _isEditMode ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isEditMode
          ? AppBar(
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
                'Edit Job',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          : null,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditMode) ...[
                Text(
                  'Post a Job',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in the details to attract the right candidates',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
              ],

              // ── Basic Info ────────────────────────────────────────────
              _sectionLabel('Basic Info'),
              TextFormField(
                controller: _titleCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: _inputDecoration(
                    'e.g. Senior Flutter Developer',
                    label: 'Job Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration:
                    _inputDecoration('e.g. Acme Corp', label: 'Company'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: _inputDecoration(
                    'e.g. Cairo, Egypt or Remote',
                    label: 'Location'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: _inputDecoration('').copyWith(labelText: 'Job Type'),
                child: DropdownButton<String>(
                  value: _jobType,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textPrimary),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(
                        value: 'full-time', child: Text('Full-time')),
                    DropdownMenuItem(
                        value: 'part-time', child: Text('Part-time')),
                    DropdownMenuItem(
                        value: 'remote', child: Text('Remote')),
                    DropdownMenuItem(
                        value: 'contract', child: Text('Contract')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _jobType = v);
                  },
                ),
              ),
              const SizedBox(height: 28),

              // ── Description ───────────────────────────────────────────
              _sectionLabel('Job Description'),
              TextFormField(
                controller: _descriptionCtrl,
                style: GoogleFonts.inter(fontSize: 14, height: 1.6),
                maxLines: 6,
                decoration: _inputDecoration(
                  'Describe the role, responsibilities, and what makes it exciting...',
                  label: 'Description',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 28),

              // ── Requirements ──────────────────────────────────────────
              _sectionLabel('Requirements'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _reqCtrl,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: _inputDecoration(
                          'e.g. 3+ years of Flutter experience'),
                      onFieldSubmitted: (_) => _addRequirement(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _addButton(_addRequirement, accent),
                ],
              ),
              if (_requirements.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._requirements.asMap().entries.map(
                      (e) => _listItem(
                        e.value,
                        accent,
                        () => setState(() => _requirements.removeAt(e.key)),
                      ),
                    ),
              ],
              const SizedBox(height: 28),

              // ── Skills ────────────────────────────────────────────────
              _sectionLabel('Required Skills'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillCtrl,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration:
                          _inputDecoration('e.g. Flutter, Firebase, Dart'),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _addButton(_addSkill, accent),
                ],
              ),
              if (_skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.asMap().entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.value,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _skills.removeAt(e.key)),
                            child: Icon(Icons.close_rounded,
                                size: 14, color: accent),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 28),

              // ── Salary ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel('Salary Range (optional)'),
                  Switch(
                    value: _hasSalary,
                    activeThumbColor: accent,
                    onChanged: (v) => setState(() => _hasSalary = v),
                  ),
                ],
              ),
              if (_hasSalary) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _salaryMinCtrl,
                        style: GoogleFonts.inter(fontSize: 14),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration:
                            _inputDecoration('0', label: 'Min (\$)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _salaryMaxCtrl,
                        style: GoogleFonts.inter(fontSize: 14),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration:
                            _inputDecoration('0', label: 'Max (\$)'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // ── Submit bar ─────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: accent.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  _isEditMode ? 'Save Changes' : 'Post Job',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  Widget _addButton(VoidCallback onTap, Color color) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      );

  Widget _listItem(String text, Color color, VoidCallback onRemove) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
}
