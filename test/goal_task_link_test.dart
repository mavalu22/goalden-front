// Regression tests for TASK-109: task ↔ goal link create / update / unlink.
//
// Verifies that:
// 1. A task created with a goal_id stores and retrieves the link correctly.
// 2. Updating a task's goal_id changes the link.
// 3. unlinkTasksFromGoal sets goal_id to null for all tasks referencing that goal.
// 4. Soft-deleted tasks are not affected by unlinkTasksFromGoal.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:goalden/data/local/database.dart';
import 'package:goalden/data/local/daos/task_dao.dart';

AppDatabase _openInMemory() => AppDatabase(NativeDatabase.memory());

TasksCompanion _task({
  required String id,
  String? goalId,
}) {
  final now = DateTime.now().toUtc();
  return TasksCompanion(
    id: Value(id),
    title: const Value('Test Task'),
    date: Value(DateTime(2026, 5, 1)),
    priority: const Value('normal'),
    done: const Value(false),
    recurrence: const Value('none'),
    sortOrder: const Value(0),
    goalId: Value(goalId),
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

  test('task created with goal_id stores the link', () async {
    await dao.insertTask(_task(id: 'task-1', goalId: 'goal-A'));

    final tasks = await dao.getTasksForDate(DateTime(2026, 5, 1));
    expect(tasks.length, 1);
    expect(tasks.first.goalId, 'goal-A');
  });

  test('task created without goal_id has null goalId', () async {
    await dao.insertTask(_task(id: 'task-2'));

    final tasks = await dao.getTasksForDate(DateTime(2026, 5, 1));
    expect(tasks.first.goalId, isNull);
  });

  test('updating task goal_id changes the link', () async {
    final now = DateTime.now().toUtc();
    await dao.insertTask(_task(id: 'task-3', goalId: 'goal-A'));

    // Update to link to goal-B
    await dao.updateTask(
      _task(id: 'task-3', goalId: 'goal-B').copyWith(
        updatedAt: Value(now.add(const Duration(seconds: 1))),
      ),
    );

    final tasks = await dao.getTasksForDate(DateTime(2026, 5, 1));
    expect(tasks.first.goalId, 'goal-B');
  });

  test('updating task goal_id to null unlinks the task', () async {
    final now = DateTime.now().toUtc();
    await dao.insertTask(_task(id: 'task-4', goalId: 'goal-A'));

    await dao.updateTask(
      _task(id: 'task-4').copyWith(
        goalId: const Value(null),
        updatedAt: Value(now.add(const Duration(seconds: 1))),
      ),
    );

    final tasks = await dao.getTasksForDate(DateTime(2026, 5, 1));
    expect(tasks.first.goalId, isNull);
  });

  test('unlinkTasksFromGoal clears goal_id for all tasks referencing that goal',
      () async {
    await dao.insertTask(_task(id: 'task-5', goalId: 'goal-X'));
    await dao.insertTask(_task(id: 'task-6', goalId: 'goal-X'));
    await dao.insertTask(_task(id: 'task-7', goalId: 'goal-Y'));

    await dao.unlinkTasksFromGoal('goal-X');

    final all = await dao.getTasksForDate(DateTime(2026, 5, 1));
    final byId = {for (final t in all) t.id: t};

    expect(byId['task-5']!.goalId, isNull);
    expect(byId['task-6']!.goalId, isNull);
    expect(byId['task-7']!.goalId, 'goal-Y'); // unrelated goal unchanged
  });

  test('unlinkTasksFromGoal does not affect soft-deleted tasks', () async {
    await dao.insertTask(_task(id: 'task-8', goalId: 'goal-X'));
    await dao.softDeleteTask('task-8');

    await dao.unlinkTasksFromGoal('goal-X');

    // The soft-deleted row should retain its goal_id (it's hidden from UI anyway)
    final allIncludingDeleted = await (db.select(db.tasks)
          ..where((t) => t.id.equals('task-8')))
        .get();
    expect(allIncludingDeleted.first.goalId, 'goal-X');
  });
}
