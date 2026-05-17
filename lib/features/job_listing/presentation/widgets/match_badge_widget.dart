import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/job_matching_service.dart';

class MatchBadgeWidget extends StatelessWidget {
  final MatchResult result;

  const MatchBadgeWidget({super.key, required this.result});

  Color _color(MatchCategory c) {
    switch (c) {
      case MatchCategory.excellent:
        return AppColors.success;
      case MatchCategory.good:
        return AppColors.info;
      case MatchCategory.fair:
        return AppColors.warning;
      case MatchCategory.low:
        return AppColors.textTertiary;
    }
  }

  String _label(MatchCategory c) {
    switch (c) {
      case MatchCategory.excellent:
        return 'Excellent';
      case MatchCategory.good:
        return 'Good';
      case MatchCategory.fair:
        return 'Fair';
      case MatchCategory.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(result.category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '★ ${result.score}% · ${_label(result.category)}',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
