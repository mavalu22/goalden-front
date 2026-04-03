import '../models/task.dart';

abstract class TaskRepository {
  /// Stream of tasks for a specific day. Emits on every change.
  Stream<List<Task>> watchTasksForDate(DateTime date);

  /// One-shot fetch of tasks for a specific day.
  Future<List<Task>> getTasksForDate(DateTime date);

  /// Tasks not yet completed from days before [date].
  Future<List<Task>> getPendingTasksBefore(DateTime date);

  /// Reactive stream of uncompleted tasks from days before [date].
  Stream<List<Task>> watchPendingTasksBefore(DateTime date);

  /// Persist a new task.
  Future<void> createTask(Task task);

  /// Persist changes to an existing task.
  Future<void> updateTask(Task task);

  /// Permanently remove a task.
  Future<void> deleteTask(String id);

  /// Update sortOrder for a list of tasks based on their new positions.
  Future<void> reorderTasks(List<Task> reorderedTasks);

  /// Delete all uncompleted tasks pending for more than [days] days.
  Future<void> deleteOldPendingTasks({int days = 7});

  /// Reactive stream of all tasks within a date range [start, end] inclusive.
  Stream<List<Task>> watchTasksForDateRange(DateTime start, DateTime end);
}
