import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/milestone.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/sync_provider.dart';

export '../../../domain/models/milestone.dart' show Milestone;

const _uuid = Uuid();

/// Reactive stream of milestones for a specific goal.
final milestonesForGoalProvider =
    StreamProvider.family<List<Milestone>, String>((ref, goalId) async* {
  final repo = await ref.watch(milestoneRepositoryProvider.future);
  yield* repo.watchMilestonesForGoal(goalId);
});

final milestoneListProvider =
    AsyncNotifierProvider.family<MilestoneListNotifier, List<Milestone>, String>(
  MilestoneListNotifier.new,
);

class MilestoneListNotifier
    extends FamilyAsyncNotifier<List<Milestone>, String> {
  @override
  Future<List<Milestone>> build(String goalId) async {
    final repo = await ref.watch(milestoneRepositoryProvider.future);
    return repo.getMilestonesForGoal(goalId);
  }

  Future<void> createMilestone({
    required String goalId,
    required String title,
    required DateTime date,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.length > 500) return;

    final userId =
        ref.read(authUserProvider).valueOrNull?.id ?? '';
    if (userId.isEmpty) return;

    final repo = await ref.read(milestoneRepositoryProvider.future);
    final now = DateTime.now().toUtc();
    final milestone = Milestone(
      id: _uuid.v4(),
      goalId: goalId,
      userId: userId,
      title: trimmed,
      date: date,
      createdAt: now,
      updatedAt: now,
    );
    await repo.createMilestone(milestone);
    ref.read(syncActionsProvider.notifier).pushSync();
  }

  Future<void> updateMilestone(Milestone milestone) async {
    final trimmed = milestone.title.trim();
    if (trimmed.isEmpty || trimmed.length > 500) return;
    final repo = await ref.read(milestoneRepositoryProvider.future);
    await repo.updateMilestone(milestone.copyWith(title: trimmed));
    ref.read(syncActionsProvider.notifier).pushSync();
  }

  Future<void> toggleDone(String milestoneId, {required bool done}) async {
    final repo = await ref.read(milestoneRepositoryProvider.future);
    await repo.completeMilestone(milestoneId, done: done);
    ref.read(syncActionsProvider.notifier).pushSync();
  }

  Future<void> deleteMilestone(String milestoneId) async {
    final repo = await ref.read(milestoneRepositoryProvider.future);
    await repo.deleteMilestone(milestoneId);
    ref.read(syncActionsProvider.notifier).pushSync();
  }
}
