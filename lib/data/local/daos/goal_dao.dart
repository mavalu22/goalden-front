import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/goal_table.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  // ── Read operations ───────────────────────────────────────────────────────

  /// All non-deleted goals for this user, ordered by starred desc then createdAt asc.
  Stream<List<GoalEntry>> watchAllGoals() {
    return (select(goals)
          ..where((g) => g.deletedAt.isNull())
          ..orderBy([
            (g) => OrderingTerm.desc(g.starred),
            (g) => OrderingTerm.asc(g.createdAt),
          ]))
        .watch();
  }

  /// All non-deleted active goals.
  Stream<List<GoalEntry>> watchActiveGoals() {
    return (select(goals)
          ..where(
            (g) => g.status.equals('active') & g.deletedAt.isNull(),
          )
          ..orderBy([
            (g) => OrderingTerm.desc(g.starred),
            (g) => OrderingTerm.asc(g.createdAt),
          ]))
        .watch();
  }

  /// All non-deleted archived goals.
  Stream<List<GoalEntry>> watchArchivedGoals() {
    return (select(goals)
          ..where(
            (g) => g.status.equals('archived') & g.deletedAt.isNull(),
          )
          ..orderBy([
            (g) => OrderingTerm.desc(g.archivedAt),
          ]))
        .watch();
  }

  /// Fetch a single goal by id.
  Future<GoalEntry?> getGoalById(String id) {
    return (select(goals)..where((g) => g.id.equals(id))).getSingleOrNull();
  }

  /// Reactive stream for a single non-deleted goal by id.
  Stream<GoalEntry?> watchGoalById(String id) {
    return (select(goals)
          ..where((g) => g.id.equals(id) & g.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  /// One-shot fetch of all non-deleted goals.
  Future<List<GoalEntry>> getAllGoals() {
    return (select(goals)..where((g) => g.deletedAt.isNull())).get();
  }

  // ── Write operations ──────────────────────────────────────────────────────

  Future<void> insertGoal(GoalsCompanion entry) =>
      into(goals).insert(entry);

  Future<bool> updateGoal(GoalsCompanion entry) =>
      update(goals).replace(entry);

  Future<void> softDeleteGoal(String id) {
    final now = DateTime.now().toUtc();
    return (update(goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pending_delete'),
      ),
    );
  }

  Future<void> archiveGoal(String id) {
    final now = DateTime.now().toUtc();
    return (update(goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        status: const Value('archived'),
        archivedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pending_update'),
      ),
    );
  }

  Future<void> unarchiveGoal(String id) {
    final now = DateTime.now().toUtc();
    return (update(goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        status: const Value('active'),
        archivedAt: const Value(null),
        updatedAt: Value(now),
        syncStatus: const Value('pending_update'),
      ),
    );
  }

  // ── Sync operations ───────────────────────────────────────────────────────

  Future<List<GoalEntry>> getPendingSyncGoals() {
    return (select(goals)
          ..where((g) => g.syncStatus.isNotValue('synced')))
        .get();
  }

  Future<void> upsertFromCloud(GoalsCompanion entry) async {
    final id = entry.id.value;
    final existing = await (select(goals)
          ..where((g) => g.id.equals(id)))
        .getSingleOrNull();

    if (existing == null) {
      await into(goals).insert(
        entry.copyWith(
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now().toUtc()),
        ),
      );
    } else {
      final incomingUpdated = entry.updatedAt.present
          ? entry.updatedAt.value
          : existing.updatedAt;
      if (!incomingUpdated.isAfter(existing.updatedAt)) return;

      await (update(goals)..where((g) => g.id.equals(id))).write(
        entry.copyWith(
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
  }

  Future<void> markSynced(String id) {
    return (update(goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
