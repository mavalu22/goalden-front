import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/task.dart' show Task;
import '../providers/today_provider.dart';
import '../utils/task_sort.dart';
import '../widgets/pending_section.dart';
import '../widgets/task_tile.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
          return const _DesktopTodayView();
        }
        return const _MobileTodayView();
      },
    );
  }
}

// ─── Mobile ──────────────────────────────────────────────────────────────────

class _MobileTodayView extends ConsumerWidget {
  const _MobileTodayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(now).toUpperCase();
    final dateLabel = DateFormat('MMMM d').format(now);
    final tasksAsync = ref.watch(todayTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayOfWeek,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFont,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _QuickTaskInput(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: tasksAsync.when(
            data: (tasks) => tasks.isEmpty
                ? const _EmptyStateWithPending()
                : ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: PendingSection(),
                      ),
                      _TaskList(tasks: tasks),
                    ],
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const _EmptyState(),
          ),
        ),
      ],
    );
  }
}

// ─── Desktop ─────────────────────────────────────────────────────────────────

class _DesktopTodayView extends ConsumerWidget {
  const _DesktopTodayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE, MMMM d').format(now);
    final tasksAsync = ref.watch(todayTasksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S FOCUS",
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            dateLabel,
            style: const TextStyle(
              fontFamily: AppTypography.displayFont,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _QuoteCard(),
          const SizedBox(height: AppSpacing.xxl),
          const _QuickTaskInput(hint: 'Pick a task to focus on...'),
          const SizedBox(height: AppSpacing.xxxl),
          const PendingSection(),
          tasksAsync.when(
            data: (tasks) => tasks.isEmpty
                ? const _EmptyState()
                : _TaskList(tasks: tasks),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const _EmptyState(),
          ),
        ],
      ),
    );
  }
}

// ─── Quick task input ─────────────────────────────────────────────────────────

class _QuickTaskInput extends ConsumerStatefulWidget {
  const _QuickTaskInput({this.hint = 'New task...'});

  final String hint;

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
    await ref.read(taskActionsProvider.notifier).createTask(title);
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
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
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
        GestureDetector(
          onTap: _submit,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.golden,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: AppColors.background, size: 22),
          ),
        ),
      ],
    );
  }
}

// ─── Task list ────────────────────────────────────────────────────────────────

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = sortTasks(tasks);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                    shadowColor: AppColors.golden.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemCount: sorted.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            final updated = List<Task>.from(sorted);
            final moved = updated.removeAt(oldIndex);
            updated.insert(newIndex, moved);
            ref.read(taskActionsProvider.notifier).reorderTasks(updated);
          },
          itemBuilder: (_, i) {
            final task = sorted[i];
            return Padding(
              key: ValueKey(task.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Stack(
                children: [
                  TaskTile(task: task),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: ReorderableDragStartListener(
                      index: i,
                      child: const Icon(
                        Icons.drag_handle,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (sorted.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Center(
              child: Text(
                '← swipe to remove  ·  swipe to postpone →',
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

// ─── Empty state with pending section ────────────────────────────────────────

class _EmptyStateWithPending extends StatelessWidget {
  const _EmptyStateWithPending();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: const [
        PendingSection(),
        _EmptyState(),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
          const Text(
            'No tasks for today.',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Enjoy your day!',
            style: TextStyle(
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

// ─── Quote card ───────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❝',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.golden.withValues(alpha: 0.35),
              height: 1.2,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'The secret of your future is hidden in your daily routine.',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '— Mike Murdock',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
