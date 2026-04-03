import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/task.dart';
import '../providers/today_provider.dart';

class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task.done;
    final isHigh = task.priority == TaskPriority.high && !isCompleted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isCompleted ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHigh ? AppColors.goldenBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Circle checkbox with scale pop animation on toggle
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(taskActionsProvider.notifier).toggleDone(task),
              child: _Checkbox(done: isCompleted, taskId: task.id),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title with animated strikethrough via CrossFade
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Align(
                  key: ValueKey(isCompleted),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCompleted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            // HIGH badge (only on uncompleted high priority tasks)
            if (isHigh) ...[
              const SizedBox(width: AppSpacing.sm),
              const _HighBadge(),
            ],
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatefulWidget {
  const _Checkbox({required this.done, required this.taskId});

  final bool done;
  final String taskId;

  @override
  State<_Checkbox> createState() => _CheckboxState();
}

class _CheckboxState extends State<_Checkbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _prevDone = false;

  @override
  void initState() {
    super.initState();
    _prevDone = widget.done;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void didUpdateWidget(_Checkbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Play scale pop only when transitioning to done
    if (!_prevDone && widget.done) {
      _playPop();
    }
    _prevDone = widget.done;
  }

  void _playPop() {
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.75),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.75, end: 1.2),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.done ? AppColors.golden : Colors.transparent,
            border: Border.all(
              color: widget.done ? AppColors.golden : AppColors.border,
              width: 1.5,
            ),
          ),
          child: widget.done
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
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
