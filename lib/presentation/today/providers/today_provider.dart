import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/task.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/sync_provider.dart';

const _uuid = Uuid();

/// Reactive stream of tasks for today.
/// Also triggers recurrence generation for today on first load.
final todayTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final repo = await ref.watch(taskRepositoryProvider.future);
  final svc = await ref.watch(recurrenceServiceProvider.future);
  final now = DateTime.now();
  await svc.generateForDate(now);
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

  /// Triggers a background push sync after any task mutation.
  /// Errors are surfaced via [syncStatusProvider], not propagated.
  void _scheduleSync() {
    ref.read(syncActionsProvider.notifier).pushSync();
  }

  Future<void> createTask(
    String title, {
    DateTime? date,
    TaskPriority priority = TaskPriority.normal,
    String? note,
    TaskRecurrence recurrence = TaskRecurrence.none,
    List<int> recurrenceDays = const [],
    int? startTimeMinutes,
    int? endTimeMinutes,
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
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
    );
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.createTask(task);
    _scheduleSync();
  }

  Future<void> toggleDone(Task task) async {
    final now = DateTime.now();
    final updated = task.copyWith(
      done: !task.done,
      completedAt: !task.done ? now : null,
    );
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.updateTask(updated);
    _scheduleSync();
  }

  Future<void> updateTask(Task task) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.updateTask(task);
    _scheduleSync();
  }

  Future<void> deleteTask(String id, {bool isRecurringSource = false}) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    if (isRecurringSource) {
      // Remove all future instances before deleting the source.
      final today = DateTime.now();
      final todayLocal = DateTime(today.year, today.month, today.day);
      await repo.deleteFutureInstances(id, todayLocal);
    }
    await repo.deleteTask(id);
    _scheduleSync();
  }

  Future<void> reorderTasks(List<Task> reordered) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.reorderTasks(reordered);
    _scheduleSync();
  }

  Future<void> rescheduleToToday(Task task) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.updateTask(task.copyWith(date: today));
    _scheduleSync();
  }
}
