import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/task.dart';
import '../../shared/widgets/pressable.dart';
import '../../today/providers/today_provider.dart';
import '../../today/utils/task_sort.dart';
import '../../today/widgets/task_tile.dart';
import '../providers/week_provider.dart';

class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isPast = date.isBefore(today);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= AppConstants.mobileBreakpoint;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.textSecondary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isToday
                  ? 'Today'
                  : DateFormat(isDesktop ? 'EEEE, MMMM d' : 'EEEE, MMMM d')
                      .format(date),
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            bottom: isPast
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(28),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                          horizontal: AppSpacing.lg),
                      child: const Text(
                        'Past day — view only',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          body: _DayDetailBody(
            date: date,
            isToday: isToday,
            isPast: isPast,
            isDesktop: isDesktop,
          ),
        );
      },
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _DayDetailBody extends ConsumerWidget {
  const _DayDetailBody({
    required this.date,
    required this.isToday,
    required this.isPast,
    required this.isDesktop,
  });

  final DateTime date;
  final bool isToday;
  final bool isPast;
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksForDateProvider(date));

    final padding = isDesktop
        ? const EdgeInsets.fromLTRB(
            AppSpacing.xxxl,
            AppSpacing.xxl,
            AppSpacing.xxxl,
            AppSpacing.xxl,
          )
        : const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          );

    return tasksAsync.when(
      data: (tasks) => _buildContent(context, ref, tasks, padding),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const Center(
        child: Text(
          'Could not load tasks',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Task> tasks,
    EdgeInsets padding,
  ) {
    final sorted = sortTasks(tasks);

    if (isDesktop) {
      return SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isPast) ...[
              _QuickTaskInput(date: date),
              const SizedBox(height: AppSpacing.xxl),
            ],
            if (sorted.isEmpty)
              _EmptyState(isPast: isPast)
            else
              _TaskList(tasks: sorted, isPast: isPast),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isPast)
          Padding(
            padding: padding,
            child: _QuickTaskInput(date: date),
          ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: sorted.isEmpty
              ? _EmptyState(isPast: isPast)
              : ListView(
                  children: [
                    _TaskList(tasks: sorted, isPast: isPast),
                  ],
                ),
        ),
      ],
    );
  }
}

// ─── Quick task input ─────────────────────────────────────────────────────────

class _QuickTaskInput extends ConsumerStatefulWidget {
  const _QuickTaskInput({required this.date});

  final DateTime date;

  @override
  ConsumerState<_QuickTaskInput> createState() => _QuickTaskInputState();
}

class _QuickTaskInputState extends ConsumerState<_QuickTaskInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    _controller.clear();
    _focusNode.requestFocus();
    await ref
        .read(taskActionsProvider.notifier)
        .createTask(title, date: widget.date);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'New task...',
                hintStyle: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Pressable(
          onTap: _submit,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.golden,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add,
                color: AppColors.background, size: 22),
          ),
        ),
      ],
    );
  }
}

// ─── Task list ────────────────────────────────────────────────────────────────

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks, required this.isPast});

  final List<Task> tasks;
  final bool isPast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isPast) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: tasks
              .map((task) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ReadOnlyTaskRow(task: task),
                  ))
              .toList(),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final scale = 1.03 + animation.value * 0.02;
                return Transform.scale(
                  scale: scale,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 8 * animation.value,
                    shadowColor:
                        AppColors.golden.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemCount: tasks.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            final updated = List<Task>.from(tasks);
            final moved = updated.removeAt(oldIndex);
            updated.insert(newIndex, moved);
            ref
                .read(taskActionsProvider.notifier)
                .reorderTasks(updated);
          },
          itemBuilder: (_, i) {
            final task = tasks[i];
            return Padding(
              key: ValueKey(task.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TaskTile(task: task, index: i),
            );
          },
        ),
        if (tasks.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Center(
              child: Text(
                '← swipe to remove · swipe to postpone →',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Read-only task row (past days) ──────────────────────────────────────────

class _ReadOnlyTaskRow extends StatelessWidget {
  const _ReadOnlyTaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.done ? AppColors.golden : Colors.transparent,
              border: Border.all(
                color: task.done ? AppColors.golden : AppColors.border,
                width: 1.5,
              ),
            ),
            child: task.done
                ? const Icon(Icons.check,
                    size: 13, color: AppColors.background)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: task.done
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
                decoration:
                    task.done ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isPast});

  final bool isPast;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isPast ? 'No tasks recorded.' : 'No tasks for this day.',
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isPast ? '' : 'Add one above.',
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
