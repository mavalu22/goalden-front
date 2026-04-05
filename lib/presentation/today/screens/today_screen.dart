import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/task.dart' show Task;
import '../providers/today_provider.dart';
import '../../week/providers/week_provider.dart' show tasksForDateProvider;
import '../utils/daily_quote.dart';
import '../utils/task_sort.dart';
import '../widgets/pending_section.dart';
import '../../shared/widgets/pressable.dart';
import '../widgets/task_form_sheet.dart';
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

/// Viewport width at which the sidebar appears.
const _sidebarBreakpoint = 1200.0;
/// Width of the contextual sidebar.
const _sidebarWidth = 240.0;

// ─── Desktop ─────────────────────────────────────────────────────────────────

class _DesktopTodayView extends ConsumerWidget {
  const _DesktopTodayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE, MMMM d').format(now);
    final tasksAsync = ref.watch(todayTasksProvider);
    final viewportWidth = MediaQuery.of(context).size.width;
    final showSidebar = viewportWidth >= _sidebarBreakpoint;

    final mainContent = SingleChildScrollView(
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
          const SizedBox(height: AppSpacing.lg),
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

    if (!showSidebar) return mainContent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: mainContent),
        const _ContextSidebar(),
      ],
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
        // Full form button
        Pressable(
          onTap: () => showTaskForm(context),
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.golden.withValues(alpha: 0.08),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.tune,
                color: AppColors.textSecondary, size: 20),
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
          buildDefaultDragHandles: false,
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
              child: TaskTile(task: task, index: i),
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
    final quote = getTodayQuote();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❝',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.golden.withValues(alpha: 0.25),
              height: 1.3,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '"${quote.text}"',
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '— ${quote.author}',
                  style: const TextStyle(
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

// ─── Context sidebar (desktop, > 1200px) ──────────────────────────────────────

class _ContextSidebar extends ConsumerWidget {
  const _ContextSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayTasksAsync = ref.watch(todayTasksProvider);
    final pendingAsync = ref.watch(pendingTasksProvider);

    // Upcoming: next 3 days' task counts via tasksForDateProvider family
    final upcoming = [
      for (int i = 1; i <= 3; i++) today.add(Duration(days: i)),
    ];

    return SizedBox(
      width: _sidebarWidth,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          0,
          AppSpacing.xxl,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress ──────────────────────────────────────────────────────
            _SidebarCard(
              children: [
                const _SidebarSectionLabel('TODAY'),
                const SizedBox(height: AppSpacing.sm),
                todayTasksAsync.when(
                  data: (tasks) {
                    final done = tasks.where((t) => t.done).length;
                    final total = tasks.length;
                    return _ProgressBlock(done: done, total: total);
                  },
                  loading: () => const _SidebarPlaceholder(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Overdue ───────────────────────────────────────────────────────
            pendingAsync.when(
              data: (pending) {
                if (pending.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    _SidebarCard(
                      children: [
                        const _SidebarSectionLabel('OVERDUE'),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${pending.length} task${pending.length == 1 ? '' : 's'} pending',
                              style: const TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Upcoming ──────────────────────────────────────────────────────
            _SidebarCard(
              children: [
                const _SidebarSectionLabel('UPCOMING'),
                const SizedBox(height: AppSpacing.sm),
                for (final day in upcoming) ...[
                  _UpcomingDayRow(date: day),
                  if (day != upcoming.last) const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarCard extends StatelessWidget {
  const _SidebarCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: AppTypography.bodyFont,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : done / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$done / $total completed',
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 4,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.golden),
          ),
        ),
      ],
    );
  }
}

class _UpcomingDayRow extends ConsumerWidget {
  const _UpcomingDayRow({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(
      tasksForDateProvider(date),
    );
    final label = _dayLabel(date);

    return tasksAsync.when(
      data: (tasks) {
        final count = tasks.length;
        return Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              count == 0 ? '—' : '$count task${count == 1 ? '' : 's'}',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 12,
                color: count == 0 ? AppColors.textMuted : AppColors.textPrimary,
                fontWeight: count > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        );
      },
      loading: () => const _SidebarPlaceholder(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEEE').format(date);
  }
}

class _SidebarPlaceholder extends StatelessWidget {
  const _SidebarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
