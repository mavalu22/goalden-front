import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Shows a bottom sheet for picking a postpone date.
/// Returns the selected [DateTime] or null if dismissed.
Future<DateTime?> showPostponeSheet(BuildContext context) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PostponeSheet(),
  );
}

class _PostponeSheet extends StatelessWidget {
  const _PostponeSheet();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final next7 = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day + i + 1),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Postpone to',
                style: TextStyle(
                  fontFamily: AppTypography.displayFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Tomorrow quick-pick (highlighted)
              _TomorrowOption(date: tomorrow),
              const SizedBox(height: AppSpacing.lg),
              // 7-day grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                children: next7.map((d) => _DayCell(date: d)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TomorrowOption extends StatelessWidget {
  const _TomorrowOption({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(date),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.goldenDim,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldenBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wb_sunny_outlined,
              size: 18,
              color: AppColors.golden,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Tomorrow',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.golden,
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('EEE, MMM d').format(date),
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                color: AppColors.golden,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final dayAbbr = DateFormat('E').format(date).substring(0, 1);
    final dayNum = date.day.toString();

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(date),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayAbbr,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
