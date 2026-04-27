import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/goal_colors.dart';
import '../../goals/providers/goal_provider.dart'
    show
        activeGoalsProvider,
        archivedGoalsProvider,
        goalColorMapProvider;
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();
  HistoryRange? _scrolledForRange;
  DateTime? _selectedDay;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _onCellTap(DateTime date, bool isDesktop) {
    if (isDesktop) {
      setState(() => _selectedDay = _selectedDay == date ? null : date);
    } else {
      setState(() => _selectedDay = date);
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        isScrollControlled: true,
        builder: (_) => _DayPanel(
          date: date,
          onClose: () => Navigator.of(context).pop(),
        ),
      ).then((_) => setState(() => _selectedDay = null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(historyRangeProvider);
    final viewMode = ref.watch(historyViewModeProvider);
    final dayData = ref.watch(historyDayDataProvider);
    final dominantGoals = ref.watch(historyDominantGoalProvider);
    final goalColorMap = ref.watch(goalColorMapProvider);
    final tasks = ref.watch(historyTasksProvider).valueOrNull ?? [];
    final isLoading = ref.watch(historyTasksProvider).isLoading;

    // Goal info map: active + archived, for goal breakdown panel
    final activeGoals = ref.watch(activeGoalsProvider).valueOrNull ?? [];
    final archivedGoals = ref.watch(archivedGoalsProvider).valueOrNull ?? [];
    final goalInfoMap = <String, ({String title, GoalColor gc})>{
      for (final g in [...activeGoals, ...archivedGoals])
        g.id: (title: g.title, gc: GoalColors.fromId(g.color)),
    };

    if (!isLoading && _scrolledForRange != range) {
      _scrolledForRange = range;
      if (_selectedDay != null) setState(() => _selectedDay = null);
      _scrollToEnd();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = range.startDate(today);

    // Precompute dominant goal color per day for goal mode
    final dominantColors = <DateTime, Color>{};
    if (viewMode == HistoryViewMode.byGoal) {
      for (final entry in dominantGoals.entries) {
        if (entry.value != null) {
          final gc = goalColorMap[entry.value];
          if (gc != null) dominantColors[entry.key] = gc.base;
        }
      }
    }

    // ── KPI computations ─────────────────────────────────────────
    final doneCount = tasks.where((t) => t.done).length;
    final totalCount = tasks.length;
    final completionRate =
        totalCount > 0 ? (doneCount / totalCount * 100).round() : 0;
    final rangeLength = today.difference(rangeStart).inDays + 1;
    final avgPerDay = rangeLength > 0 ? doneCount / rangeLength : 0.0;

    // Current streak: count back from today for consecutive days with ≥1 done
    var currentStreak = 0;
    for (var i = 0; i <= rangeLength; i++) {
      final d = today.subtract(Duration(days: i));
      final data = dayData[d];
      if (data != null && data.completed > 0) {
        currentStreak++;
      } else if (i > 0) {
        break;
      }
    }

    // Best streak in range
    var bestStreak = 0;
    var tempStreak = 0;
    for (var i = 0; i < rangeLength; i++) {
      final d = rangeStart.add(Duration(days: i));
      final data = dayData[d];
      if (data != null && data.completed > 0) {
        tempStreak++;
        bestStreak = math.max(bestStreak, tempStreak);
      } else {
        tempStreak = 0;
      }
    }

    // Day of week counts (0=Mon, 6=Sun), done tasks only
    final dowCounts = List.filled(7, 0);
    for (final task in tasks.where((t) => t.done)) {
      final dow = task.date.weekday - 1;
      if (dow >= 0 && dow < 7) dowCounts[dow]++;
    }
    final maxDow = dowCounts.reduce(math.max);
    final bestDow = maxDow > 0 ? dowCounts.indexOf(maxDow) : -1;

    // Hour of day counts (0–23), done tasks only
    final hourCounts = List.filled(24, 0);
    for (final task in tasks.where((t) => t.done)) {
      final hour = task.startTimeMinutes != null
          ? task.startTimeMinutes! ~/ 60
          : task.createdAt.toLocal().hour;
      if (hour >= 0 && hour < 24) hourCounts[hour]++;
    }
    final maxHour = hourCounts.reduce(math.max);
    final bestHour = maxHour > 0 ? hourCounts.indexOf(maxHour) : -1;

    // Goal breakdown: count done tasks per goalId, sorted desc
    final goalCounts = <String?, int>{};
    for (final task in tasks.where((t) => t.done)) {
      goalCounts[task.goalId] = (goalCounts[task.goalId] ?? 0) + 1;
    }
    final sortedGoalEntries = goalCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= AppConstants.mobileBreakpoint;
        final hPad = isDesktop ? AppSpacing.xxxl : AppSpacing.lg;
        final cellSize = isDesktop ? 14.0 : 12.0;
        const gap = 2.0;

        final heatmapGrid = isLoading
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.golden),
                    strokeWidth: 2,
                  ),
                ),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: _HeatmapGrid(
                  dayData: dayData,
                  rangeStart: rangeStart,
                  today: today,
                  cellSize: cellSize,
                  gap: gap,
                  selectedDate: _selectedDay,
                  onCellTap: (d) => _onCellTap(d, isDesktop),
                  goalColorMode: viewMode == HistoryViewMode.byGoal,
                  dominantGoalColors: dominantColors,
                ),
              );

        // Panels content (cards below header)
        final Widget panelsContent = SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.huge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI row
                _KpiRow(
                  doneCount: doneCount,
                  completionRate: completionRate,
                  totalCount: totalCount,
                  currentStreak: currentStreak,
                  bestStreak: bestStreak,
                  avgPerDay: avgPerDay,
                ),
                const SizedBox(height: AppSpacing.md),

                // Heatmap + breakdown
                if (isDesktop)
                  _TwoColumnRow(
                    leftFlex: 18,
                    rightFlex: 10,
                    left: _HeatmapCard(heatmapGrid: heatmapGrid),
                    right: _GoalBreakdownPanel(
                      sortedGoalEntries: sortedGoalEntries,
                      goalInfoMap: goalInfoMap,
                      doneCount: doneCount,
                    ),
                  )
                else
                  Column(
                    children: [
                      _HeatmapCard(heatmapGrid: heatmapGrid),
                      const SizedBox(height: AppSpacing.md),
                      _GoalBreakdownPanel(
                        sortedGoalEntries: sortedGoalEntries,
                        goalInfoMap: goalInfoMap,
                        doneCount: doneCount,
                      ),
                    ],
                  ),

                const SizedBox(height: AppSpacing.md),

                // Time patterns
                if (isDesktop)
                  _TwoColumnRow(
                    leftFlex: 1,
                    rightFlex: 1,
                    left: _DayOfWeekChart(
                      counts: dowCounts,
                      maxCount: maxDow,
                      bestIndex: bestDow,
                    ),
                    right: _HourOfDayChart(
                      counts: hourCounts,
                      maxCount: maxHour,
                      bestHour: bestHour,
                    ),
                  )
                else
                  Column(
                    children: [
                      _DayOfWeekChart(
                        counts: dowCounts,
                        maxCount: maxDow,
                        bestIndex: bestDow,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _HourOfDayChart(
                        counts: hourCounts,
                        maxCount: maxHour,
                        bestHour: bestHour,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, AppSpacing.lg, hPad, AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HISTORY',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Your year so far',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFont,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _ViewModeToggle(
                    mode: viewMode,
                    onToggle: () =>
                        ref.read(historyViewModeProvider.notifier).toggle(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _RangeSelector(
                    selected: range,
                    onSelect: (r) =>
                        ref.read(historyRangeProvider.notifier).state = r,
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: isDesktop && _selectedDay != null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: panelsContent),
                        SizedBox(
                          width: 300,
                          child: _DayPanel(
                            date: _selectedDay!,
                            onClose: () =>
                                setState(() => _selectedDay = null),
                          ),
                        ),
                      ],
                    )
                  : panelsContent,
            ),
          ],
        );
      },
    );
  }
}

