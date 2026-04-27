import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../local/daos/task_dao.dart';
import '../local/database.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._dao);

  final TaskDao _dao;

  @override
  Stream<List<Task>> watchTasksForDate(DateTime date) =>
      _dao.watchTasksForDate(date).map(
        (entries) => entries.map(_fromEntry).toList(),
      );

  @override
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final entries = await _dao.getTasksForDate(date);
    return entries.map(_fromEntry).toList();
  }

  @override
  Future<List<Task>> getPendingTasksBefore(DateTime date) async {
    final entries = await _dao.getPendingTasksBefore(date);
    return entries.map(_fromEntry).toList();
  }

  @override
  Future<void> createTask(Task task) {
    final now = DateTime.now().toUtc();
    return _dao.insertTask(
      _toCompanion(task).copyWith(
        updatedAt: Value(now),
        syncStatus: const Value('pending_create'),
      ),
    );
  }

  @override
  Future<void> updateTask(Task task) {
    final now = DateTime.now().toUtc();
    return _dao.updateTask(
      _toCompanion(task).copyWith(
        updatedAt: Value(now),
        syncStatus: const Value('pending_update'),
      ),
    );
  }

  @override
  Future<void> deleteTask(String id) => _dao.softDeleteTask(id);

  @override
  Stream<List<Task>> watchPendingTasksBefore(DateTime date) =>
      _dao.watchPendingTasksBefore(date).map(
        (entries) => entries.map(_fromEntry).toList(),
      );

  @override
  Future<void> reorderTasks(List<Task> reorderedTasks) async {
    final updates = [
      for (var i = 0; i < reorderedTasks.length; i++)
        (id: reorderedTasks[i].id, order: i),
    ];
    await _dao.reorderTasksBatch(updates);
  }

  @override
  Future<List<Task>> getRecurringSourceTasks() async {
    final entries = await _dao.getRecurringSourceTasks();
    return entries.map(_fromEntry).toList();
  }

  @override
  Future<bool> recurringInstanceExists(String sourceTaskId, DateTime date) =>
      _dao.recurringInstanceExists(sourceTaskId, date);

  @override
  Future<void> deleteFutureInstances(
      String sourceTaskId, DateTime fromDate) async {
    await _dao.softDeleteFutureInstances(sourceTaskId, fromDate);
  }

  @override
  Future<void> unlinkTasksFromGoal(String goalId) =>
      _dao.unlinkTasksFromGoal(goalId);

  @override
  Future<void> healInstanceGoalIds(String sourceTaskId, String goalId) =>
      _dao.healInstanceGoalIds(sourceTaskId, goalId);

  @override
  Stream<List<Task>> watchTasksForGoal(String goalId) =>
      _dao.watchTasksForGoal(goalId).map(
            (entries) => entries.map(_fromEntry).toList(),
          );

  @override
  Future<void> deleteOldPendingTasks({int days = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffLocal = DateTime(cutoff.year, cutoff.month, cutoff.day);
    await _dao.softDeleteOldPendingTasks(cutoffLocal);
  }

  @override
  Stream<List<Task>> watchTasksForDateRange(DateTime start, DateTime end) {
    return _dao.watchTasksForDateRange(start, end).map(
          (entries) => entries.map(_fromEntry).toList(),
        );
  }

  // ─── Mapping ──────────────────────────────────────────────────────────────

  Task _fromEntry(TaskEntry e) {
    return Task(
      id: e.id,
      title: e.title,
      date: e.date,
      priority: e.priority == 'high' ? TaskPriority.high : TaskPriority.normal,
      note: e.note,
      done: e.done,
      recurrence: _parseRecurrence(e.recurrence),
      recurrenceDays: e.recurrenceDays != null
          ? List<int>.from(jsonDecode(e.recurrenceDays!) as List)
          : [],
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      completedAt: e.completedAt,
      sortOrder: e.sortOrder,
      sourceTaskId: e.sourceTaskId,
      startTimeMinutes: e.startTimeMinutes,
      endTimeMinutes: e.endTimeMinutes,
      goalId: e.goalId,
    );
  }

  TasksCompanion _toCompanion(Task t) {
    final effectiveUpdatedAt = t.updatedAt ?? t.createdAt;
    return TasksCompanion(
      id: Value(t.id),
      title: Value(t.title),
      date: Value(t.date),
      priority: Value(t.priority == TaskPriority.high ? 'high' : 'normal'),
      note: Value(t.note),
      done: Value(t.done),
      recurrence: Value(_recurrenceToString(t.recurrence)),
      recurrenceDays: t.recurrenceDays.isEmpty
          ? const Value(null)
          : Value(jsonEncode(t.recurrenceDays)),
      createdAt: Value(t.createdAt),
      updatedAt: Value(effectiveUpdatedAt),
      completedAt: Value(t.completedAt),
      sortOrder: Value(t.sortOrder),
      sourceTaskId: Value(t.sourceTaskId),
      startTimeMinutes: Value(t.startTimeMinutes),
      endTimeMinutes: Value(t.endTimeMinutes),
      goalId: Value(t.goalId),
    );
  }

  TaskRecurrence _parseRecurrence(String value) {
    return switch (value) {
      'daily' => TaskRecurrence.daily,
      'weekly' => TaskRecurrence.weekly,
      'custom_days' => TaskRecurrence.customDays,
      _ => TaskRecurrence.none,
    };
  }

  String _recurrenceToString(TaskRecurrence r) {
    return switch (r) {
      TaskRecurrence.daily => 'daily',
      TaskRecurrence.weekly => 'weekly',
      TaskRecurrence.customDays => 'custom_days',
      TaskRecurrence.none => 'none',
    };
  }
}
