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

class DayColumn extends ConsumerStatefulWidget {
  const DayColumn({
    super.key,
    required this.date,
    required this.tasks,
  });

  final DateTime date;
  final List<Task> tasks;

  @override
  ConsumerState<DayColumn> createState() => _DayColumnState();
}

class _DayColumnState extends ConsumerState<DayColumn> {
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
    final column = _buildColumn();
    if (_isPast) {
      return Opacity(opacity: 0.5, child: column);
    }
    return column;
  }

  Widget _buildColumn() {
    final completed = widget.tasks.where((t) => t.done).length;
    final total = widget.tasks.length;
    final weekdayAbbr = DateFormat('EEE').format(widget.date).toUpperCase();
    final dayNum = widget.date.day.toString();

    final borderColor = _isToday ? AppColors.goldenBorder : AppColors.border;
    final bgColor = _isToday
        ? AppColors.golden.withValues(alpha: 0.12)
        : Colors.transparent;
    final borderWidth = _isToday ? 1.5 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — tapping navigates to the day detail screen
          Pressable(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DayDetailScreen(date: widget.date),
              ),
            ),
            child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    if (_isToday) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.golden,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.background,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dayNum,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color:
                        _isToday ? AppColors.golden : AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _ProgressCounter(completed: completed, total: total),
                ],
              ],
            ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Task list (scrollable)
          Expanded(
            child: DragTarget<Task>(
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
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: isHovered
                        ? Border.all(color: AppColors.goldenBorder)
                        : null,
                  ),
                  child: widget.tasks.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            'No tasks',
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          itemCount: widget.tasks.length,
                          itemBuilder: (context, index) {
                            return _ColumnTaskRow(
                              task: widget.tasks[index],
                              isPast: _isPast,
                              date: widget.date,
                            );
                          },
                        ),
                );
              },
            ),
          ),
          // Add task button
          if (!_isPast)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Pressable(
                onTap: () => showTaskForm(context, defaultDate: widget.date),
                borderRadius: BorderRadius.circular(8),
                hoverColor: AppColors.golden.withValues(alpha: 0.08),
                child: Container(
                  width: double.infinity,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Progress counter ─────────────────────────────────────────────────────────

class _ProgressCounter extends StatelessWidget {
  const _ProgressCounter({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? completed / total : 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$completed/$total',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: completed > 0 ? AppColors.golden : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 28,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.golden),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Column task row ──────────────────────────────────────────────────────────

class _ColumnTaskRow extends ConsumerWidget {
  const _ColumnTaskRow({
    required this.task,
    required this.isPast,
    required this.date,
  });

  final Task task;
  final bool isPast;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalColorMap = ref.watch(goalColorMapProvider);
    final gc = task.goalId != null ? goalColorMap[task.goalId] : null;
    final row = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: task.done ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: AppSpacing.sm),
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
          horizontal: gc != null ? AppSpacing.sm : AppSpacing.xs,
          vertical: 3,
        ),
        child: Row(
          children: [
            Pressable(
              onTap: isPast
                  ? null
                  : () =>
                      ref.read(taskActionsProvider.notifier).toggleDone(task),
              scaleFactor: 0.88,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 16,
                height: 16,
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
                        size: 10,
                        color: AppColors.background,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (task.startTimeMinutes != null &&
                task.endTimeMinutes != null) ...[
              Text(
                _compactTimeRange(
                    task.startTimeMinutes!, task.endTimeMinutes!),
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isPast
                    ? null
                    : () => showTaskEditForm(context, task: task),
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 12,
                    color: task.done
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textMuted,
                    decorationThickness: task.done ? 2.0 : null,
                  ),
                ),
              ),
            ),
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
                fontSize: 12,
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

  static String _compactTimeRange(int startMin, int endMin) {
    String fmt(int mins) {
      final h = mins ~/ 60;
      final m = mins % 60;
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return m == 0 ? '$h12' : '$h12:${m.toString().padLeft(2, '0')}';
    }
    final startPeriod = startMin < 720 ? 'a' : 'p';
    final endPeriod = endMin < 720 ? 'a' : 'p';
    if (startPeriod == endPeriod) {
      return '${fmt(startMin)}–${fmt(endMin)}$endPeriod';
    }
    return '${fmt(startMin)}$startPeriod–${fmt(endMin)}$endPeriod';
  }
}

