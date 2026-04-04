import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/task.dart';
import '../../../providers/database_provider.dart';

export '../../../providers/database_provider.dart'
    show recurrenceServiceProvider;

/// Current week offset from this week (0 = this week, 1 = next, -1 = last).
final weekOffsetProvider = StateProvider<int>((ref) => 0);

/// Monday of the currently viewed week.
final weekStartProvider = Provider<DateTime>((ref) {
  final offset = ref.watch(weekOffsetProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return monday.add(Duration(days: offset * 7));
});

/// Human-readable date-range label for the week navigation bar.
/// Format: "April 7–13" (same month) or "March 31 – April 6" (different months).
/// For cross-year weeks: "Dec 29 – Jan 4, 2027".
final weekLabelProvider = Provider<String>((ref) {
  final weekStart = ref.watch(weekStartProvider);
  final weekEnd = weekStart.add(const Duration(days: 6));

  if (weekStart.month == weekEnd.month) {
    final month = DateFormat('MMMM').format(weekStart);
    return '$month ${weekStart.day}–${weekEnd.day}';
  } else if (weekStart.year == weekEnd.year) {
    return '${DateFormat('MMMM d').format(weekStart)} – ${DateFormat('MMMM d').format(weekEnd)}';
  } else {
    // Cross-year week (e.g. Dec 29 – Jan 4)
    return '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d, y').format(weekEnd)}';
  }
});

/// Reactive stream of tasks for a specific calendar day.
final tasksForDateProvider =
    StreamProvider.family<List<Task>, DateTime>((ref, date) async* {
  final repo = await ref.watch(taskRepositoryProvider.future);
  yield* repo.watchTasksForDate(date);
});

/// All tasks for the current viewed week (Monday–Sunday), as a reactive stream.
/// Also triggers recurrence generation for each day of the viewed week.
final weekTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final repo = await ref.watch(taskRepositoryProvider.future);
  final svc = await ref.watch(recurrenceServiceProvider.future);
  final weekStart = ref.watch(weekStartProvider);
  final weekEnd = weekStart.add(const Duration(days: 6));

  // Generate recurring instances for every day in the visible week.
  for (var i = 0; i <= 6; i++) {
    final day = weekStart.add(Duration(days: i));
    await svc.generateForDate(day);
  }

  yield* repo.watchTasksForDateRange(weekStart, weekEnd);
});
