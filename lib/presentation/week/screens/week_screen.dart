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
import '../../shared/widgets/pressable.dart';

enum _WeekViewMode { byDay, byGoal }

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
  _WeekViewMode _mode = _WeekViewMode.byDay;

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
              if (_mode == _WeekViewMode.byGoal) {
                final goals = goalsAsync.valueOrNull ?? [];
                return _GoalSwimLane(
                  tasks: tasks,
                  weekStart: weekStart,
                  goals: goals,
                  goalColorMap: goalColorMap,
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
  _WeekViewMode _mode = _WeekViewMode.byDay;

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
              if (_mode == _WeekViewMode.byGoal) {
                final goals = goalsAsync.valueOrNull ?? [];
                return _GoalSwimLane(
                  tasks: tasks,
                  weekStart: weekStart,
                  goals: goals,
                  goalColorMap: goalColorMap,
                  desktop: true,
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
        // By goal / By day toggle
        _ModeToggle(mode: mode, onToggle: onModeChange),
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onToggle});

  final _WeekViewMode mode;
  final void Function(_WeekViewMode) onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeChip(
          label: 'By goal',
          active: mode == _WeekViewMode.byGoal,
          onTap: () => onToggle(_WeekViewMode.byGoal),
        ),
        const SizedBox(width: AppSpacing.xs),
        _ModeChip(
          label: 'By day',
          active: mode == _WeekViewMode.byDay,
          onTap: () => onToggle(_WeekViewMode.byDay),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.golden : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.golden : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w500,
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

// ─── By goal swim-lane view ───────────────────────────────────────────────────

class _GoalSwimLane extends StatelessWidget {
  const _GoalSwimLane({
    required this.tasks,
    required this.weekStart,
    required this.goals,
    required this.goalColorMap,
    this.desktop = false,
  });

  final List<Task> tasks;
  final DateTime weekStart;
  final List<Goal> goals;
  final Map<String, GoalColor> goalColorMap;
  final bool desktop;

  static const _dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build goal rows: active goals that have tasks this week + a "no goal" row
    final goalIds = tasks.map((t) => t.goalId).toSet();
    final visibleGoals = goals.where((g) => goalIds.contains(g.id)).toList();
    final hasNoGoalTasks = goalIds.contains(null);

    final hPad =
        desktop ? AppSpacing.xxxl.toDouble() : AppSpacing.sm.toDouble();
    const rowLabelWidth = 90.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, AppSpacing.sm, hPad, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day headers row
          Padding(
            padding:
                const EdgeInsets.only(left: rowLabelWidth + AppSpacing.sm),
            child: Row(
              children: List.generate(7, (i) {
                final date = weekStart.add(Duration(days: i));
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                return Expanded(
                  child: Center(
                    child: Text(
                      _dayHeaders[i],
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 10,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday
                            ? AppColors.golden
                            : AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Goal rows
          ...visibleGoals.map((goal) {
            final gc = goalColorMap[goal.id];
            final color = gc?.base ?? AppColors.textMuted;
            return _SwimLaneRow(
              label: goal.title,
              color: color,
              weekStart: weekStart,
              tasks:
                  tasks.where((t) => t.goalId == goal.id).toList(),
              today: today,
            );
          }),
          if (hasNoGoalTasks)
            _SwimLaneRow(
              label: 'No goal',
              color: AppColors.textMuted,
              weekStart: weekStart,
              tasks: tasks.where((t) => t.goalId == null).toList(),
              today: today,
            ),
        ],
      ),
    );
  }
}

class _SwimLaneRow extends StatelessWidget {
  const _SwimLaneRow({
    required this.label,
    required this.color,
    required this.weekStart,
    required this.tasks,
    required this.today,
  });

  final String label;
  final Color color;
  final DateTime weekStart;
  final List<Task> tasks;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Goal label
            SizedBox(
              width: 90,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Day cells
            ...List.generate(7, (i) {
              final date = weekStart.add(Duration(days: i));
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final dayTasks = _tasksForDate(tasks, date);

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    color: isToday
                        ? color.withValues(alpha: 0.06)
                        : AppColors.surface.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isToday
                          ? color.withValues(alpha: 0.3)
                          : AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...dayTasks.map((t) => _TaskChip(
                            task: t,
                            color: color,
                          )),
                      if (dayTasks.isEmpty)
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.task, required this.color});

  final Task task;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: task.done
            ? Colors.transparent
            : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: task.done ? 0.2 : 0.4),
        ),
      ),
      child: Text(
        task.title,
        style: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 9,
          color: task.done ? AppColors.textMuted : AppColors.textPrimary,
          decoration: task.done ? TextDecoration.lineThrough : null,
          decorationColor: AppColors.textMuted,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
