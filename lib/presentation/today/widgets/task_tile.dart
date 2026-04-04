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
import '../../shared/widgets/pressable.dart';
import 'task_form_sheet.dart';

class TaskTile extends ConsumerStatefulWidget {
  const TaskTile({super.key, required this.task, required this.index});

  final Task task;

  /// Index within the reorderable list — used to attach [ReorderableDragStartListener]
  /// to the chevron button so long-pressing it activates drag-to-reorder.
  final int index;

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;
  bool _prevDone = false;

  late TextEditingController _noteController;

  bool _rowHovered = false;
  bool _rowPressed = false;
  bool _noteHovered = false;
  bool _priorityHovered = false;
  bool _priorityPressed = false;

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

    return ClipRect(
      child: Slidable(
      key: ValueKey(widget.task.id),
      // Swipe right → postpone action
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.35,
        children: [
          CustomSlidableAction(
            onPressed: (ctx) async {
              final picked = await showPostponeSheet(ctx);
              if (picked != null) {
                final newDate = DateTime(
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
              left: Radius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
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
      // Swipe left → remove action
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.3,
        dismissible: DismissiblePane(
          onDismissed: () =>
              ref.read(taskActionsProvider.notifier).deleteTask(widget.task.id),
        ),
        children: [
          CustomSlidableAction(
            onPressed: (_) =>
                ref.read(taskActionsProvider.notifier).deleteTask(widget.task.id),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.white),
                SizedBox(height: 4),
                Text(
                  'Remove',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
        child: MouseRegion(
          onEnter: (_) => setState(() => _rowHovered = true),
          onExit: (_) => setState(() => _rowHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
          onTap: _toggleExpanded,
          onTapDown: (_) => setState(() => _rowPressed = true),
          onTapUp: (_) => setState(() => _rowPressed = false),
          onTapCancel: () => setState(() => _rowPressed = false),
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
          scale: _rowPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _rowHovered && !isExpanded
                ? AppColors.surface.withValues(alpha: 0.85)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExpanded
                  ? AppColors.goldenBorder
                  : _rowHovered
                      ? AppColors.goldenBorder.withValues(alpha: 0.5)
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
                    Pressable(
                      onTap: () => ref
                          .read(taskActionsProvider.notifier)
                          .toggleDone(widget.task),
                      scaleFactor: 0.88,
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
                    const SizedBox(width: AppSpacing.sm),
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          Icons.drag_handle,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
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
                                // Note field with hover indicator
                                MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => _noteHovered = true),
                                  onExit: (_) =>
                                      setState(() => _noteHovered = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _noteHovered
                                            ? AppColors.goldenBorder
                                                .withValues(alpha: 0.4)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: TextField(
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
                                    ),
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
                                    // Edit button
                                    Pressable(
                                      onTap: () => showTaskEditForm(
                                        context,
                                        task: widget.task,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      hoverColor: AppColors.golden
                                          .withValues(alpha: 0.1),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xs,
                                          vertical: 3,
                                        ),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 14,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    // Priority toggle with hover indicator
                                    MouseRegion(
                                      onEnter: (_) => setState(
                                          () => _priorityHovered = true),
                                      onExit: (_) => setState(
                                          () => _priorityHovered = false),
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                      onTap: _togglePriority,
                                      onTapDown: (_) => setState(
                                          () => _priorityPressed = true),
                                      onTapUp: (_) => setState(
                                          () => _priorityPressed = false),
                                      onTapCancel: () => setState(
                                          () => _priorityPressed = false),
                                      child: AnimatedScale(
                                      scale: _priorityPressed ? 0.94 : 1.0,
                                      duration:
                                          const Duration(milliseconds: 100),
                                      curve: Curves.easeOut,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
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
                                                : _priorityHovered
                                                    ? AppColors.goldenBorder
                                                        .withValues(alpha: 0.5)
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
                                      ),   // AnimatedScale
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
        ),   // AnimatedScale
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

