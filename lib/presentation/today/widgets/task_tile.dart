import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../goals/providers/goal_provider.dart';
import '../providers/today_provider.dart';
import 'postpone_sheet.dart';
import '../../shared/widgets/delete_confirmation_dialog.dart';
import '../../shared/widgets/pressable.dart';
import 'task_form_sheet.dart';

class TaskTile extends ConsumerStatefulWidget {
  const TaskTile({super.key, required this.task, required this.index});

  final Task task;

  /// Index within the reorderable list — used to attach [ReorderableDragStartListener]
  /// to the drag handle so long-pressing activates drag-to-reorder.
  final int index;

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;
  bool _prevDone = false;

  bool _rowHovered = false;
  bool _rowPressed = false;

  @override
  void initState() {
    super.initState();
    _prevDone = widget.task.done;
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _checkScale = Tween<double>(begin: 1.0, end: 1.0).animate(_checkController);
  }

  @override
  void didUpdateWidget(TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_prevDone && widget.task.done) _playPop();
    _prevDone = widget.task.done;
  }

  @override
  void dispose() {
    _checkController.dispose();
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

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  Future<void> _showContextMenu(TapDownDetails details) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
          details.globalPosition.dx, details.globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 8,
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: _ContextMenuItem(
              icon: Icons.edit_outlined, label: 'Edit'),
        ),
        const PopupMenuItem(
          value: 'postpone',
          child: _ContextMenuItem(
              icon: Icons.arrow_forward, label: 'Postpone'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: _ContextMenuItem(
              icon: Icons.delete_outline,
              label: 'Delete',
              color: AppColors.error),
        ),
      ],
    );

    if (!mounted) return;
    switch (result) {
      case 'edit':
        showTaskEditForm(context, task: widget.task);
      case 'postpone':
        _postpone();
      case 'delete':
        final dr = await showDeleteConfirmation(context, widget.task);
        if (mounted) _handleDeleteResult(dr);
    }
  }

  Future<void> _postpone() async {
    final picked = await showPostponeSheet(context);
    if (picked != null && mounted) {
      ref.read(taskActionsProvider.notifier).updateTask(
            widget.task.copyWith(
              date: DateTime(picked.year, picked.month, picked.day),
            ),
          );
    }
  }

  void _handleDeleteResult(DeleteResult result) {
    if (result == DeleteResult.cancelled) return;
    if (result == DeleteResult.allFuture) {
      final sourceId = widget.task.sourceTaskId ?? widget.task.id;
      ref.read(taskActionsProvider.notifier).deleteTask(
            sourceId,
            isRecurringSource: true,
          );
    } else {
      ref
          .read(taskActionsProvider.notifier)
          .deleteTask(widget.task.id, isRecurringSource: false);
    }
  }

  static String _formatTimeRange(int startMin, int endMin) {
    String fmt(int mins) {
      final h = mins ~/ 60;
      final m = mins % 60;
      final period = h < 12 ? 'AM' : 'PM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return m == 0 ? '$h12 $period' : '$h12:${m.toString().padLeft(2, '0')} $period';
    }
    return '${fmt(startMin)} – ${fmt(endMin)}';
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.done;
    final isHigh = widget.task.priority == TaskPriority.high && !isCompleted;
    final goalColorMap = ref.watch(goalColorMapProvider);
    final goalColor = widget.task.goalId != null
        ? goalColorMap[widget.task.goalId]
        : null;

    final tile = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Slidable(
        key: ValueKey(widget.task.id),
        // Swipe right → postpone
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
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
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
            ),
          ],
        ),
        // Swipe left → remove (with confirmation)
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.3,
          children: [
            CustomSlidableAction(
              onPressed: (ctx) async {
                final slidable = Slidable.of(ctx);
                slidable?.close();
                final result =
                    await showDeleteConfirmation(context, widget.task);
                if (!mounted) return;
                _handleDeleteResult(result);
              },
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
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
              onTap: () => showTaskEditForm(context, task: widget.task),
              onTapDown: (_) => setState(() => _rowPressed = true),
              onTapUp: (_) => setState(() => _rowPressed = false),
              onTapCancel: () => setState(() => _rowPressed = false),
              onSecondaryTapDown:
                  _isDesktop ? _showContextMenu : null,
              behavior: HitTestBehavior.opaque,
              child: AnimatedScale(
                scale: _rowPressed ? 0.98 : 1.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: goalColor != null
                        ? goalColor.dim
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: () {
                      final sideColor = _rowHovered
                          ? AppColors.goldenBorder.withValues(alpha: 0.5)
                          : isHigh
                              ? AppColors.goldenBorder
                              : AppColors.border;
                      if (goalColor != null) {
                        return Border(
                          top: BorderSide(color: sideColor),
                          right: BorderSide(color: sideColor),
                          bottom: BorderSide(color: sideColor),
                          left: BorderSide(color: goalColor.base, width: 3),
                        );
                      }
                      return Border.all(color: sideColor);
                    }(),
                  ),
                  child: Stack(
                    children: [
                      // Normal row content
                      Row(
                        children: [
                          // Checkbox — stops tap from propagating to open detail
                          Pressable(
                            onTap: () => ref
                                .read(taskActionsProvider.notifier)
                                .toggleDone(widget.task),
                            scaleFactor: 0.88,
                            child: _buildCheckbox(),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
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
                                if (widget.task.startTimeMinutes != null &&
                                    widget.task.endTimeMinutes != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTimeRange(
                                      widget.task.startTimeMinutes!,
                                      widget.task.endTimeMinutes!,
                                    ),
                                    style: const TextStyle(
                                      fontFamily: AppTypography.bodyFont,
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.task.sourceTaskId != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(
                              Icons.repeat,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ],
                          if (isHigh) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const _HighBadge(),
                          ],
                          // Drag handle (hidden on desktop hover when action bar shows)
                          AnimatedOpacity(
                            opacity: _isDesktop && _rowHovered ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: ReorderableDragStartListener(
                              index: widget.index,
                              child: const MouseRegion(
                                cursor: SystemMouseCursors.grab,
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 2),
                                  child: Icon(
                                    Icons.drag_handle,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Desktop hover action bar (right-side overlay)
                      if (_isDesktop)
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: _rowHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: IgnorePointer(
                              ignoring: !_rowHovered,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.surfaceElevated
                                            .withValues(alpha: 0.0),
                                        AppColors.surfaceElevated,
                                      ],
                                      stops: const [0.0, 0.4],
                                    ),
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(12),
                                    ),
                                  ),
                                  padding: const EdgeInsets.only(
                                      left: AppSpacing.xxl),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _HoverAction(
                                        icon: Icons.edit_outlined,
                                        tooltip: 'Edit',
                                        onTap: () => showTaskEditForm(
                                            context,
                                            task: widget.task),
                                      ),
                                      _HoverAction(
                                        icon: Icons.arrow_forward,
                                        tooltip: 'Postpone',
                                        color: AppColors.golden,
                                        onTap: _postpone,
                                      ),
                                      _HoverAction(
                                        icon: Icons.delete_outline,
                                        tooltip: 'Delete',
                                        color: AppColors.error,
                                        onTap: () async {
                                          final dr =
                                              await showDeleteConfirmation(
                                                  context, widget.task);
                                          if (mounted) {
                                            _handleDeleteResult(dr);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Brief golden shimmer on first creation (keyed by task id so only runs once per task).
    return tile
        .animate()
        .shimmer(
          delay: 50.ms,
          duration: 350.ms,
          color: AppColors.golden.withValues(alpha: 0.2),
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

class _HoverAction extends StatelessWidget {
  const _HoverAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      preferBelow: false,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      textStyle: const TextStyle(
        fontFamily: AppTypography.bodyFont,
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(
              icon,
              size: 16,
              color: color ?? AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextMenuItem extends StatelessWidget {
  const _ContextMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 13,
            color: c,
          ),
        ),
      ],
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