// ── Two-column helper ─────────────────────────────────────────────────────────

class _TwoColumnRow extends StatelessWidget {
  const _TwoColumnRow({
    required this.leftFlex,
    required this.rightFlex,
    required this.left,
    required this.right,
  });

  final int leftFlex;
  final int rightFlex;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: rightFlex, child: right),
      ],
    );
  }
}

// ── KPI row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.doneCount,
    required this.completionRate,
    required this.totalCount,
    required this.currentStreak,
    required this.bestStreak,
    required this.avgPerDay,
  });

  final int doneCount;
  final int completionRate;
  final int totalCount;
  final int currentStreak;
  final int bestStreak;
  final double avgPerDay;

  @override
  Widget build(BuildContext context) {
    final focusMin = (avgPerDay * 20).round();
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'TASKS DONE',
            value: '$doneCount',
            sub: '$totalCount total',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _KpiCard(
            label: 'COMPLETION RATE',
            value: '$completionRate%',
            sub: '$doneCount of $totalCount done',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _KpiCard(
            label: 'CURRENT STREAK',
            value: '${currentStreak}d',
            sub: 'best: ${bestStreak}d',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _KpiCard(
            label: 'AVG PER DAY',
            value: avgPerDay.toStringAsFixed(1),
            sub: '~${focusMin}m focused',
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Heatmap card ──────────────────────────────────────────────────────────────

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.heatmapGrid});

  final Widget heatmapGrid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity heatmap',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          heatmapGrid,
          const SizedBox(height: AppSpacing.sm),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'less',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              for (final c in const [
                Color(0x0FD4AF37),
                Color(0x33D4AF37),
                Color(0x66D4AF37),
                Color(0x99D4AF37),
                AppColors.golden,
              ])
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 4),
              const Text(
                'more',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Goal breakdown panel ──────────────────────────────────────────────────────

class _GoalBreakdownPanel extends StatelessWidget {
  const _GoalBreakdownPanel({
    required this.sortedGoalEntries,
    required this.goalInfoMap,
    required this.doneCount,
  });

  final List<MapEntry<String?, int>> sortedGoalEntries;
  final Map<String, ({String title, GoalColor gc})> goalInfoMap;
  final int doneCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tasks by goal',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (sortedGoalEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'No tasks yet.',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final entry in sortedGoalEntries) ...[
              _GoalBar(
                entry: entry,
                goalInfoMap: goalInfoMap,
                doneCount: doneCount,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  const _GoalBar({
    required this.entry,
    required this.goalInfoMap,
    required this.doneCount,
  });

  final MapEntry<String?, int> entry;
  final Map<String, ({String title, GoalColor gc})> goalInfoMap;
  final int doneCount;

  @override
  Widget build(BuildContext context) {
    final isNoGoal = entry.key == null;
    final info = entry.key != null ? goalInfoMap[entry.key] : null;
    final title = isNoGoal ? 'No goal' : (info?.title ?? 'Unknown goal');
    final color = info?.gc.base ?? AppColors.textMuted;
    final pct = doneCount > 0 ? (entry.value / doneCount * 100).round() : 0;
    final fraction = doneCount > 0 ? entry.value / doneCount : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Text(
              isNoGoal ? '' : '★ ',
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${entry.value} · $pct%',
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.border.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

// ── Day of week chart ─────────────────────────────────────────────────────────

class _DayOfWeekChart extends StatelessWidget {
  const _DayOfWeekChart({
    required this.counts,
    required this.maxCount,
    required this.bestIndex,
  });

  final List<int> counts;
  final int maxCount;
  final int bestIndex;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const dayNames = [
      'Mondays',
      'Tuesdays',
      'Wednesdays',
      'Thursdays',
      'Fridays',
      'Saturdays',
      'Sundays',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best day of week',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: maxCount > 0
                                  ? (counts[i] / maxCount).clamp(0.05, 1.0)
                                  : 0.05,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: i == bestIndex
                                      ? AppColors.golden
                                      : AppColors.border.withValues(alpha: 0.5),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(2),
                                    topRight: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 9,
                            color: i == bestIndex
                                ? AppColors.golden
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < 6) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (bestIndex >= 0)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
                children: [
                  const TextSpan(text: 'You finish most tasks on '),
                  TextSpan(
                    text: dayNames[bestIndex],
                    style: const TextStyle(color: AppColors.golden),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            )
          else
            const Text(
              'Not enough data yet.',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Hour of day chart ─────────────────────────────────────────────────────────

class _HourOfDayChart extends StatelessWidget {
  const _HourOfDayChart({
    required this.counts,
    required this.maxCount,
    required this.bestHour,
  });

  final List<int> counts;
  final int maxCount;
  final int bestHour;

  String _hourRange(int h) {
    final next = (h + 2).clamp(0, 23);
    return '${h}h–${next}h';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best time of day',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 24; i++)
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: maxCount > 0
                            ? (counts[i] / maxCount).clamp(0.04, 1.0)
                            : 0.04,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          decoration: BoxDecoration(
                            color: i == bestHour
                                ? AppColors.golden
                                : AppColors.border.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(1),
                              topRight: Radius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0h',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '12h',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '24h',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (bestHour >= 0)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
                children: [
                  const TextSpan(text: 'Peak focus around '),
                  TextSpan(
                    text: _hourRange(bestHour),
                    style: const TextStyle(color: AppColors.golden),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            )
          else
            const Text(
              'Not enough data yet.',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── View mode toggle ─────────────────────────────────────────────────────────

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.mode, required this.onToggle});

  final HistoryViewMode mode;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isGoal = mode == HistoryViewMode.byGoal;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Act',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 11,
                fontWeight: !isGoal ? FontWeight.w700 : FontWeight.w400,
                color: !isGoal ? AppColors.golden : AppColors.textMuted,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '·',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 11,
                  color: AppColors.border,
                ),
              ),
            ),
            Text(
              'Goal',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 11,
                fontWeight: isGoal ? FontWeight.w700 : FontWeight.w400,
                color: isGoal ? AppColors.golden : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Range selector ───────────────────────────────────────────────────────────

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onSelect});

  final HistoryRange selected;
  final void Function(HistoryRange) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: HistoryRange.values
          .map((r) => _RangeButton(
                label: r.label,
                isActive: r == selected,
                onTap: () => onSelect(r),
              ))
          .toList(),
    );
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.goldenDim : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? AppColors.goldenBorder : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.golden : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Heatmap grid ─────────────────────────────────────────────────────────────

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.dayData,
    required this.rangeStart,
    required this.today,
    required this.cellSize,
    required this.gap,
    required this.onCellTap,
    this.selectedDate,
    this.goalColorMode = false,
    this.dominantGoalColors,
  });

  final Map<DateTime, DayData> dayData;
  final DateTime rangeStart;
  final DateTime today;
  final double cellSize;
  final double gap;
  final void Function(DateTime) onCellTap;
  final DateTime? selectedDate;
  final bool goalColorMode;
  final Map<DateTime, Color>? dominantGoalColors;

  @override
  Widget build(BuildContext context) {
    final firstMonday =
        rangeStart.subtract(Duration(days: rangeStart.weekday - 1));
    final lastSunday = today.add(Duration(days: 7 - today.weekday));

    final weeks = <DateTime>[];
    var cursor = firstMonday;
    while (!cursor.isAfter(lastSunday)) {
      weeks.add(cursor);
      cursor = cursor.add(const Duration(days: 7));
    }

    final monthLabels = <int, String>{};
    String? lastLabel;
    for (var i = 0; i < weeks.length; i++) {
      for (var d = 0; d < 7; d++) {
        final day = weeks[i].add(Duration(days: d));
        if (!day.isBefore(rangeStart) && !day.isAfter(today)) {
          final label = DateFormat('MMM').format(day);
          if (label != lastLabel) {
            monthLabels[i] = label;
            lastLabel = label;
          }
          break;
        }
      }
    }

    const dayLabels = ['M', '', 'W', '', 'F', '', 'S'];
    const labelWidth = 14.0;
    const monthLabelHeight = 18.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: monthLabelHeight),
            for (var d = 0; d < 7; d++)
              SizedBox(
                height: cellSize + gap,
                width: labelWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    dayLabels[d],
                    style: const TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: gap * 2),
        for (var i = 0; i < weeks.length; i++)
          Padding(
            padding: EdgeInsets.only(right: gap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: monthLabelHeight,
                  child: monthLabels.containsKey(i)
                      ? Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            monthLabels[i]!,
                            style: const TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : null,
                ),
                for (var d = 0; d < 7; d++)
                  _buildCell(weeks[i].add(Duration(days: d))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCell(DateTime date) {
    final isInRange = !date.isBefore(rangeStart) && !date.isAfter(today);
    if (!isInRange) {
      return SizedBox(width: cellSize, height: cellSize + gap);
    }

    final data = dayData[date];
    final completed = data?.completed ?? 0;
    final planned = data?.planned ?? 0;
    final isSelected = selectedDate == date;
    final tooltipMsg = completed == 0 && planned == 0
        ? DateFormat('MMM d, yyyy').format(date)
        : '${DateFormat('MMM d, yyyy').format(date)} · $completed of $planned completed';

    final fill = (goalColorMode && dominantGoalColors != null)
        ? (dominantGoalColors![date] != null
            ? dominantGoalColors![date]!.withValues(alpha: 0.7)
            : AppColors.border.withValues(alpha: 0.4))
        : _activityColor(completed);

    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Tooltip(
        message: tooltipMsg,
        waitDuration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: () => onCellTap(date),
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(2),
              border: isSelected
                  ? Border.all(color: AppColors.golden, width: 1.5)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Color _activityColor(int completed) {
    if (completed == 0) return const Color(0x0FD4AF37);
    if (completed == 1) return const Color(0x33D4AF37);
    if (completed == 2) return const Color(0x66D4AF37);
    if (completed == 3) return const Color(0x99D4AF37);
    if (completed == 4) return const Color(0xCCD4AF37);
    return AppColors.golden;
  }
}

// ─── Day drill-down panel ─────────────────────────────────────────────────────

class _DayPanel extends ConsumerWidget {
  const _DayPanel({required this.date, this.onClose});

  final DateTime date;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(historyDayTasksProvider(date));
    final goalColorMap = ref.watch(goalColorMapProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: tasksAsync.when(
        data: (tasks) => _buildContent(context, tasks, goalColorMap),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.golden),
            strokeWidth: 2,
          ),
        ),
        error: (_, __) => const Center(
          child: Text(
            'Could not load tasks',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Task> tasks,
    Map<String, GoalColor> goalColorMap,
  ) {
    final completed = tasks.where((t) => t.done).length;
    final total = tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM d').format(date),
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total == 0
                          ? 'No tasks'
                          : '$completed of $total completed',
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  color: AppColors.textMuted,
                  splashRadius: 16,
                ),
            ],
          ),
        ),
        // Goal segment bar
        if (tasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
            child: _DrillDownSegmentBar(
                tasks: tasks, goalColorMap: goalColorMap),
          ),
        const Divider(color: AppColors.border, height: 1),
        // Task list
        if (tasks.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Nothing logged on this day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: tasks
                  .map((t) => _DrillDownTaskRow(
                        task: t,
                        goalColorMap: goalColorMap,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ─── Segment bar (goal mix) ───────────────────────────────────────────────────

class _DrillDownSegmentBar extends StatelessWidget {
  const _DrillDownSegmentBar({
    required this.tasks,
    required this.goalColorMap,
  });

  final List<Task> tasks;
  final Map<String, GoalColor> goalColorMap;

  @override
  Widget build(BuildContext context) {
    final counts = <String?, int>{};
    for (final t in tasks) {
      counts[t.goalId] = (counts[t.goalId] ?? 0) + 1;
    }

    final segments = <({Color color, int count})>[];
    for (final entry in counts.entries.where((e) => e.key != null)) {
      final gc = goalColorMap[entry.key];
      segments.add((
        color: gc?.base ?? AppColors.border,
        count: entry.value,
      ));
    }
    segments.sort((a, b) => b.count.compareTo(a.count));
    final neutralCount = counts[null] ?? 0;
    if (neutralCount > 0) {
      segments.add((color: AppColors.border, count: neutralCount));
    }

    if (segments.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Row(
          children: [
            for (final seg in segments)
              Flexible(
                flex: seg.count,
                child: Container(color: seg.color),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Read-only task row ───────────────────────────────────────────────────────

class _DrillDownTaskRow extends StatelessWidget {
  const _DrillDownTaskRow({
    required this.task,
    required this.goalColorMap,
  });

  final Task task;
  final Map<String, GoalColor> goalColorMap;

  @override
  Widget build(BuildContext context) {
    final gc =
        task.goalId != null ? goalColorMap[task.goalId] : null;
    final checkColor = gc?.base ?? AppColors.golden;
    final borderColor = gc?.base ?? AppColors.border;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: gc?.dim ?? AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: gc != null
              ? Border(
                  top: const BorderSide(color: AppColors.border),
                  right: const BorderSide(color: AppColors.border),
                  bottom: const BorderSide(color: AppColors.border),
                  left: BorderSide(color: gc.base, width: 3),
                )
              : Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.done ? checkColor : Colors.transparent,
                border: Border.all(
                  color: task.done ? checkColor : borderColor,
                  width: 1.5,
                ),
              ),
              child: task.done
                  ? const Icon(Icons.check,
                      size: 11, color: AppColors.background)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
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
      ),
    );
  }
}
