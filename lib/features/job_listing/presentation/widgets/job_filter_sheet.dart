import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/job_providers.dart'; // FIXED: was '../data/job_providers.dart'

class JobFilterSheet extends ConsumerStatefulWidget {
  const JobFilterSheet({super.key});

  @override
  ConsumerState<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends ConsumerState<JobFilterSheet> {
  final _locationCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  RangeValues _salaryRange = const RangeValues(0, 200000);
  bool _useSalaryFilter = false;
  final List<String> _selectedSkills = [];

  @override
  void initState() {
    super.initState();
    final filter = ref.read(jobFilterProvider);
    _locationCtrl.text = filter.locationFilter;
    _selectedSkills.addAll(filter.selectedSkills);
    if (filter.minSalary != null || filter.maxSalary != null) {
      _useSalaryFilter = true;
      _salaryRange = RangeValues(
        filter.minSalary ?? 0,
        filter.maxSalary ?? 200000,
      );
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Jobs',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () {
                    ref.read(jobFilterProvider.notifier).clearAll();
                    Navigator.pop(context);
                  },
                  child: Text('Clear all',
                      style: GoogleFonts.inter(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Location filter
            _sectionTitle('Location'),
            const SizedBox(height: 8),
            TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Cairo, Remote...',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Skills filter
            _sectionTitle('Skills'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillCtrl,
                    decoration: InputDecoration(
                      hintText: 'Add a skill...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _addSkill,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _addSkill(_skillCtrl.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_selectedSkills.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedSkills
                    .map((skill) => Chip(
                          label: Text(skill,
                              style: GoogleFonts.inter(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setState(() => _selectedSkills.remove(skill)),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.08),
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 20),

            // Salary range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Salary Range'),
                Switch(
                  value: _useSalaryFilter,
                  onChanged: (v) => setState(() => _useSalaryFilter = v),
                  activeColor: AppColors.primary, // ignore: deprecated_member_use
                ),
              ],
            ),
            if (_useSalaryFilter) ...[
              RangeSlider(
                values: _salaryRange,
                min: 0,
                max: 200000,
                divisions: 40,
                activeColor: AppColors.primary,
                labels: RangeLabels(
                  '\$${(_salaryRange.start / 1000).round()}k',
                  '\$${(_salaryRange.end / 1000).round()}k',
                ),
                onChanged: (v) => setState(() => _salaryRange = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '\$${(_salaryRange.start / 1000).round()}k',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary)),
                  Text(
                      '\$${(_salaryRange.end / 1000).round()}k',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Apply Filters',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isNotEmpty && !_selectedSkills.contains(trimmed)) {
      setState(() => _selectedSkills.add(trimmed));
      _skillCtrl.clear();
    }
  }

  void _applyFilters() {
    final notifier = ref.read(jobFilterProvider.notifier);
    notifier.setLocation(_locationCtrl.text.trim());
    notifier.setSkills(List.from(_selectedSkills));
    notifier.setSalaryRange(
      _useSalaryFilter ? _salaryRange.start : null,
      _useSalaryFilter ? _salaryRange.end : null,
    );
    Navigator.pop(context);
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
}
