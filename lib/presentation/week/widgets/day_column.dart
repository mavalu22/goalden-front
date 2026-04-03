import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/task.dart';
import '../../today/providers/today_provider.dart';

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
  bool _showQuickAdd = false;
  final _addController = TextEditingController();
  final _addFocusNode = FocusNode();

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

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

  Future<void> _submitQuickAdd() async {
    final title = _addController.text.trim();
    if (title.isEmpty) {
      setState(() => _showQuickAdd = false);
      return;
    }
    _addController.clear();
    setState(() => _showQuickAdd = false);
    await ref
        .read(taskActionsProvider.notifier)
        .createTask(title, date: widget.date);
  }

  void _showAdd() {
    setState(() => _showQuickAdd = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addFocusNode.requestFocus();
    });
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
    final bgColor = _isToday ? AppColors.goldenDim : Colors.transparent;
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
          // Header
          Padding(
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
          // Quick add input or add button
          if (!_isPast)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: _showQuickAdd
                  ? _QuickAddInput(
                      controller: _addController,
                      focusNode: _addFocusNode,
                      onSubmit: _submitQuickAdd,
                      onCancel: () {
                        _addController.clear();
                        setState(() => _showQuickAdd = false);
                      },
                    )
                  : GestureDetector(
                      onTap: _showAdd,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$completed',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: completed > 0 ? AppColors.golden : AppColors.textMuted,
          ),
        ),
        Text(
          ' / $total',
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 11,
            color: AppColors.textMuted,
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
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 3,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: isPast
                ? null
                : () =>
                    ref.read(taskActionsProvider.notifier).toggleDone(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.done ? AppColors.golden : Colors.transparent,
                border: Border.all(
                  color: task.done
                      ? AppColors.golden
                      : isPast
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
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
          Expanded(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 12,
                color: task.done ? AppColors.textMuted : AppColors.textPrimary,
                decoration: task.done ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        ],
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
}

// ─── Quick add input ──────────────────────────────────────────────────────────

class _QuickAddInput extends StatelessWidget {
  const _QuickAddInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.goldenBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'New task...',
                hintStyle: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
