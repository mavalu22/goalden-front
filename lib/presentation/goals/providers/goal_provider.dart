import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/goal_colors.dart';
import '../../../domain/models/goal.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';

export '../../../domain/models/goal.dart' show Goal, GoalStatus;

const _maxTitleLength = 500;
const _uuid = Uuid();

final activeGoalsProvider = StreamProvider<List<Goal>>((ref) async* {
  final repo = await ref.watch(goalRepositoryProvider.future);
  yield* repo.watchActiveGoals();
});

final archivedGoalsProvider = StreamProvider<List<Goal>>((ref) async* {
  final repo = await ref.watch(goalRepositoryProvider.future);
  yield* repo.watchArchivedGoals();
});

/// Task counts (open, total) for each goal id.
/// Returns a map of goalId → (open: int, total: int).
final goalTaskCountsProvider =
    FutureProvider<Map<String, ({int open, int total})>>((ref) async {
  final dao = await ref.watch(taskDaoProvider.future);
  return dao.getTaskCountsByGoal();
});

/// Reactive stream for a single goal by id. Emits null if goal is deleted.
final goalByIdProvider =
    StreamProvider.family<Goal?, String>((ref, goalId) async* {
  final repo = await ref.watch(goalRepositoryProvider.future);
  yield* repo.watchGoalById(goalId);
});

/// Task stats (open, total, thisWeek) for a specific goal — reactive stream.
final goalDetailStatsProvider = StreamProvider.family<
    ({int open, int total, int thisWeek}), String>((ref, goalId) async* {
  final dao = await ref.watch(taskDaoProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));

  yield* dao.watchTasksForGoal(goalId).map((entries) {
    int open = 0, total = 0, thisWeek = 0;
    for (final e in entries) {
      total++;
      if (!e.done) open++;
      if (!e.date.isBefore(weekStart) && e.date.isBefore(weekEnd)) thisWeek++;
    }
    return (open: open, total: total, thisWeek: thisWeek);
  });
});

/// Whether the Goals screen is showing archived goals.
final showArchivedGoalsProvider = StateProvider<bool>((ref) => false);

final goalListProvider = AsyncNotifierProvider<GoalListNotifier, List<Goal>>(
  GoalListNotifier.new,
);

class GoalListNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    final repo = await ref.watch(goalRepositoryProvider.future);
    // Return the current snapshot; use activeGoalsProvider for reactive stream.
    return repo.getAllGoals();
  }

  Future<void> createGoal({
    required String title,
    String? description,
    String? color,
    DateTime? deadline,
    bool starred = false,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.length > _maxTitleLength) return;

    final userId =
        ref.read(authUserProvider).valueOrNull?.id ?? '';
    if (userId.isEmpty) return;

    final repo = await ref.read(goalRepositoryProvider.future);

    // Auto-suggest a palette color if none was specified.
    String resolvedColor = color ?? '';
    if (resolvedColor.isEmpty) {
      final existing = await repo.getAllGoals();
      resolvedColor = GoalColors.suggest(existing.length).id;
    }

    final now = DateTime.now().toUtc();
    final goal = Goal(
      id: _uuid.v4(),
      userId: userId,
      title: trimmed,
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      color: resolvedColor,
      deadline: deadline,
      starred: starred,
      createdAt: now,
      updatedAt: now,
    );
    await repo.createGoal(goal);
  }

  Future<void> updateGoal(Goal goal) async {
    final trimmed = goal.title.trim();
    if (trimmed.isEmpty || trimmed.length > _maxTitleLength) return;
    final repo = await ref.read(goalRepositoryProvider.future);
    await repo.updateGoal(goal.copyWith(title: trimmed));
  }

  Future<void> archiveGoal(String id) async {
    final repo = await ref.read(goalRepositoryProvider.future);
    await repo.archiveGoal(id);
  }

  Future<void> unarchiveGoal(String id) async {
    final repo = await ref.read(goalRepositoryProvider.future);
    await repo.unarchiveGoal(id);
  }

  Future<void> deleteGoal(String id) async {
    // Unlink tasks (not deleted) and tombstone milestones before soft-deleting.
    final taskRepo = await ref.read(taskRepositoryProvider.future);
    await taskRepo.unlinkTasksFromGoal(id);

    final milestoneRepo = await ref.read(milestoneRepositoryProvider.future);
    await milestoneRepo.deleteMilestonesForGoal(id);

    final repo = await ref.read(goalRepositoryProvider.future);
    await repo.deleteGoal(id);
  }
}
