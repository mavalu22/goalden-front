import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/goal_colors.dart';
import '../../../domain/models/goal.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.openTaskCount,
    required this.totalTaskCount,
    this.onTap,
  });

  final Goal goal;
  final int openTaskCount;
  final int totalTaskCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gc = GoalColors.fromId(goal.color);
    final progress = totalTaskCount > 0
        ? (totalTaskCount - openTaskCount) / totalTaskCount
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: gc.soft,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: gc.base, width: 3),
              top: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: const TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (goal.starred) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.star_rounded, color: gc.base, size: 16),
                    ],
                  ],
                ),

                // ── Description ───────────────────────────────────
                if (goal.description != null && goal.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    goal.description!,
                    style: const TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // ── Progress bar ──────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(gc.base),
                    minHeight: 3,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Footer row ────────────────────────────────────
                Row(
                  children: [
                    Text(
                      '$openTaskCount open / $totalTaskCount total',
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (goal.deadline != null)
                      Text(
                        DateFormat('MMM d').format(goal.deadline!),
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 11,
                          color: gc.base,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
