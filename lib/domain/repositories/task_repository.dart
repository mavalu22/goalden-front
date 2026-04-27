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

  /// All source recurring tasks (tasks with recurrence != none and no sourceTaskId).
  Future<List<Task>> getRecurringSourceTasks();

  /// Check if a recurring instance already exists for [sourceTaskId] on [date].
  Future<bool> recurringInstanceExists(String sourceTaskId, DateTime date);

  /// Delete all future instances of a recurring source task (today and forward).
  Future<void> deleteFutureInstances(String sourceTaskId, DateTime fromDate);

  /// Backfill [goalId] on all generated instances of [sourceTaskId] that have
  /// no goal link. Idempotent — no-op if all instances already carry the goal.
  Future<void> healInstanceGoalIds(String sourceTaskId, String goalId);

  /// Unlink all non-deleted tasks that reference [goalId] (set goal_id to null).
  /// Called when a goal is deleted.
  Future<void> unlinkTasksFromGoal(String goalId);

  /// Reactive stream of all non-deleted tasks linked to a specific goal.
  Stream<List<Task>> watchTasksForGoal(String goalId);
}
