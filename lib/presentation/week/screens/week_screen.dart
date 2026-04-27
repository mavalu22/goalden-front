import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/goal.dart';
import '../../../domain/models/task.dart';
import '../../goals/providers/goal_provider.dart'
    show activeGoalsProvider, goalColorMapProvider, GoalColor;
import '../providers/week_provider.dart';
import '../widgets/day_card.dart';
import '../widgets/day_column.dart';
import '../../shared/widgets/pressable.dart';

enum _WeekViewMode { vertical, horizontal }

class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
          return const _DesktopWeekView();
        }
        return const _MobileWeekView();
      },
    );
  }
}

// ─── Mobile ───────────────────────────────────────────────────────────────────

class _MobileWeekView extends ConsumerStatefulWidget {
  const _MobileWeekView();

  @override
  ConsumerState<_MobileWeekView> createState() => _MobileWeekViewState();
}

class _MobileWeekViewState extends ConsumerState<_MobileWeekView> {
  _WeekViewMode _mode = _WeekViewMode.vertical;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(weekTasksProvider);
    final weekStart = ref.watch(weekStartProvider);
    final goalsAsync = ref.watch(activeGoalsProvider);
    final goalColorMap = ref.watch(goalColorMapProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            0,
          ),
          child: _WeekHeader(
            mode: _mode,
            onModeChange: (m) => setState(() => _mode = m),
          ),
        ),
        // Goal legend
        tasksAsync.when(
          data: (tasks) {
            final goals = goalsAsync.valueOrNull ?? [];
            final goalIds = tasks.map((t) => t.goalId).toSet();
            final visibleGoals =
                goals.where((g) => goalIds.contains(g.id)).toList();
            if (visibleGoals.isEmpty) return const SizedBox.shrink();
            return _GoalLegendRow(
              goals: visibleGoals,
              goalColorMap: goalColorMap,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Expanded(
          child: tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) return const _WeekEmptyState();
              if (_mode == _WeekViewMode.horizontal) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: SizedBox(
                    width: 7 * 156.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(7, (i) {
                        final date = weekStart.add(Duration(days: i));
                        return SizedBox(
                          width: 156,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: DayColumn(
                              date: date,
                              tasks: _tasksForDate(tasks, date),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = weekStart.add(Duration(days: index));
                  final dayTasks = _tasksForDate(tasks, date);
                  return DayCard(date: date, tasks: dayTasks);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.golden),
                strokeWidth: 2,
              ),
            ),
            error: (e, _) => const Center(
              child: Text(
                'Could not load tasks',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Desktop ──────────────────────────────────────────────────────────────────

class _DesktopWeekView extends ConsumerStatefulWidget {
  const _DesktopWeekView();

  @override
  ConsumerState<_DesktopWeekView> createState() => _DesktopWeekViewState();
}

class _DesktopWeekViewState extends ConsumerState<_DesktopWeekView> {
  _WeekViewMode _mode = _WeekViewMode.vertical;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(weekTasksProvider);
    final weekStart = ref.watch(weekStartProvider);
    final goalsAsync = ref.watch(activeGoalsProvider);
    final goalColorMap = ref.watch(goalColorMapProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxxl,
            AppSpacing.lg,
            AppSpacing.xxxl,
            AppSpacing.md,
          ),
          child: _WeekHeader(
            mode: _mode,
            onModeChange: (m) => setState(() => _mode = m),
          ),
        ),
        // Goal legend chips + week progress bar
        tasksAsync.when(
          data: (tasks) {
            final done = tasks.where((t) => t.done).length;
            final total = tasks.length;
            final goals = goalsAsync.valueOrNull ?? [];
            final goalIds = tasks.map((t) => t.goalId).toSet();
            final visibleGoals =
                goals.where((g) => goalIds.contains(g.id)).toList();
            return _WeekSummaryBar(
              done: done,
              total: total,
              goals: visibleGoals,
              goalColorMap: goalColorMap,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Expanded(
          child: tasksAsync.when(
            data: (tasks) {
              if (_mode == _WeekViewMode.horizontal) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxxl,
                    0,
                    AppSpacing.xxxl,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(7, (i) {
                      final date = weekStart.add(Duration(days: i));
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: DayColumn(
                            date: date,
                            tasks: _tasksForDate(tasks, date),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl, vertical: AppSpacing.xs),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = weekStart.add(Duration(days: index));
                  final dayTasks = _tasksForDate(tasks, date);
                  return DayCard(date: date, tasks: dayTasks);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.golden),
                strokeWidth: 2,
              ),
            ),
            error: (e, _) => const Center(
              child: Text(
                'Could not load tasks',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Week header ──────────────────────────────────────────────────────────────

class _WeekHeader extends ConsumerWidget {
  const _WeekHeader({required this.mode, required this.onModeChange});

  final _WeekViewMode mode;
  final void Function(_WeekViewMode) onModeChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(weekLabelProvider);
    final isCurrent = ref.watch(weekOffsetProvider) == 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Prev/next nav
        _NavButton(
          icon: Icons.chevron_left,
          onTap: () => ref.read(weekOffsetProvider.notifier).state--,
        ),
        const SizedBox(width: AppSpacing.sm),
        // Date + title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCurrent ? 'THIS WEEK · $label' : label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isCurrent ? 'Your week at a glance' : label,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFont,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        // Vertical / horizontal view mode
        _ViewModeButtons(mode: mode, onToggle: onModeChange),
        const SizedBox(width: AppSpacing.sm),
        // Prev/next
        _NavButton(
          icon: Icons.chevron_right,
          onTap: () => ref.read(weekOffsetProvider.notifier).state++,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _ViewModeButtons extends StatelessWidget {
  const _ViewModeButtons({required this.mode, required this.onToggle});

  final _WeekViewMode mode;
  final void Function(_WeekViewMode) onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ViewModeButton(
          icon: Icons.view_agenda_outlined,
          active: mode == _WeekViewMode.vertical,
          tooltip: 'Vertical view',
          onTap: () => onToggle(_WeekViewMode.vertical),
        ),
        const SizedBox(width: AppSpacing.xs),
        _ViewModeButton(
          icon: Icons.view_week_outlined,
          active: mode == _WeekViewMode.horizontal,
          tooltip: 'Horizontal view',
          onTap: () => onToggle(_WeekViewMode.horizontal),
        ),
      ],
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Pressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.golden : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.golden : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Week summary bar (desktop) ───────────────────────────────────────────────

class _WeekSummaryBar extends StatelessWidget {
  const _WeekSummaryBar({
    required this.done,
    required this.total,
    required this.goals,
    required this.goalColorMap,
  });

  final int done;
  final int total;
  final List<Goal> goals;
  final Map<String, GoalColor> goalColorMap;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        0,
        AppSpacing.xxxl,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              Text(
                '$done of $total done',
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Goal legend chips
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ...goals.map((g) {
                    final gc = goalColorMap[g.id];
                    final color = gc?.base ?? AppColors.textMuted;
                    return _GoalChip(label: g.title, color: color);
                  }),
                  if (goals.isNotEmpty)
                    const _GoalChip(
                      label: 'No goal',
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Progress bar
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
      ),
    );
  }
}

class _GoalLegendRow extends StatelessWidget {
  const _GoalLegendRow({required this.goals, required this.goalColorMap});

  final List<Goal> goals;
  final Map<String, GoalColor> goalColorMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          ...goals.map((g) {
            final gc = goalColorMap[g.id];
            final color = gc?.base ?? AppColors.textMuted;
            return _GoalChip(label: g.title, color: color);
          }),
          const _GoalChip(label: 'No goal', color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _WeekEmptyState extends StatelessWidget {
  const _WeekEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Nothing planned yet.',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Tap a day to start planning your week.',
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

List<Task> _tasksForDate(List<Task> tasks, DateTime date) {
  return tasks.where((t) {
    final taskDate = t.date.toLocal();
    return taskDate.year == date.year &&
        taskDate.month == date.month &&
        taskDate.day == date.day;
  }).toList();
}
