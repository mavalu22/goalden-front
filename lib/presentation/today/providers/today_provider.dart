import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/task.dart';
import '../../../providers/database_provider.dart';

const _uuid = Uuid();

/// Reactive stream of tasks for today.
final todayTasksProvider = StreamProvider<List<Task>>((ref) {
  final now = DateTime.now();
  return ref.watch(taskRepositoryProvider).watchTasksForDate(now);
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
}
