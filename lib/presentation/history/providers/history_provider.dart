import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/task.dart';
import '../../../providers/database_provider.dart';

export '../../../domain/models/task.dart' show Task;

enum HistoryRange { last90Days, thisYear, last12Months }

extension HistoryRangeX on HistoryRange {
  String get label {
    switch (this) {
      case HistoryRange.last90Days:
        return '90d';
      case HistoryRange.thisYear:
        return 'Year';
      case HistoryRange.last12Months:
        return '12m';
    }
  }

  DateTime startDate(DateTime today) {
    switch (this) {
      case HistoryRange.last90Days:
        return today.subtract(const Duration(days: 89));
      case HistoryRange.thisYear:
        return DateTime(today.year, 1, 1);
      case HistoryRange.last12Months:
        return DateTime(today.year - 1, today.month, today.day);
    }
  }
}

typedef DayData = ({int completed, int planned});

final historyRangeProvider =
    StateProvider<HistoryRange>((ref) => HistoryRange.last12Months);

final historyTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final range = ref.watch(historyRangeProvider);
  final repo = await ref.watch(taskRepositoryProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  yield* repo.watchTasksForDateRange(range.startDate(today), today);
});

/// Tasks for a specific day in the history drill-down.
final historyDayTasksProvider =
    StreamProvider.family<List<Task>, DateTime>((ref, date) async* {
  final repo = await ref.watch(taskRepositoryProvider.future);
  yield* repo.watchTasksForDate(date);
});

// ─── View mode (Activity vs By goal) ─────────────────────────────────────────

enum HistoryViewMode { activity, byGoal }

const _kViewModeKey = 'history_view_mode';

/// Loads the persisted view mode preference (async, used once at startup).
final historyViewModeInitProvider =
    FutureProvider<HistoryViewMode>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kViewModeKey);
  return raw == 'byGoal' ? HistoryViewMode.byGoal : HistoryViewMode.activity;
});

class HistoryViewModeNotifier extends Notifier<HistoryViewMode> {
  @override
  HistoryViewMode build() {
    // Seed from persisted value; will be overwritten once future resolves.
    ref.listen(historyViewModeInitProvider, (_, next) {
      if (next.hasValue) state = next.value!;
    });
    return HistoryViewMode.activity;
  }

  Future<void> toggle() async {
    final next = state == HistoryViewMode.activity
        ? HistoryViewMode.byGoal
        : HistoryViewMode.activity;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kViewModeKey, next == HistoryViewMode.byGoal ? 'byGoal' : 'activity');
  }
}

final historyViewModeProvider =
    NotifierProvider<HistoryViewModeNotifier, HistoryViewMode>(
  HistoryViewModeNotifier.new,
);

/// Per-day dominant goalId: the goal with the most tasks that day.
/// Returns null for the day when no goal dominates (tied, or no goals).
final historyDominantGoalProvider =
    Provider<Map<DateTime, String?>>((ref) {
  final tasks = ref.watch(historyTasksProvider).valueOrNull ?? [];

  // Accumulate task counts per date per goalId.
  final goalCounts = <DateTime, Map<String?, int>>{};
  for (final task in tasks) {
    final d = task.date.toLocal();
    final key = DateTime(d.year, d.month, d.day);
    final counts = goalCounts.putIfAbsent(key, () => {});
    counts[task.goalId] = (counts[task.goalId] ?? 0) + 1;
  }

  final result = <DateTime, String?>{};
  for (final entry in goalCounts.entries) {
    final goalOnly = Map.fromEntries(
      entry.value.entries.where((e) => e.key != null),
    );
    if (goalOnly.isEmpty) {
      result[entry.key] = null;
      continue;
    }
    final maxCount = goalOnly.values.reduce((a, b) => a > b ? a : b);
    final top = goalOnly.entries.where((e) => e.value == maxCount).toList();
    result[entry.key] = top.length == 1 ? top.first.key : null;
  }
  return result;
});

// ─── Day completion data ──────────────────────────────────────────────────────

final historyDayDataProvider = Provider<Map<DateTime, DayData>>((ref) {
  final tasks = ref.watch(historyTasksProvider).valueOrNull ?? [];
  final map = <DateTime, DayData>{};
  for (final task in tasks) {
    final d = task.date.toLocal();
    final key = DateTime(d.year, d.month, d.day);
    final existing = map[key] ?? (completed: 0, planned: 0);
    map[key] = (
      completed: existing.completed + (task.done ? 1 : 0),
      planned: existing.planned + 1,
    );
  }
  return map;
});
