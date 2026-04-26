import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();
  HistoryRange? _scrolledForRange;

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

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(historyRangeProvider);
    final dayData = ref.watch(historyDayDataProvider);
    final isLoading = ref.watch(historyTasksProvider).isLoading;

    if (!isLoading && _scrolledForRange != range) {
      _scrolledForRange = range;
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, AppSpacing.lg, hPad, AppSpacing.md),
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
              child: isLoading
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
                        ),
                      ),
                    ),
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
  });

  final Map<DateTime, DayData> dayData;
  final DateTime rangeStart;
  final DateTime today;
  final double cellSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    // First Monday on or before rangeStart
    final firstMonday =
        rangeStart.subtract(Duration(days: rangeStart.weekday - 1));
    // Last Sunday on or after today
    final lastSunday = today.add(Duration(days: 7 - today.weekday));

    final weeks = <DateTime>[];
    var cursor = firstMonday;
    while (!cursor.isAfter(lastSunday)) {
      weeks.add(cursor);
      cursor = cursor.add(const Duration(days: 7));
    }

    // Month label at each column where the visible month name changes
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
        // Weekday labels column
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
        // Week columns
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
    final isInRange =
        !date.isBefore(rangeStart) && !date.isAfter(today);

    if (!isInRange) {
      return SizedBox(width: cellSize, height: cellSize + gap);
    }

    final data = dayData[date];
    final completed = data?.completed ?? 0;
    final planned = data?.planned ?? 0;
    final tooltipMsg = completed == 0 && planned == 0
        ? DateFormat('MMM d, yyyy').format(date)
        : '${DateFormat('MMM d, yyyy').format(date)} · $completed of $planned completed';

    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Tooltip(
        message: tooltipMsg,
        waitDuration: const Duration(milliseconds: 300),
        child: Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            color: _cellColor(completed),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Color _cellColor(int completed) {
    // Golden ramp: 0 tasks = very faint, 5+ = full golden
    if (completed == 0) return const Color(0x0FD4AF37);
    if (completed == 1) return const Color(0x33D4AF37);
    if (completed == 2) return const Color(0x66D4AF37);
    if (completed == 3) return const Color(0x99D4AF37);
    if (completed == 4) return const Color(0xCCD4AF37);
    return AppColors.golden;
  }
}
