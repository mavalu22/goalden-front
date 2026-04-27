import 'package:flutter_riverpod/flutter_riverpod.dart';

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
