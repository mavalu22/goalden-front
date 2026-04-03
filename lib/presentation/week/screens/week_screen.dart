import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/task.dart';
import '../providers/week_provider.dart';
import '../widgets/day_card.dart';
import '../widgets/day_column.dart';

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

// ─── Shared: week nav bar ─────────────────────────────────────────────────────

class _WeekNavBar extends ConsumerWidget {
  const _WeekNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(weekLabelProvider);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          onPressed: () => ref.read(weekOffsetProvider.notifier).state--,
          splashRadius: 20,
        ),
        Expanded(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onPressed: () => ref.read(weekOffsetProvider.notifier).state++,
          splashRadius: 20,
        ),
      ],
    );
  }
}

// ─── Mobile ───────────────────────────────────────────────────────────────────

class _MobileWeekView extends ConsumerWidget {
  const _MobileWeekView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(weekTasksProvider);
    final weekStart = ref.watch(weekStartProvider);

    return Column(
      children: [
        // Week navigation bar
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            0,
          ),
          child: _WeekNavBar(),
        ),
        // Day cards
        Expanded(
          child: tasksAsync.when(
            data: (tasks) {
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.golden),
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

class _DesktopWeekView extends ConsumerWidget {
  const _DesktopWeekView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(weekTasksProvider);
    final weekStart = ref.watch(weekStartProvider);

    return Column(
      children: [
        // Week navigation bar
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: _WeekNavBar(),
        ),
        // Day columns
        Expanded(
          child: tasksAsync.when(
            data: (tasks) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < 7; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DayColumn(
                          date: weekStart.add(Duration(days: i)),
                          tasks: _tasksForDate(
                            tasks,
                            weekStart.add(Duration(days: i)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.golden),
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

List<Task> _tasksForDate(List<Task> tasks, DateTime date) {
  return tasks.where((t) {
    final taskDate = t.date.toLocal();
    return taskDate.year == date.year &&
        taskDate.month == date.month &&
        taskDate.day == date.day;
  }).toList();
}
