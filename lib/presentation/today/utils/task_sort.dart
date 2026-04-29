import '../../../domain/models/task.dart';

/// Sorts tasks:
/// 1. Timed uncompleted tasks (sorted by start time)
/// 2. Untimed uncompleted tasks
/// 3. Completed tasks (by completedAt)
///
/// Within each group, [sortOrder] and [createdAt] are used as tiebreakers.
List<Task> sortTasks(List<Task> tasks) {
  final timed = tasks
      .where((t) => !t.done && t.startTimeMinutes != null)
      .toList()
    ..sort((a, b) {
      final timeCmp = a.startTimeMinutes!.compareTo(b.startTimeMinutes!);
      if (timeCmp != 0) return timeCmp;
      final cmp = a.sortOrder.compareTo(b.sortOrder);
      return cmp != 0 ? cmp : a.createdAt.compareTo(b.createdAt);
    });

  final untimed = tasks
      .where((t) => !t.done && t.startTimeMinutes == null)
      .toList()
    ..sort((a, b) {
      final cmp = a.sortOrder.compareTo(b.sortOrder);
      return cmp != 0 ? cmp : a.createdAt.compareTo(b.createdAt);
    });

  final completed = tasks.where((t) => t.done).toList()
    ..sort((a, b) {
      final ca = a.completedAt ?? a.createdAt;
      final cb = b.completedAt ?? b.createdAt;
      return ca.compareTo(cb);
    });

  return [...timed, ...untimed, ...completed];
}
