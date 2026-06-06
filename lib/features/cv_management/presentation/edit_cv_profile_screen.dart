import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/profile_levels.dart';
import '../../../core/utils/cv_profile_strength.dart';
import '../../../core/widgets/profile_level_fields.dart';
import '../../../data/models/cv_model.dart';
import '../../auth/data/auth_providers.dart';
import '../../job_listing/data/job_providers.dart';
import '../../notifications/data/notification_providers.dart';
import '../data/cv_providers.dart';

class EditCvProfileScreen extends ConsumerStatefulWidget {
  const EditCvProfileScreen({super.key});

  @override
  ConsumerState<EditCvProfileScreen> createState() =>
      _EditCvProfileScreenState();
}

class _EditCvProfileScreenState extends ConsumerState<EditCvProfileScreen> {
  final _skillCtrl = TextEditingController();
  final _expTitle = TextEditingController();
  final _expCompany = TextEditingController();
  final _expDuration = TextEditingController();
  final _expDesc = TextEditingController();
  final _eduField = TextEditingController();
  final _eduInstitution = TextEditingController();
  final _eduYear = TextEditingController();

  List<String> _skills = [];
  List<WorkExperience> _experience = [];
  List<Education> _education = [];
  String? _experienceLevel;
  String? _educationLevel;
  String? _entryEducationLevel;
  bool _hasFile = false;
  bool _profileLoaded = false;
  bool _saving = false;

