import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../goals/providers/goal_provider.dart';
import '../../shared/widgets/pressable.dart';
import '../../today/providers/today_provider.dart';
import '../../today/widgets/task_form_sheet.dart';
import '../screens/day_detail_screen.dart';

class DayCard extends ConsumerStatefulWidget {
  const DayCard({
    super.key,
    required this.date,
    required this.tasks,
  });

  final DateTime date;
  final List<Task> tasks;

  @override
  ConsumerState<DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<DayCard> {
  bool get _isToday {
    final now = DateTime.now();
    return widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;
  }

  bool get _isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.date.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final card = _buildCard();
    if (_isPast) {
      return Opacity(opacity: 0.5, child: card);
    }
    return card;
  }

  Widget _buildCard() {
    final completed = widget.tasks.where((t) => t.done).length;
    final total = widget.tasks.length;
    final weekdayAbbr = DateFormat('EEE').format(widget.date).toUpperCase();
    final dayNum = widget.date.day.toString();
    final dayName = _isToday ? 'Today' : DateFormat('EEEE').format(widget.date);

    final borderColor = _isToday ? AppColors.goldenBorder : AppColors.border;
    final bgColor = _isToday
        ? AppColors.golden.withValues(alpha: 0.12)
        : Colors.transparent;
    final borderWidth = _isToday ? 1.5 : 1.0;

    // Show max 3 tasks, then "+N more"
    final visibleTasks = widget.tasks.take(3).toList();
    final remaining = widget.tasks.length - visibleTasks.length;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: day identification block
            SizedBox(
              width: 44,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekdayAbbr,
                    style: const TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _isToday ? AppColors.golden : AppColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Right: content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Day name + progress counter + add button
                  Row(
                    children: [
                      Expanded(
                        child: Pressable(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  DayDetailScreen(date: widget.date),
                            ),
                          ),
                          child: Text(
                            dayName,
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isToday
                                  ? AppColors.golden
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      if (total > 0) ...[
                        Text(
                          '$completed/$total',
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: completed > 0
                                ? AppColors.golden
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (!_isPast)
                        Pressable(
                          onTap: () => showTaskForm(context, defaultDate: widget.date),
                          borderRadius: BorderRadius.circular(8),
                          hoverColor: AppColors.golden.withValues(alpha: 0.08),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Segmented goal progress bar
                  if (total > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _GoalSegmentBar(tasks: widget.tasks),
                  ],
                  // Divider between header and task list
                  if (widget.tasks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1, color: AppColors.border),
                  ],
                  // Task list or empty state
                  if (widget.tasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'No tasks',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  else if (widget.tasks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    DragTarget<Task>(
                      onWillAcceptWithDetails: (details) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        return !widget.date.isBefore(today);
                      },
                      onAcceptWithDetails: (details) {
                        final task = details.data;
                        ref.read(taskActionsProvider.notifier).updateTask(
                              task.copyWith(
                                date: DateTime.utc(
                                  widget.date.year,
                                  widget.date.month,
                                  widget.date.day,
                                ),
                              ),
                            );
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovered = candidateData.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isHovered
                                ? Border.all(color: AppColors.goldenBorder)
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final task in visibleTasks)
                                _TaskRow(
                                  task: task,
                                  isPast: _isPast,
                                  date: widget.date,
                                ),
                              if (remaining > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.xs,
                                  ),
                                  child: Text(
                                    '+$remaining more',
                                    style: const TextStyle(
                                      fontFamily: AppTypography.bodyFont,
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  // Empty state drag target
                  if (widget.tasks.isEmpty)
                    DragTarget<Task>(
                      onWillAcceptWithDetails: (details) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        return !widget.date.isBefore(today);
                      },
                      onAcceptWithDetails: (details) {
                        final task = details.data;
                        ref.read(taskActionsProvider.notifier).updateTask(
                              task.copyWith(
                                date: DateTime.utc(
                                  widget.date.year,
                                  widget.date.month,
                                  widget.date.day,
                                ),
                              ),
                            );
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovered = candidateData.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: isHovered ? 40 : 0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isHovered
                                ? Border.all(color: AppColors.goldenBorder)
                                : null,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Goal segment bar ─────────────────────────────────────────────────────────

class _GoalSegmentBar extends ConsumerWidget {
  const _GoalSegmentBar({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalColorMap = ref.watch(goalColorMapProvider);
    final total = tasks.length;
    if (total == 0) return const SizedBox.shrink();

    // Count tasks per goalId; null goalId → neutral bucket
    final counts = <String?, int>{};
    for (final t in tasks) {
      counts[t.goalId] = (counts[t.goalId] ?? 0) + 1;
    }

    // Build segments: goal segments first (sorted by count desc), then neutral
    final segments = <({Color color, int count})>[];
    for (final entry in counts.entries.where((e) => e.key != null)) {
      final gc = goalColorMap[entry.key];
      if (gc != null) {
        segments.add((color: gc.base, count: entry.value));
      } else {
        // Goal no longer active or missing — treat as neutral
        final neutralEntry = segments.where((s) => s.color == AppColors.border);
        if (neutralEntry.isEmpty) {
          segments.add((color: AppColors.border, count: entry.value));
        }
      }
    }
    segments.sort((a, b) => b.count.compareTo(a.count));
    // Append neutral (no-goal) segment at the end
    final neutralCount = counts[null] ?? 0;
    if (neutralCount > 0) {
      segments.add((color: AppColors.border, count: neutralCount));
    }

    return Semantics(
      label: 'Task distribution: ${segments.map((s) => '${s.count} tasks').join(', ')}',
      child: SizedBox(
        height: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Row(
            children: [
              for (final seg in segments)
                Flexible(
                  flex: seg.count,
                  child: Container(color: seg.color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Task row ─────────────────────────────────────────────────────────────────

class _TaskRow extends ConsumerWidget {
  const _TaskRow({
    required this.task,
    required this.isPast,
    required this.date,
  });

  final Task task;
  final bool isPast;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHigh = task.priority == TaskPriority.high && !task.done;
    final goalColorMap = ref.watch(goalColorMapProvider);
    final gc = task.goalId != null ? goalColorMap[task.goalId] : null;

    final row = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: task.done ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: gc != null
            ? BoxDecoration(
                color: gc.dim,
                borderRadius: BorderRadius.circular(4),
                border: Border(
                  left: BorderSide(color: gc.base, width: 3),
                ),
              )
            : null,
        child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: gc != null ? AppSpacing.sm : 0,
          vertical: 3,
        ),
        child: Row(
          children: [
            // Checkbox
            Pressable(
              onTap: isPast
                  ? null
                  : () =>
                      ref.read(taskActionsProvider.notifier).toggleDone(task),
              scaleFactor: 0.88,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.done
                      ? (gc?.base ?? AppColors.golden)
                      : Colors.transparent,
                  border: Border.all(
                    color: task.done
                        ? (gc?.base ?? AppColors.golden)
                        : isPast
                            ? AppColors.textMuted
                            : (gc?.base ?? AppColors.textSecondary),
                    width: 1.5,
                  ),
                ),
                child: task.done
                    ? const Icon(
                        Icons.check,
                        size: 11,
                        color: AppColors.background,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Title + optional time — tappable to open detail
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isPast
                    ? null
                    : () => showTaskEditForm(context, task: task),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 13,
                        color: task.done
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration:
                            task.done ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textMuted,
                        decorationThickness: task.done ? 2.0 : null,
                      ),
                    ),
                    if (task.startTimeMinutes != null &&
                        task.endTimeMinutes != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        _shortTimeRange(
                            task.startTimeMinutes!, task.endTimeMinutes!),
                        style: const TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isHigh) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.golden,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );

    if (isPast) return row;

    return LongPressDraggable<Task>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.goldenBorder),
            ),
            child: Text(
              task.title,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: row),
      child: row,
    );
  }

  static String _shortTimeRange(int startMin, int endMin) {
    String fmt(int mins) {
      final h = mins ~/ 60;
      final m = mins % 60;
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return m == 0 ? '$h12' : '$h12:${m.toString().padLeft(2, '0')}';
    }
    final startPeriod = startMin < 720 ? 'AM' : 'PM';
    final endPeriod = endMin < 720 ? 'AM' : 'PM';
    if (startPeriod == endPeriod) {
      return '${fmt(startMin)}–${fmt(endMin)} $endPeriod';
    }
    return '${fmt(startMin)} $startPeriod–${fmt(endMin)} $endPeriod';
  }
}

