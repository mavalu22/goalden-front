import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/goal_colors.dart' show GoalColor;
import '../../goals/providers/goal_provider.dart' show goalColorMapProvider;
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
    final dayData = ref.watch(historyDayDataProvider);
    final isLoading = ref.watch(historyTasksProvider).isLoading;

    if (!isLoading && _scrolledForRange != range) {
      _scrolledForRange = range;
      // Clear selection when range changes
      if (_selectedDay != null) setState(() => _selectedDay = null);
      _scrollToEnd();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = range.startDate(today);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= AppConstants.mobileBreakpoint;
        final hPad = isDesktop ? AppSpacing.xxxl : AppSpacing.lg;
        final cellSize = isDesktop ? 14.0 : 12.0;
        const gap = 2.0;

        final heatmap = isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.golden),
                  strokeWidth: 2,
                ),
              )
            : Padding(
                padding: EdgeInsets.fromLTRB(
                    hPad, AppSpacing.sm, hPad, AppSpacing.lg),
                child: SingleChildScrollView(
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
                  ),
                ),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  hPad, AppSpacing.lg, hPad, AppSpacing.md),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'History',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _RangeSelector(
                    selected: range,
                    onSelect: (r) =>
                        ref.read(historyRangeProvider.notifier).state = r,
                  ),
                ],
              ),
            ),
            Expanded(
              child: isDesktop && _selectedDay != null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: heatmap),
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
                  : heatmap,
            ),
          ],
        );
      },
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? AppColors.golden : AppColors.textMuted,
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
  });

  final Map<DateTime, DayData> dayData;
  final DateTime rangeStart;
  final DateTime today;
  final double cellSize;
  final double gap;
  final void Function(DateTime) onCellTap;
  final DateTime? selectedDate;

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

    final fill = _activityColor(completed);

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
