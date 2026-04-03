import '../../../domain/models/task.dart';

/// Sorts tasks: high priority uncompleted → normal uncompleted → completed.
/// Within each group, sorts by [sortOrder] ascending, then [createdAt] as tiebreaker.
List<Task> sortTasks(List<Task> tasks) {
  final highUncompleted = tasks
      .where((t) => !t.done && t.priority == TaskPriority.high)
      .toList()
    ..sort((a, b) {
      final cmp = a.sortOrder.compareTo(b.sortOrder);
      return cmp != 0 ? cmp : a.createdAt.compareTo(b.createdAt);
    });

  final normalUncompleted = tasks
      .where((t) => !t.done && t.priority == TaskPriority.normal)
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

  return [...highUncompleted, ...normalUncompleted, ...completed];
}