  void _applyProfile(CvModel? cv) {
    if (_profileLoaded) return;
    _profileLoaded = true;
    _skills = List<String>.from(cv?.skills ?? []);
    _experience = List<WorkExperience>.from(cv?.workExperience ?? []);
    _education = List<Education>.from(cv?.education ?? []);
    _experienceLevel = cv?.experienceLevel ??
        ProfileLevels.inferExperienceLevel(_experience.length);
    _educationLevel = cv?.educationLevel ??
        ProfileLevels.inferEducationLevel(_education);
    _hasFile = cv?.hasFile ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _skillCtrl,
      _expTitle,
      _expCompany,
      _expDuration,
      _expDesc,
      _eduField,
      _eduInstitution,
      _eduYear,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _previewStrength => CvProfileStrength.calculate(
        skills: _skills,
        workExperience: _experience,
        education: _education,
        hasFile: _hasFile,
        experienceLevel: _experienceLevel,
        educationLevel: _educationLevel,
      );

  void _addSkill() {
    final raw = _skillCtrl.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      for (final part in raw.split(',')) {
        final skill = part.trim();
        if (skill.isEmpty) continue;
        if (!_skills.any((s) => s.toLowerCase() == skill.toLowerCase())) {
          _skills.add(skill);
        }
      }
      _skillCtrl.clear();
    });
  }

  void _addExperience() {
    if (_expTitle.text.trim().isEmpty || _expCompany.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _experience.add(WorkExperience(
        title: _expTitle.text.trim(),
        company: _expCompany.text.trim(),
        duration: _expDuration.text.trim(),
        description: _expDesc.text.trim(),
      ));
      _expTitle.clear();
      _expCompany.clear();
      _expDuration.clear();
      _expDesc.clear();
    });
  }

  void _addEducation() {
    final degree = _entryEducationLevel;
    if (degree == null || _eduInstitution.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _education.add(Education(
        degree: degree,
        field: _eduField.text.trim(),
        institution: _eduInstitution.text.trim(),
        year: _eduYear.text.trim(),
      ));
      _entryEducationLevel = null;
      _eduField.clear();
      _eduInstitution.clear();
      _eduYear.clear();
      _educationLevel = ProfileLevels.inferEducationLevel(_education) ??
          _educationLevel;
    });
  }

  Future<void> _save() async {
    if (_skills.isEmpty &&
        _experience.isEmpty &&
        _education.isEmpty &&
        _experienceLevel == null &&
        _educationLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add at least one skill, experience entry, or education entry.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final err = await ref.read(cvProfileEditProvider.notifier).save(
          skills: _skills,
          workExperience: _experience,
          education: _education,
          experienceLevel: _experienceLevel,
          educationLevel: _educationLevel,
        );
    if (!mounted) return;

    if (err == null) {
      final user = ref.read(firebaseUserProvider).value;
      final cv = ref.read(cvStreamProvider).value;
      final jobs = ref.read(jobsStreamProvider).value ?? [];
      if (user != null && cv != null) {
        await ref
            .read(jobMatchNotificationServiceProvider)
            .syncMatchNotifications(
              candidateId: user.uid,
              cv: cv,
              jobs: jobs,
              notifications: ref.read(notificationRepositoryProvider),
            );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile saved · $_previewStrength% complete',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context, true);
  }

  InputDecoration _dec(String hint, {String? label}) => InputDecoration(
        hintText: hint,
        labelText: label,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CvModel?>>(cvStreamProvider, (prev, next) {
      if (_profileLoaded || !next.hasValue) return;
      setState(() => _applyProfile(next.value));
    });

    final profileAsync = ref.watch(cvStreamProvider);

    if (!_profileLoaded) {
      if (profileAsync.isLoading || !profileAsync.hasValue) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(
              'Edit Profile',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      _applyProfile(profileAsync.value);
    }

    if (profileAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'Edit Profile',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(child: Text('Error: ${profileAsync.error}')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile strength',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$_previewStrength%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: _previewStrength / 100,
                  strokeWidth: 6,
                  color: AppColors.primary,
                  backgroundColor: AppColors.border,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _skills.isEmpty && _experience.isEmpty && _education.isEmpty
                ? 'Add skills, experience, and education. Used for job matching even without a CV file.'
                : 'Update your skills, experience, and education below.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Profile levels'),
          Text(
            'Same options recruiters use when posting jobs — improves match accuracy.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ExperienceLevelDropdown(
            value: _experienceLevel,
            onChanged: (v) => setState(() => _experienceLevel = v),
          ),
          const SizedBox(height: 12),
          CandidateEducationLevelDropdown(
            value: _educationLevel,
            onChanged: (v) => setState(() => _educationLevel = v),
          ),
          const SizedBox(height: 28),
          _sectionTitle('Skills'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillCtrl,
                  decoration: _dec('e.g. Flutter, Dart'),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addSkill,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (_skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.asMap().entries.map((e) {
                return InputChip(
                  label: Text(e.value),
                  onDeleted: () => setState(() => _skills.removeAt(e.key)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 28),
          _sectionTitle('Work experience'),
          TextField(
              controller: _expTitle,
              decoration: _dec('Job title', label: 'Title')),
          const SizedBox(height: 10),
          TextField(
              controller: _expCompany,
              decoration: _dec('Company', label: 'Company')),
          const SizedBox(height: 10),
          TextField(
              controller: _expDuration,
              decoration: _dec('2022 – Present', label: 'Duration')),
          const SizedBox(height: 10),
          TextField(
            controller: _expDesc,
            maxLines: 3,
            decoration: _dec('Brief description', label: 'Description'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _addExperience,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add experience'),
          ),
          if (_experience.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._experience.asMap().entries.map((e) => _listTile(
                  title: '${e.value.title} · ${e.value.company}',
                  subtitle: e.value.duration,
                  onDelete: () =>
                      setState(() => _experience.removeAt(e.key)),
                )),
          ],
          const SizedBox(height: 28),
          _sectionTitle('Education'),
          CandidateEducationLevelDropdown(
            value: _entryEducationLevel,
            label: 'Degree type',
            onChanged: (v) => setState(() => _entryEducationLevel = v),
          ),
          const SizedBox(height: 10),
          TextField(
              controller: _eduField,
              decoration: _dec('Computer Science', label: 'Field of study')),
          const SizedBox(height: 10),
          TextField(
              controller: _eduInstitution,
              decoration: _dec('University name', label: 'Institution')),
          const SizedBox(height: 10),
          TextField(
              controller: _eduYear,
              decoration: _dec('2020 – 2024', label: 'Years')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _addEducation,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add education'),
          ),
          if (_education.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._education.asMap().entries.map((e) => _listTile(
                  title: '${e.value.degree} · ${e.value.field}',
                  subtitle:
                      '${e.value.institution}${e.value.year.isNotEmpty ? ' · ${e.value.year}' : ''}',
                  onDelete: () => setState(() => _education.removeAt(e.key)),
                )),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _listTile({
    required String title,
    required String subtitle,
    required VoidCallback onDelete,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
            ),
          ],
        ),
      );
}
