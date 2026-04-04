import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/task_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// All tasks for a specific calendar day (UTC).
  Future<List<TaskEntry>> getTasksForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(tasks)
          ..where(
            (t) => t.date.isBiggerOrEqualValue(dayStart) &
                t.date.isSmallerThanValue(dayEnd),
          ))
        .get();
  }

  /// All uncompleted tasks with a date strictly before [date].
  Future<List<TaskEntry>> getPendingTasksBefore(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return (select(tasks)
          ..where(
            (t) =>
                t.date.isSmallerThanValue(dayStart) &
                t.done.equals(false),
          ))
        .get();
  }

  /// Watch tasks for today — reactive stream.
  Stream<List<TaskEntry>> watchTasksForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(tasks)
          ..where(
            (t) => t.date.isBiggerOrEqualValue(dayStart) &
                t.date.isSmallerThanValue(dayEnd),
          ))
        .watch();
  }

  /// Watch uncompleted tasks with a date strictly before [date] — reactive stream.
  Stream<List<TaskEntry>> watchPendingTasksBefore(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return (select(tasks)
          ..where(
            (t) =>
                t.date.isSmallerThanValue(dayStart) &
                t.done.equals(false),
          ))
        .watch();
  }

  Future<void> insertTask(TasksCompanion entry) =>
      into(tasks).insert(entry);

  Future<bool> updateTask(TasksCompanion entry) =>
      update(tasks).replace(entry);

  Future<int> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  /// Update sortOrder for a specific task by id.
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

  /// Delete uncompleted tasks with a date before [cutoff].
  Future<int> deleteOldPendingTasks(DateTime cutoff) =>
      (delete(tasks)
            ..where(
              (t) =>
                  t.date.isSmallerThanValue(cutoff) &
                  t.done.equals(false),
            ))
          .go();

  /// All tasks within a date range [start, end] inclusive — reactive stream.
  Stream<List<TaskEntry>> watchTasksForDateRange(DateTime start, DateTime end) {
    final startLocal = DateTime(start.year, start.month, start.day);
    final endLocal = DateTime(end.year, end.month, end.day + 1); // exclusive end
    return (select(tasks)
          ..where(
            (t) => t.date.isBiggerOrEqualValue(startLocal) &
                t.date.isSmallerThanValue(endLocal),
          ))
        .watch();
  }
}
