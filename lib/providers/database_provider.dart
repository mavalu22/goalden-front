import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/local/daos/goal_dao.dart';
import '../data/local/daos/milestone_dao.dart';
import '../data/local/daos/task_dao.dart';
import '../data/repositories/goal_repository_impl.dart';
import '../data/repositories/milestone_repository_impl.dart';
import '../data/repositories/task_repository_impl.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/repositories/milestone_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/services/recurrence_service.dart';
import 'auth_provider.dart';

/// Derives a stable, file-safe identifier from the signed-in user.
/// Returns `'anonymous'` when no user is authenticated — tasks are never
/// written in that state (the app shows the login screen instead).
final _currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(authUserProvider).valueOrNull?.id ?? 'anonymous';
});

/// Asynchronously opens the per-user SQLite database in the app's private
/// support directory. Rebuilds automatically when the authenticated user
/// changes, closing the old database (via [ref.onDispose]) and opening a
/// fresh one for the new user.
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final userId = ref.watch(_currentUserIdProvider);
  final executor = await openDatabase(userId);
  final db = AppDatabase(executor);
  ref.onDispose(db.close);
  return db;
});

/// Provides the [TaskDao] — waits for the database to be ready.
final taskDaoProvider = FutureProvider<TaskDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.taskDao;
});

/// Provides the [TaskRepository] implementation.
final taskRepositoryProvider = FutureProvider<TaskRepository>((ref) async {
  final dao = await ref.watch(taskDaoProvider.future);
  return TaskRepositoryImpl(dao);
});

/// Provides the [RecurrenceService] once the repository is ready.
final recurrenceServiceProvider =
    FutureProvider<RecurrenceService>((ref) async {
  final repo = await ref.watch(taskRepositoryProvider.future);
  return RecurrenceService(repo);
});

/// Runs overdue-task cleanup exactly once per session, as soon as the
/// repository is available. Errors are caught and logged so cleanup
/// failures never affect task loading.
final overdueCleanupProvider = FutureProvider<void>((ref) async {
  final repo = await ref.watch(taskRepositoryProvider.future);
  try {
    await repo.deleteOldPendingTasks(days: 7);
  } catch (e) {
    // Cleanup is best-effort — a failure is non-fatal.
    debugPrint('[overdueCleanup] Failed to clean up old pending tasks: $e');
  }
});

/// Provides the [GoalDao] — waits for the database to be ready.
final goalDaoProvider = FutureProvider<GoalDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.goalDao;
});

/// Provides the [GoalRepository] implementation.
final goalRepositoryProvider = FutureProvider<GoalRepository>((ref) async {
  final dao = await ref.watch(goalDaoProvider.future);
  return GoalRepositoryImpl(dao);
});

/// Provides the [MilestoneDao] — waits for the database to be ready.
final milestoneDaoProvider = FutureProvider<MilestoneDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.milestoneDao;
});

/// Provides the [MilestoneRepository] implementation.
final milestoneRepositoryProvider =
    FutureProvider<MilestoneRepository>((ref) async {
  final dao = await ref.watch(milestoneDaoProvider.future);
  return MilestoneRepositoryImpl(dao);
});
