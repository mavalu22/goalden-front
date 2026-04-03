import '../models/task.dart';

abstract class TaskRepository {
  /// Stream of tasks for a specific day. Emits on every change.
  Stream<List<Task>> watchTasksForDate(DateTime date);

  /// One-shot fetch of tasks for a specific day.
  Future<List<Task>> getTasksForDate(DateTime date);

  /// Tasks not yet completed from days before [date].
  Future<List<Task>> getPendingTasksBefore(DateTime date);

  /// Persist a new task.
  Future<void> createTask(Task task);

  /// Persist changes to an existing task.
  Future<void> updateTask(Task task);

  /// Permanently remove a task.
  Future<void> deleteTask(String id);
}
