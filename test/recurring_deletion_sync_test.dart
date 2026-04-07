// Regression tests for TASK-081: recurring task deletion sync behavior.
//
// Verifies that:
// 1. Deleting future recurring instances uses soft-delete so the deletions
//    are propagated to the cloud during the next push sync.
// 2. A soft-deleted instance is not recreated by the recurrence service
//    because recurringInstanceExists includes soft-deleted rows.
// 3. Soft-deleted recurring instances are not purged, so they act as
//    tombstones preventing recreation even after sync completes.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:goalden/data/local/database.dart';
import 'package:goalden/data/local/daos/task_dao.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

AppDatabase _openInMemory() =>
    AppDatabase(NativeDatabase.memory());

TasksCompanion _baseTask({
  required String id,
  required DateTime date,
  String recurrence = 'none',
  String? sourceTaskId,
}) {
  final now = DateTime.now().toUtc();
  return TasksCompanion(
    id: Value(id),
    title: const Value('Test Task'),
    date: Value(date),
    priority: const Value('normal'),
    done: const Value(false),
    recurrence: Value(recurrence),
    recurrenceDays: const Value(null),
    sortOrder: const Value(0),
    sourceTaskId: Value(sourceTaskId),
    createdAt: Value(now),
    updatedAt: Value(now),
    syncStatus: const Value('synced'),
  );
}

void main() {
  late AppDatabase db;
  late TaskDao dao;

  setUp(() {
    db = _openInMemory();
    dao = db.taskDao;
  });

  tearDown(() => db.close());

  // ── Bug 1: softDeleteFutureInstances propagates to sync ──────────────────

  test(
    'softDeleteFutureInstances marks instances pending_delete (not hard-deleted)',
    () async {
      final today = DateTime(2026, 4, 6);
      final tomorrow = DateTime(2026, 4, 7);

      // Source recurring task.
      await dao.insertTask(_baseTask(
        id: 'src-1',
        date: today,
        recurrence: 'daily',
      ));

      // Two already-synced instances.
      await dao.insertTask(_baseTask(
        id: 'inst-today',
        date: today,
        sourceTaskId: 'src-1',
      ));
      await dao.insertTask(_baseTask(
        id: 'inst-tomorrow',
        date: tomorrow,
        sourceTaskId: 'src-1',
      ));

      // Soft-delete future instances from today onward.
      await dao.softDeleteFutureInstances('src-1', today);

      // Both instances must still exist in the DB (soft-deleted, not hard-deleted).
      final pending = await dao.getPendingSyncTasks();
      final pendingIds = pending.map((t) => t.id).toSet();
      expect(pendingIds, containsAll({'inst-today', 'inst-tomorrow'}));

      // Both must have syncStatus='pending_delete' so they get pushed.
      for (final t in pending.where((t) => t.sourceTaskId == 'src-1')) {
        expect(t.syncStatus, 'pending_delete');
        expect(t.deletedAt, isNotNull);
      }
    },
  );

  // ── Bug 2: recurringInstanceExists includes soft-deleted rows ─────────────

  test(
    'recurringInstanceExists returns true for soft-deleted instance '
    'preventing recreation by recurrence service',
    () async {
      final day = DateTime(2026, 4, 7);

      await dao.insertTask(_baseTask(
        id: 'src-1',
        date: DateTime(2026, 4, 6),
        recurrence: 'daily',
      ));

      // Insert instance, then soft-delete it.
      await dao.insertTask(_baseTask(
        id: 'inst-1',
        date: day,
        sourceTaskId: 'src-1',
      ));
      await dao.softDeleteTask('inst-1');

      // Even though the instance is soft-deleted, existsCheck must return true.
      final exists = await dao.recurringInstanceExists('src-1', day);
      expect(exists, isTrue,
          reason:
              'Soft-deleted instance must block recreation by recurrence service');
    },
  );

  // ── Bug 3: purgeDeletedSyncedTasks keeps recurring instance tombstones ────

  test(
    'purgeDeletedSyncedTasks does not purge soft-deleted recurring instances',
    () async {
      final day = DateTime(2026, 4, 7);
      final now = DateTime.now().toUtc();

      // A non-recurring task that was soft-deleted and synced → should be purged.
      await dao.insertTask(_baseTask(id: 'regular-1', date: day));
      await (db.update(db.tasks)..where((t) => t.id.equals('regular-1'))).write(
        TasksCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value('synced'),
        ),
      );

      // A recurring instance that was soft-deleted and synced → must NOT be purged.
      await dao.insertTask(_baseTask(
        id: 'inst-1',
        date: day,
        sourceTaskId: 'src-1',
      ));
      await (db.update(db.tasks)..where((t) => t.id.equals('inst-1'))).write(
        TasksCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value('synced'),
        ),
      );

      await dao.purgeDeletedSyncedTasks();

      // Regular task must be gone.
      final regular = await (db.select(db.tasks)
            ..where((t) => t.id.equals('regular-1')))
          .getSingleOrNull();
      expect(regular, isNull,
          reason: 'Non-recurring deleted+synced tasks must be purged');

      // Recurring instance tombstone must survive.
      final instance = await (db.select(db.tasks)
            ..where((t) => t.id.equals('inst-1')))
          .getSingleOrNull();
      expect(instance, isNotNull,
          reason:
              'Recurring instance tombstones must not be purged — '
              'they prevent recreation by the recurrence service');
      expect(instance!.deletedAt, isNotNull);
    },
  );

  // ── End-to-end: delete-sync-noreappear ────────────────────────────────────

  test(
    'deleted recurring instance does not reappear after sync cycle',
    () async {
      final day = DateTime(2026, 4, 7);

      await dao.insertTask(_baseTask(
        id: 'src-1',
        date: DateTime(2026, 4, 6),
        recurrence: 'daily',
      ));
      await dao.insertTask(_baseTask(
        id: 'inst-1',
        date: day,
        sourceTaskId: 'src-1',
      ));

      // User deletes the instance.
      await dao.softDeleteTask('inst-1');

      // Simulate a sync cycle: mark synced, then purge.
      await dao.markSynced('inst-1');
      await dao.purgeDeletedSyncedTasks();

      // The tombstone must remain (not purged).
      final tombstone = await (db.select(db.tasks)
            ..where((t) => t.id.equals('inst-1')))
          .getSingleOrNull();
      expect(tombstone, isNotNull,
          reason: 'Tombstone must survive purge for recurring instances');

      // recurringInstanceExists must still return true — recurrence service
      // must not recreate the instance.
      final exists = await dao.recurringInstanceExists('src-1', day);
      expect(exists, isTrue,
          reason:
              'Instance must not reappear: tombstone blocks recurrence service');
    },
  );
}
