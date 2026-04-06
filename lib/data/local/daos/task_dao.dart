import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/task_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  // ── Read operations ───────────────────────────────────────────────────────

  /// All non-deleted tasks for a specific calendar day (UTC).
  Future<List<TaskEntry>> getTasksForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(tasks)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(dayStart) &
                t.date.isSmallerThanValue(dayEnd) &
                t.deletedAt.isNull(),
          ))
        .get();
  }

  /// All non-deleted uncompleted tasks with a date strictly before [date].
  Future<List<TaskEntry>> getPendingTasksBefore(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return (select(tasks)
          ..where(
            (t) =>
                t.date.isSmallerThanValue(dayStart) &
                t.done.equals(false) &
                t.deletedAt.isNull(),
          ))
        .get();
  }

  /// Watch non-deleted tasks for today — reactive stream.
  Stream<List<TaskEntry>> watchTasksForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(tasks)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(dayStart) &
                t.date.isSmallerThanValue(dayEnd) &
                t.deletedAt.isNull(),
          ))
        .watch();
  }

  /// Watch non-deleted uncompleted tasks before [date] — reactive stream.
  Stream<List<TaskEntry>> watchPendingTasksBefore(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return (select(tasks)
          ..where(
            (t) =>
                t.date.isSmallerThanValue(dayStart) &
                t.done.equals(false) &
                t.deletedAt.isNull(),
          ))
        .watch();
  }

  /// Watch non-deleted tasks within a date range — reactive stream.
  Stream<List<TaskEntry>> watchTasksForDateRange(DateTime start, DateTime end) {
    final startLocal = DateTime(start.year, start.month, start.day);
    final endLocal =
        DateTime(end.year, end.month, end.day + 1); // exclusive end
    return (select(tasks)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(startLocal) &
                t.date.isSmallerThanValue(endLocal) &
                t.deletedAt.isNull(),
          ))
        .watch();
  }

  /// All non-deleted source recurring tasks.
  Future<List<TaskEntry>> getRecurringSourceTasks() {
    return (select(tasks)
          ..where(
            (t) =>
                t.recurrence.isNotValue('none') &
                t.sourceTaskId.isNull() &
                t.deletedAt.isNull(),
          ))
        .get();
  }

  /// Whether a non-deleted recurring instance exists for [sourceId] on [date].
  Future<bool> recurringInstanceExists(String sourceId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final rows = await (select(tasks)
          ..where(
            (t) =>
                t.sourceTaskId.equals(sourceId) &
                t.date.isBiggerOrEqualValue(dayStart) &
                t.date.isSmallerThanValue(dayEnd) &
                t.deletedAt.isNull(),
          ))
        .get();
    return rows.isNotEmpty;
  }

  // ── Write operations ──────────────────────────────────────────────────────

  Future<void> insertTask(TasksCompanion entry) =>
      into(tasks).insert(entry);

  Future<bool> updateTask(TasksCompanion entry) =>
      update(tasks).replace(entry);

  /// Soft-delete a task: sets deletedAt and marks it pending_delete.
  /// The row is retained until the deletion is propagated to the cloud.
  Future<void> softDeleteTask(String id) {
    final now = DateTime.now().toUtc();
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pending_delete'),
      ),
    );
  }

  /// Update sortOrder for a specific task.
  Future<void> updateSortOrder(String id, int order) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(sortOrder: Value(order)),
      );

  /// Batch update sortOrder for multiple tasks in a single transaction.
  Future<void> reorderTasksBatch(List<({String id, int order})> updates) =>
      transaction(() async {
        for (final u in updates) {
          await (update(tasks)..where((t) => t.id.equals(u.id))).write(
            TasksCompanion(sortOrder: Value(u.order)),
          );
        }
      });

  /// Soft-delete non-deleted uncompleted tasks with a date before [cutoff].
  Future<void> softDeleteOldPendingTasks(DateTime cutoff) async {
    final dayStart = DateTime(cutoff.year, cutoff.month, cutoff.day);
    final now = DateTime.now().toUtc();
    await (update(tasks)
          ..where(
            (t) =>
                t.date.isSmallerThanValue(dayStart) &
                t.done.equals(false) &
                t.deletedAt.isNull(),
          ))
        .write(
      TasksCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pending_delete'),
      ),
    );
  }

  /// Delete future recurring instances of [sourceId] starting from [fromDate].
  Future<int> deleteFutureInstances(String sourceId, DateTime fromDate) {
    final dayStart = DateTime(fromDate.year, fromDate.month, fromDate.day);
    return (delete(tasks)
          ..where(
            (t) =>
                t.sourceTaskId.equals(sourceId) &
                t.date.isBiggerOrEqualValue(dayStart),
          ))
        .go();
  }

  // ── Sync operations ───────────────────────────────────────────────────────

  /// All tasks that need to be pushed to the cloud (syncStatus != 'synced').
  /// Includes pending_delete rows so deletions are propagated.
  Future<List<TaskEntry>> getPendingSyncTasks() {
    return (select(tasks)
          ..where((t) => t.syncStatus.isNotValue('synced')))
        .get();
  }

  /// Upsert a task record received from the cloud.
  /// If the row already exists, it is replaced only when the incoming
  /// updated_at is newer (last-write-wins). If it doesn't exist, it is inserted.
  Future<void> upsertFromCloud(TasksCompanion entry) async {
    final id = entry.id.value;
    final existing = await (select(tasks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing == null) {
      // New task from the cloud — insert and mark as synced.
      await into(tasks).insert(
        entry.copyWith(
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now().toUtc()),
        ),
      );
    } else {
      // Only overwrite if the incoming record is newer.
      final incomingUpdated = entry.updatedAt.present
          ? entry.updatedAt.value
          : existing.updatedAt;
      if (!incomingUpdated.isAfter(existing.updatedAt)) return;

      await (update(tasks)..where((t) => t.id.equals(id))).write(
        entry.copyWith(
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
  }

  /// Mark a task as fully synced after a successful push/pull round.
  Future<void> markSynced(String id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Apply a server-initiated deletion using last-write-wins.
  ///
  /// The task is only soft-deleted locally if [serverDeletedAt] is **after**
  /// the local [updatedAt]. If the local version is newer, the deletion is
  /// ignored (local edit wins). Either way, the task is marked  to
  /// prevent re-pushing it.
  Future<void> applyServerDeletion(String id, DateTime serverDeletedAt) async {
    final existing = await (select(tasks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing == null) {
      // Task not present locally — nothing to do.
      return;
    }

    if (serverDeletedAt.isAfter(existing.updatedAt)) {
      // Server deletion is newer → honor it.
      await (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          deletedAt: Value(serverDeletedAt),
          updatedAt: Value(serverDeletedAt),
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now().toUtc()),
        ),
      );
    } else {
      // Local version is newer → ignore server deletion; mark synced so
      // the next push will overwrite the server with the local data.
      await markSynced(id);
    }
  }

  /// Permanently remove tasks that have been soft-deleted AND synced.
  /// Call this periodically to reclaim storage.
  Future<int> purgeDeletedSyncedTasks() {
    return (delete(tasks)
          ..where(
            (t) =>
                t.deletedAt.isNotNull() &
                t.syncStatus.equals('synced'),
          ))
        .go();
  }
}
