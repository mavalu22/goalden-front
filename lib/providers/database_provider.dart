import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/local/daos/task_dao.dart';
import '../data/repositories/task_repository_impl.dart';
import '../domain/repositories/task_repository.dart';
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
