import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/local/daos/task_dao.dart';
import '../data/repositories/task_repository_impl.dart';
import '../domain/repositories/task_repository.dart';
import 'auth_provider.dart';

/// Derives a stable, file-safe identifier from the signed-in user.
/// Returns `'anonymous'` when no user is authenticated (app startup /
/// logged-out state — tasks are never written in that state).
final _currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(authUserProvider).valueOrNull?.id ?? 'anonymous';
});

/// Opens a per-user SQLite database keyed on [_currentUserIdProvider].
/// When the authenticated user changes (login, logout, or account switch)
/// Riverpod automatically closes the old database and opens a fresh one
/// for the new user — giving each account a fully isolated local store.
final databaseProvider = Provider<AppDatabase>((ref) {
  final userId = ref.watch(_currentUserIdProvider);
  final db = AppDatabase(userId);
  ref.onDispose(db.close);
  return db;
});

/// Provides the [TaskDao] backed by the per-user database.
final taskDaoProvider = Provider<TaskDao>(
  (ref) => ref.watch(databaseProvider).taskDao,
);

/// Provides the [TaskRepository] implementation.
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.watch(taskDaoProvider)),
);
