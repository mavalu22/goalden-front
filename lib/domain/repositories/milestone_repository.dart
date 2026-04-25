import '../models/milestone.dart';

abstract class MilestoneRepository {
  /// Reactive stream of milestones for a goal, ordered by date.
  Stream<List<Milestone>> watchMilestonesForGoal(String goalId);

  /// One-shot fetch of milestones for a goal.
  Future<List<Milestone>> getMilestonesForGoal(String goalId);

  /// Create a new milestone.
  Future<void> createMilestone(Milestone milestone);

  /// Update an existing milestone.
  Future<void> updateMilestone(Milestone milestone);

  /// Toggle the done state of a milestone.
  Future<void> completeMilestone(String id, {required bool done});

  /// Soft-delete a milestone.
  Future<void> deleteMilestone(String id);

  /// Soft-delete all milestones for a goal (called on goal deletion).
  Future<void> deleteMilestonesForGoal(String goalId);
}
