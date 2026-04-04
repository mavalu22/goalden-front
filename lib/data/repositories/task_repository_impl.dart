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
  Future<void> createTask(Task task) =>
      _dao.insertTask(_toCompanion(task));

  @override
  Future<void> updateTask(Task task) =>
      _dao.updateTask(_toCompanion(task));

  @override
  Future<void> deleteTask(String id) async => _dao.deleteTask(id);

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
  Future<void> deleteOldPendingTasks({int days = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffLocal = DateTime(cutoff.year, cutoff.month, cutoff.day);
    await _dao.deleteOldPendingTasks(cutoffLocal);
  }

  @override
  Stream<List<Task>> watchTasksForDateRange(DateTime start, DateTime end) {
    return _dao.watchTasksForDateRange(start, end).map(
          (entries) => entries.map(_fromEntry).toList(),
        );
  }

  // ─── Mapping ─────────────────────────────────────────────────────────────

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
      completedAt: e.completedAt,
      sortOrder: e.sortOrder,
    );
  }

  TasksCompanion _toCompanion(Task t) {
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
      completedAt: Value(t.completedAt),
      sortOrder: Value(t.sortOrder),
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
