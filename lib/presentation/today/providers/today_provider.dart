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
final pendingTasksProvider = StreamProvider<List<Task>>((ref) async* {
  // Ensure one-time overdue cleanup has run before streaming pending tasks.
  await ref.watch(overdueCleanupProvider.future);
  final repo = await ref.watch(taskRepositoryProvider.future);
  final now = DateTime.now();
  yield* repo.watchPendingTasksBefore(now);
});

/// Completion data for the last 7 days (index 0 = oldest, 6 = today).
final todayStreakProvider =
    StreamProvider<List<({int done, int total})>>((ref) async* {
  final repo = await ref.watch(taskRepositoryProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 6));
  await for (final tasks in repo.watchTasksForDateRange(start, today)) {
    final result = <({int done, int total})>[];
    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final dayTasks = tasks.where((t) =>
          t.date.year == day.year &&
          t.date.month == day.month &&
          t.date.day == day.day).toList();
      result.add((
        done: dayTasks.where((t) => t.done).length,
        total: dayTasks.length,
      ));
    }
    yield result;
  }
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

  /// Returns true if every day in [days] is a valid ISO weekday (1–7).
  bool _validRecurrenceDays(List<int> days) =>
      days.every((d) => d >= 1 && d <= 7);

  Future<void> createTask(
    String title, {
    DateTime? date,
    String? note,
    TaskRecurrence recurrence = TaskRecurrence.none,
    List<int> recurrenceDays = const [],
    int? startTimeMinutes,
    int? endTimeMinutes,
    String? goalId,
  }) async {
    if (title.trim().isEmpty || title.trim().length > 500) return;
    if (!_validRecurrenceDays(recurrenceDays)) return;
    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      date: date ?? DateTime(now.year, now.month, now.day),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      recurrence: recurrence,
      recurrenceDays: recurrenceDays,
      createdAt: now,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      goalId: goalId,
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
    if (task.title.trim().isEmpty || task.title.trim().length > 500) return;
    if (!_validRecurrenceDays(task.recurrenceDays)) return;
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
