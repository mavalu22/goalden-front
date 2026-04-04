import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/task.dart';
import '../../../providers/database_provider.dart';

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

/// Human-readable label for the week navigation bar.
final weekLabelProvider = Provider<String>((ref) {
  final offset = ref.watch(weekOffsetProvider);
  if (offset == 0) return 'This week';
  if (offset == 1) return 'Next week';
  if (offset == -1) return 'Last week';
  if (offset > 0) return '$offset weeks ahead';
  return '${offset.abs()} weeks ago';
});

/// Reactive stream of tasks for a specific calendar day.
final tasksForDateProvider =
    StreamProvider.family<List<Task>, DateTime>((ref, date) async* {
  final repo = await ref.watch(taskRepositoryProvider.future);
  yield* repo.watchTasksForDate(date);
});

/// All tasks for the current viewed week (Monday–Sunday), as a reactive stream.
final weekTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final repo = await ref.watch(taskRepositoryProvider.future);
  final weekStart = ref.watch(weekStartProvider);
  final weekEnd = weekStart.add(const Duration(days: 6));
  yield* repo.watchTasksForDateRange(weekStart, weekEnd);
});
