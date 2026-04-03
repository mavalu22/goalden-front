import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/task.dart';
import '../../../providers/database_provider.dart';

const _uuid = Uuid();

/// Tracks the id of the currently expanded task tile (null = none).
final expandedTaskIdProvider = StateProvider<String?>((ref) => null);

/// Reactive stream of tasks for today.
final todayTasksProvider = StreamProvider<List<Task>>((ref) {
  final now = DateTime.now();
  return ref.watch(taskRepositoryProvider).watchTasksForDate(now);
});

/// Reactive stream of uncompleted tasks from previous days.
/// Also triggers cleanup of tasks older than 7 days on initialization.
final pendingTasksProvider = StreamProvider<List<Task>>((ref) {
  // One-shot cleanup on provider init
  ref.read(taskRepositoryProvider).deleteOldPendingTasks(days: 7);
  final now = DateTime.now();
  return ref.watch(taskRepositoryProvider).watchPendingTasksBefore(now);
});

/// Handles task mutations (create, update, delete).
final taskActionsProvider =
    AsyncNotifierProvider<TaskActionsNotifier, void>(TaskActionsNotifier.new);

class TaskActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createTask(String title, {DateTime? date}) async {
    if (title.trim().isEmpty) return;
    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      date: date ?? DateTime.utc(now.year, now.month, now.day),
      createdAt: now,
    );
    await ref.read(taskRepositoryProvider).createTask(task);
  }

  Future<void> toggleDone(Task task) async {
    final now = DateTime.now();
    final updated = task.copyWith(
      done: !task.done,
      completedAt: !task.done ? now : null,
    );
    await ref.read(taskRepositoryProvider).updateTask(updated);
  }

  Future<void> updateTask(Task task) async {
    await ref.read(taskRepositoryProvider).updateTask(task);
  }

  Future<void> deleteTask(String id) async {
    await ref.read(taskRepositoryProvider).deleteTask(id);
  }

  Future<void> reorderTasks(List<Task> reordered) async {
    await ref.read(taskRepositoryProvider).reorderTasks(reordered);
  }

  Future<void> rescheduleToToday(Task task) async {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    await ref
        .read(taskRepositoryProvider)
        .updateTask(task.copyWith(date: today));
  }
}
