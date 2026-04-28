import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/milestone_table.dart';

part 'milestone_dao.g.dart';

@DriftAccessor(tables: [Milestones])
class MilestoneDao extends DatabaseAccessor<AppDatabase>
    with _$MilestoneDaoMixin {
  MilestoneDao(super.db);

  // ── Read operations ───────────────────────────────────────────────────────

  /// Non-deleted milestones for a goal, ordered by date ascending.
  Stream<List<MilestoneEntry>> watchMilestonesForGoal(String goalId) {
    return (select(milestones)
          ..where(
            (m) => m.goalId.equals(goalId) & m.deletedAt.isNull(),
          )
          ..orderBy([(m) => OrderingTerm.asc(m.date)]))
        .watch();
  }

  Future<List<MilestoneEntry>> getMilestonesForGoal(String goalId) {
    return (select(milestones)
          ..where(
            (m) => m.goalId.equals(goalId) & m.deletedAt.isNull(),
          )
          ..orderBy([(m) => OrderingTerm.asc(m.date)]))
        .get();
  }

  Future<MilestoneEntry?> getMilestoneById(String id) {
    return (select(milestones)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  // ── Write operations ──────────────────────────────────────────────────────

  Future<void> insertMilestone(MilestonesCompanion entry) =>
      into(milestones).insert(entry);

  Future<bool> updateMilestone(MilestonesCompanion entry) =>
      update(milestones).replace(entry);

  /// Soft-delete a milestone.
  Future<void> softDeleteMilestone(String id) {
    final now = DateTime.now().toUtc();
    return (update(milestones)..where((m) => m.id.equals(id))).write(
      MilestonesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pending_delete'),
      ),
    );
  }

  /// Soft-delete all non-deleted milestones for a goal.
  /// Called when a goal is deleted so its milestones are tombstoned.
  Future<void> softDeleteMilestonesForGoal(String goalId) {
    final now = DateTime.now().toUtc();
    return (update(milestones)
          ..where(
            (m) => m.goalId.equals(goalId) & m.deletedAt.isNull(),
          ))
        .write(
      MilestonesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pending_delete'),
      ),
    );
  }

  // ── Sync operations ───────────────────────────────────────────────────────

  Future<List<MilestoneEntry>> getPendingSyncMilestones() {
    return (select(milestones)
          ..where((m) => m.syncStatus.isNotValue('synced')))
        .get();
  }

  Future<void> upsertFromCloud(MilestonesCompanion entry) async {
    final id = entry.id.value;
    final existing = await (select(milestones)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();

    if (existing == null) {
      await into(milestones).insert(
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
      await (update(milestones)..where((m) => m.id.equals(id))).write(
        entry.copyWith(
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
  }

  Future<void> markSynced(String id) {
    return (update(milestones)..where((m) => m.id.equals(id))).write(
      MilestonesCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Marks a server-deleted milestone as deleted locally if it exists.
  Future<void> applyServerDeletion(String id) async {
    final existing = await (select(milestones)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) return;

    final now = DateTime.now().toUtc();
    await (update(milestones)..where((m) => m.id.equals(id))).write(
      MilestonesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(now),
      ),
    );
  }

  Future<int> purgeDeletedSyncedMilestones() {
    return (delete(milestones)
          ..where(
            (m) =>
                m.deletedAt.isNotNull() & m.syncStatus.equals('synced'),
          ))
        .go();
  }
}
