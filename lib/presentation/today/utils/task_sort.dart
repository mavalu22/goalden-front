import '../../../domain/models/task.dart';

/// Sorts tasks:
/// 1. Timed uncompleted tasks (sorted by start time, then priority within same slot)
/// 2. Untimed high-priority uncompleted
/// 3. Untimed normal-priority uncompleted
/// 4. Completed tasks (by completedAt)
///
/// Within each group, [sortOrder] and [createdAt] are used as tiebreakers.
List<Task> sortTasks(List<Task> tasks) {
  // Tasks with a time range come first, sorted by start time.
  final timed = tasks
      .where((t) => !t.done && t.startTimeMinutes != null)
      .toList()
    ..sort((a, b) {
      final timeCmp = a.startTimeMinutes!.compareTo(b.startTimeMinutes!);
      if (timeCmp != 0) return timeCmp;
      // Same start time: high priority first
      if (a.priority != b.priority) {
        return a.priority == TaskPriority.high ? -1 : 1;
      }
      final cmp = a.sortOrder.compareTo(b.sortOrder);
      return cmp != 0 ? cmp : a.createdAt.compareTo(b.createdAt);
    });

  final highUncompleted = tasks
      .where((t) =>
          !t.done &&
          t.startTimeMinutes == null &&
          t.priority == TaskPriority.high)
      .toList()
    ..sort((a, b) {
      final cmp = a.sortOrder.compareTo(b.sortOrder);
      return cmp != 0 ? cmp : a.createdAt.compareTo(b.createdAt);
    });

  final normalUncompleted = tasks
      .where((t) =>
          !t.done &&
          t.startTimeMinutes == null &&
          t.priority == TaskPriority.normal)
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

  return [...timed, ...highUncompleted, ...normalUncompleted, ...completed];
}
