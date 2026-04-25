import '../models/goal.dart';

abstract class GoalRepository {
  /// Stream of all active goals. Emits on every change.
  Stream<List<Goal>> watchActiveGoals();

  /// Stream of all archived goals.
  Stream<List<Goal>> watchArchivedGoals();

  /// One-shot fetch of all non-deleted goals.
  Future<List<Goal>> getAllGoals();

  /// Fetch a single goal by id.
  Future<Goal?> getGoalById(String id);

  /// Reactive stream for a single non-deleted goal by id.
  Stream<Goal?> watchGoalById(String id);

  /// Persist a new goal.
  Future<void> createGoal(Goal goal);

  /// Persist changes to an existing goal.
  Future<void> updateGoal(Goal goal);

  /// Archive a goal (sets status to archived).
  Future<void> archiveGoal(String id);

  /// Restore an archived goal to active.
  Future<void> unarchiveGoal(String id);

  /// Permanently remove a goal (soft-delete for sync).
  Future<void> deleteGoal(String id);
}
