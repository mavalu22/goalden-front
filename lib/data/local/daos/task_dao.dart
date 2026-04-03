import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/task_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// All tasks for a specific calendar day (UTC).
  Future<List<TaskEntry>> getTasksForDate(DateTime date) {
    final dayStart = DateTime.utc(date.year, date.month, date.day);
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
    final dayStart = DateTime.utc(date.year, date.month, date.day);
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
    final dayStart = DateTime.utc(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(tasks)
          ..where(
            (t) => t.date.isBiggerOrEqualValue(dayStart) &
                t.date.isSmallerThanValue(dayEnd),
          ))
        .watch();
  }

  Future<void> insertTask(TasksCompanion entry) =>
      into(tasks).insert(entry);

  Future<bool> updateTask(TasksCompanion entry) =>
      update(tasks).replace(entry);

  Future<int> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
}
