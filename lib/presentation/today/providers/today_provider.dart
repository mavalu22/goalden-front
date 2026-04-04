import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/task.dart';
import '../../../providers/database_provider.dart';

const _uuid = Uuid();

/// Tracks the id of the currently expanded task tile (null = none).
final expandedTaskIdProvider = StateProvider<String?>((ref) => null);

/// Reactive stream of tasks for today.
final todayTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final repo = await ref.watch(taskRepositoryProvider.future);
  final now = DateTime.now();
  yield* repo.watchTasksForDate(now);
});

/// Reactive stream of uncompleted tasks from previous days.
/// Also triggers cleanup of tasks older than 7 days on initialization.
final pendingTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final repo = await ref.watch(taskRepositoryProvider.future);
  repo.deleteOldPendingTasks(days: 7);
  final now = DateTime.now();
  yield* repo.watchPendingTasksBefore(now);
});

/// Handles task mutations (create, update, delete).
final taskActionsProvider =
    AsyncNotifierProvider<TaskActionsNotifier, void>(TaskActionsNotifier.new);

class TaskActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createTask(
    String title, {
    DateTime? date,
    TaskPriority priority = TaskPriority.normal,
    String? note,
    TaskRecurrence recurrence = TaskRecurrence.none,
    List<int> recurrenceDays = const [],
  }) async {
    if (title.trim().isEmpty) return;
    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      date: date ?? DateTime(now.year, now.month, now.day),
      priority: priority,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      recurrence: recurrence,
      recurrenceDays: recurrenceDays,
      createdAt: now,
    );
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.createTask(task);
  }

  Future<void> toggleDone(Task task) async {
    final now = DateTime.now();
    final updated = task.copyWith(
      done: !task.done,
      completedAt: !task.done ? now : null,
    );
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.updateTask(updated);
  }

  Future<void> updateTask(Task task) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.updateTask(task);
  }

  Future<void> deleteTask(String id) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.deleteTask(id);
  }

  Future<void> reorderTasks(List<Task> reordered) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.reorderTasks(reordered);
  }

  Future<void> rescheduleToToday(Task task) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.updateTask(task.copyWith(date: today));
  }
}
