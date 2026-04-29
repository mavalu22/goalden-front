import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/goal_colors.dart';
import '../../../domain/models/goal.dart';
import '../providers/goal_provider.dart' show goalNextOpenTaskProvider, goalSevenDayActivityProvider;

class GoalCard extends ConsumerWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.openTaskCount,
    required this.totalTaskCount,
    this.onTap,
    this.onEdit,
    this.onArchive,
    this.onDelete,
  });

  final Goal goal;
  final int openTaskCount;
  final int totalTaskCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gc = GoalColors.fromId(goal.color);
    final doneCount = totalTaskCount - openTaskCount;
    final progress = totalTaskCount > 0 ? doneCount / totalTaskCount : 0.0;
    final isArchived = goal.status == GoalStatus.archived;

    final nextTask = ref.watch(goalNextOpenTaskProvider(goal.id)).valueOrNull;
    final sevenDayMap = ref.watch(goalSevenDayActivityProvider).valueOrNull;
    final sevenDays = sevenDayMap?[goal.id] ?? List.filled(7, false);

    // Stalled: no activity in last 7 days
    final stalledDays = _stalledDays(sevenDays);
    final isStalled = stalledDays >= 5 && totalTaskCount > 0;

    // Streak: consecutive days with activity (from today backwards)
    final streakCount = _streakCount(sevenDays);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: gc.base),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header row ─────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star_rounded, color: gc.base, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            goal.title,
                            style: const TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (isStalled)
                          _Badge(
                            label: 'stalled · ${stalledDays}d',
                            color: AppColors.error,
                          )
                        else if (streakCount >= 2)
                          _Badge(
                            label: '🔥 ${streakCount}d',
                            color: gc.base,
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        _KebabMenu(
                          goal: goal,
                          isArchived: isArchived,
                          onEdit: onEdit,
                          onArchive: onArchive,
                          onDelete: onDelete,
                        ),
                      ],
                    ),
    
                    // ── Sub-header ─────────────────────────────────────
                    const SizedBox(height: 4),
                    Text(
                      _subHeader(),
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 10,
                        color: AppColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
    
                    const SizedBox(height: AppSpacing.md),
    
                    // ── Progress bar ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation(gc.base),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: gc.base,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
    
                    // ── Tasks + deadline row ───────────────────────────
                    Row(
                      children: [
                        Text(
                          '$doneCount of $totalTaskCount tasks done',
                          style: const TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        if (goal.deadline != null)
                          _DeadlineChip(
                            deadline: goal.deadline!,
                            color: gc.base,
                          ),
                      ],
                    ),
    
                    // ── NEXT → box ─────────────────────────────────────
                    if (nextTask != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: gc.dim,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: gc.base.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'NEXT →',
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: gc.base,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                nextTask.title,
                                style: const TextStyle(
                                  fontFamily: AppTypography.bodyFont,
                                  fontSize: 11,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
    
                    // ── 7-day mini bars ────────────────────────────────
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        for (var i = 0; i < sevenDays.length; i++) ...[
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: sevenDays[i]
                                    ? gc.base
                                    : AppColors.border.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                          if (i < sevenDays.length - 1) const SizedBox(width: 3),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'M T W T F S S · last 7 days',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 8,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subHeader() {
    final parts = <String>[];
    if (goal.deadline != null) {
      parts.add('due ${DateFormat('MMM d').format(goal.deadline!)}');
    } else {
      parts.add('no deadline');
    }
    return parts.join(' · ');
  }

  static int _stalledDays(List<bool> days) {
    var count = 0;
    for (var i = days.length - 1; i >= 0; i--) {
      if (!days[i]) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  static int _streakCount(List<bool> days) {
    var count = 0;
    for (var i = days.length - 1; i >= 0; i--) {
      if (days[i]) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }
}

// ── Badge chip ────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Deadline chip ─────────────────────────────────────────────────────────────

class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({required this.deadline, required this.color});

  final DateTime deadline;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = deadline.difference(today).inDays;
    final label = daysLeft <= 0
        ? 'overdue'
        : daysLeft == 1
            ? '1 day left'
            : '$daysLeft days left';
    final textColor = daysLeft <= 7 ? AppColors.error : color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '⏰ ',
          style: TextStyle(fontSize: 9),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 10,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Kebab menu ────────────────────────────────────────────────────────────────

class _KebabMenu extends StatelessWidget {
  const _KebabMenu({
    required this.goal,
    required this.isArchived,
    this.onEdit,
    this.onArchive,
    this.onDelete,
  });

  final Goal goal;
  final bool isArchived;
  final VoidCallback? onEdit;
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

enum _GoalAction { edit, archive, delete }

// ── Empty slot card ───────────────────────────────────────────────────────────

class GoalEmptySlot extends StatelessWidget {
  const GoalEmptySlot({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 32,
                color: AppColors.textMuted,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Add another goal',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
