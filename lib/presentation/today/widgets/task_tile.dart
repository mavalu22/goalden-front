import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/task.dart';
import '../providers/today_provider.dart';
import 'postpone_sheet.dart';

class TaskTile extends ConsumerStatefulWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;
  bool _prevDone = false;

  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _prevDone = widget.task.done;
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _checkScale = Tween<double>(begin: 1.0, end: 1.0).animate(_checkController);
    _noteController =
        TextEditingController(text: widget.task.note ?? '');
  }

  @override
  void didUpdateWidget(TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_prevDone && widget.task.done) _playPop();
    _prevDone = widget.task.done;
    // Sync note controller if task updated externally
    if (oldWidget.task.note != widget.task.note &&
        _noteController.text != (widget.task.note ?? '')) {
      _noteController.text = widget.task.note ?? '';
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _playPop() {
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));
    _checkController
      ..reset()
      ..forward();
  }

  void _toggleExpanded() {
    final current = ref.read(expandedTaskIdProvider);
    ref.read(expandedTaskIdProvider.notifier).state =
        current == widget.task.id ? null : widget.task.id;
  }

  void _saveNote(String value) {
    final trimmed = value.trim().isEmpty ? null : value.trim();
    if (trimmed == widget.task.note) return;
    ref
        .read(taskActionsProvider.notifier)
        .updateTask(widget.task.copyWith(note: trimmed));
  }

  void _togglePriority() {
    final next = widget.task.priority == TaskPriority.high
        ? TaskPriority.normal
        : TaskPriority.high;
    ref
        .read(taskActionsProvider.notifier)
        .updateTask(widget.task.copyWith(priority: next));
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.done;
    final isHigh = widget.task.priority == TaskPriority.high && !isCompleted;
    final expandedId = ref.watch(expandedTaskIdProvider);
    final isExpanded = expandedId == widget.task.id;

    return Slidable(
      key: ValueKey(widget.task.id),
      // Swipe left → postpone action
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.35,
        children: [
          CustomSlidableAction(
            onPressed: (ctx) async {
              final picked = await showPostponeSheet(ctx);
              if (picked != null) {
                final newDate = DateTime.utc(
                  picked.year,
                  picked.month,
                  picked.day,
                );
                ref.read(taskActionsProvider.notifier).updateTask(
                      widget.task.copyWith(date: newDate),
                    );
              }
            },
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textSecondary,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward, size: 18, color: AppColors.golden),
                SizedBox(height: 4),
                Text(
                  'Postpone',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.golden,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isCompleted ? 0.45 : 1.0,
        child: GestureDetector(
          onTap: _toggleExpanded,
          behavior: HitTestBehavior.opaque,
          child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExpanded
                  ? AppColors.goldenBorder
                  : isHigh
                      ? AppColors.goldenBorder
                      : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Main row ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    // Checkbox — stops tap from propagating to expand
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        ref
                            .read(taskActionsProvider.notifier)
                            .toggleDone(widget.task);
                      },
                      child: _buildCheckbox(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Align(
                          key: ValueKey(isCompleted),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.task.title,
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isCompleted
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isHigh && !isExpanded) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const _HighBadge(),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),

              // ── Expansion panel ───────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderSubtle,
                            indent: AppSpacing.lg,
                            endIndent: AppSpacing.lg,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.sm,
                              AppSpacing.lg,
                              AppSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Note field
                                TextField(
                                  controller: _noteController,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.bodyFont,
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Add a note...',
                                    hintStyle: TextStyle(
                                      fontFamily: AppTypography.bodyFont,
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  maxLines: null,
                                  onChanged: (_) {},
                                  onEditingComplete: () =>
                                      _saveNote(_noteController.text),
                                  onTapOutside: (_) =>
                                      _saveNote(_noteController.text),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                // Meta row: date + priority toggle
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      DateFormat('MMM d')
                                          .format(widget.task.date),
                                      style: const TextStyle(
                                        fontFamily: AppTypography.bodyFont,
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Priority toggle
                                    GestureDetector(
                                      onTap: _togglePriority,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.task.priority ==
                                                  TaskPriority.high
                                              ? AppColors.goldenDim
                                              : AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: widget.task.priority ==
                                                    TaskPriority.high
                                                ? AppColors.goldenBorder
                                                : AppColors.border,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.flag_outlined,
                                              size: 12,
                                              color: widget.task.priority ==
                                                      TaskPriority.high
                                                  ? AppColors.golden
                                                  : AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              widget.task.priority ==
                                                      TaskPriority.high
                                                  ? 'High'
                                                  : 'Normal',
                                              style: TextStyle(
                                                fontFamily:
                                                    AppTypography.bodyFont,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: widget.task.priority ==
                                                        TaskPriority.high
                                                    ? AppColors.golden
                                                    : AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return AnimatedBuilder(
      animation: _checkController,
      builder: (_, __) => Transform.scale(
        scale: _checkScale.value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.task.done ? AppColors.golden : Colors.transparent,
            border: Border.all(
              color: widget.task.done ? AppColors.golden : AppColors.border,
              width: 1.5,
            ),
          ),
          child: widget.task.done
              ? const Icon(
                  Icons.check,
                  size: 13,
                  color: AppColors.background,
                )
              : null,
        ),
      ),
    );
  }
}

class _HighBadge extends StatelessWidget {
  const _HighBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.goldenDim,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.goldenBorder),
      ),
      child: const Text(
        'HIGH',
        style: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.golden,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Sorts tasks: high priority uncompleted → normal uncompleted → completed.
/// Within each group, preserves creation order.
List<Task> sortTasks(List<Task> tasks) {
  final highUncompleted = tasks
      .where((t) => !t.done && t.priority == TaskPriority.high)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final normalUncompleted = tasks
      .where((t) => !t.done && t.priority == TaskPriority.normal)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final completed = tasks.where((t) => t.done).toList()
    ..sort((a, b) {
      final ca = a.completedAt ?? a.createdAt;
      final cb = b.completedAt ?? b.createdAt;
      return ca.compareTo(cb);
    });

  return [...highUncompleted, ...normalUncompleted, ...completed];
}
