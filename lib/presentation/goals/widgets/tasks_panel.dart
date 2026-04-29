import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/widgets/pressable.dart';
import '../../today/providers/today_provider.dart';
import '../../today/widgets/task_form_sheet.dart';
import '../providers/goal_provider.dart';

enum _TaskFilter { thisWeek, open, all }

class TasksPanel extends ConsumerStatefulWidget {
  const TasksPanel({
    super.key,
    required this.goalId,
    required this.goalTitle,
    required this.gc,
  });

  final String goalId;
  final String goalTitle;
  final GoalColor gc;

  @override
  ConsumerState<TasksPanel> createState() => _TasksPanelState();
}

class _TasksPanelState extends ConsumerState<TasksPanel> {
  _TaskFilter _filter = _TaskFilter.thisWeek;

  @override
  Widget build(BuildContext context) {
    final gc = widget.gc;
    final tasksAsync = ref.watch(tasksForGoalProvider(widget.goalId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: gc.base, width: 3),
          left: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              'Tasks',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: gc.base,
              ),
            ),
          ),

          // ── Filter chips ────────────────────────────────────────
          tasksAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (tasks) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final weekStart =
                  today.subtract(Duration(days: today.weekday - 1));
              final weekEnd = weekStart.add(const Duration(days: 7));

              final thisWeekCount = tasks
                  .where((t) =>
                      !t.date.isBefore(weekStart) && t.date.isBefore(weekEnd))
                  .length;
              final openCount = tasks.where((t) => !t.done).length;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    _Chip(
                      label: 'This week · $thisWeekCount',
                      selected: _filter == _TaskFilter.thisWeek,
                      gc: gc,
                      onTap: () => setState(() => _filter = _TaskFilter.thisWeek),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _Chip(
                      label: 'Open · $openCount',
                      selected: _filter == _TaskFilter.open,
                      gc: gc,
                      onTap: () => setState(() => _filter = _TaskFilter.open),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _Chip(
                      label: 'All',
                      selected: _filter == _TaskFilter.all,
                      gc: gc,
                      onTap: () => setState(() => _filter = _TaskFilter.all),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xs),
          const Divider(height: 1, color: AppColors.border),

          // ── Add task button ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Pressable(
              onTap: () => showTaskForm(context, defaultGoalId: widget.goalId),
              borderRadius: BorderRadius.circular(8),
              hoverColor: gc.base.withValues(alpha: 0.08),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 14, color: gc.base),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Add task',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 12,
                        color: gc.base,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ── Task list ───────────────────────────────────────────
          tasksAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.golden, strokeWidth: 2),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Failed to load tasks.',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            data: (allTasks) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final weekStart =
                  today.subtract(Duration(days: today.weekday - 1));
              final weekEnd = weekStart.add(const Duration(days: 7));

              final filtered = switch (_filter) {
                _TaskFilter.thisWeek => allTasks
                    .where((t) =>
                        !t.date.isBefore(weekStart) && t.date.isBefore(weekEnd))
                    .toList(),
                _TaskFilter.open => allTasks.where((t) => !t.done).toList(),
                _TaskFilter.all => allTasks,
              };

              // Sort: undone → done; secondary by date.
              filtered.sort((a, b) {
                if (a.done != b.done) return a.done ? 1 : -1;
                return a.date.compareTo(b.date);
              });

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    _filter == _TaskFilter.thisWeek
                        ? 'No tasks this week.'
                        : _filter == _TaskFilter.open
                            ? 'No open tasks.'
                            : 'No tasks linked yet.',
                    style: const TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }

              return Column(
                children: filtered
                    .map((task) => _GoalTaskRow(
                          task: task,
                          gc: gc,
                          onToggle: () => ref
                              .read(taskActionsProvider.notifier)
                              .toggleDone(task),
                          onTap: () =>
                              showTaskEditForm(context, task: task),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.gc,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final GoalColor gc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? gc.dim : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? gc.base : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? gc.base : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Task row ──────────────────────────────────────────────────────────────────

class _GoalTaskRow extends StatelessWidget {
  const _GoalTaskRow({
    required this.task,
    required this.gc,
    required this.onToggle,
    required this.onTap,
  });

  final Task task;
  final GoalColor gc;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDone = task.done;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Opacity(
          opacity: isDone ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: gc.dim,
              borderRadius: BorderRadius.circular(6),
              border: Border(
                left: BorderSide(color: gc.base, width: 3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: onToggle,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? gc.base : Colors.transparent,
                          border: Border.all(
                            color: gc.base,
                            width: isDone ? 0 : 1.5,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 11, color: AppColors.background)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Title
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Date label
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _formatDate(task.date),
                    style: const TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }
}

