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
    this.onEdit,
    this.onToggleStar,
    this.onArchive,
    this.onDelete,
  });

  final Goal goal;
  final int openTaskCount;
  final int totalTaskCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStar;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final gc = GoalColors.fromId(goal.color);
    final progress = totalTaskCount > 0
        ? (totalTaskCount - openTaskCount) / totalTaskCount
        : 0.0;
    final isArchived = goal.status == GoalStatus.archived;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.star_rounded, color: gc.base, size: 16),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    _KebabMenu(
                      goal: goal,
                      isArchived: isArchived,
                      onEdit: onEdit,
                      onToggleStar: onToggleStar,
                      onArchive: onArchive,
                      onDelete: onDelete,
                    ),
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

// ── Kebab menu ────────────────────────────────────────────────────────────────

class _KebabMenu extends StatelessWidget {
  const _KebabMenu({
    required this.goal,
    required this.isArchived,
    this.onEdit,
    this.onToggleStar,
    this.onArchive,
    this.onDelete,
  });

  final Goal goal;
  final bool isArchived;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStar;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // absorb tap so card onTap doesn't fire
      child: PopupMenuButton<_GoalAction>(
        onSelected: (action) => _handleAction(action),
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.more_vert,
          color: AppColors.textMuted,
          size: 16,
        ),
        color: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
        itemBuilder: (_) => [
          _menuItem(
            value: _GoalAction.edit,
            icon: Icons.edit_outlined,
            label: 'Edit',
          ),
          _menuItem(
            value: _GoalAction.toggleStar,
            icon: goal.starred ? Icons.star_outline : Icons.star_rounded,
            label: goal.starred ? 'Unstar' : 'Star',
          ),
          _menuItem(
            value: _GoalAction.archive,
            icon: isArchived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined,
            label: isArchived ? 'Unarchive' : 'Archive',
          ),
          const PopupMenuDivider(height: 1),
          _menuItem(
            value: _GoalAction.delete,
            icon: Icons.delete_outline,
            label: 'Delete',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  void _handleAction(_GoalAction action) {
    switch (action) {
      case _GoalAction.edit:
        onEdit?.call();
      case _GoalAction.toggleStar:
        onToggleStar?.call();
      case _GoalAction.archive:
        onArchive?.call();
      case _GoalAction.delete:
        onDelete?.call();
    }
  }

  PopupMenuItem<_GoalAction> _menuItem({
    required _GoalAction value,
    required IconData icon,
    required String label,
    Color color = AppColors.textPrimary,
  }) {
    return PopupMenuItem<_GoalAction>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum _GoalAction { edit, toggleStar, archive, delete }
