import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/local/daos/task_dao.dart';
import '../data/repositories/task_repository_impl.dart';
import '../domain/repositories/task_repository.dart';

/// Singleton database instance — closed when the app exits.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provides the [TaskDao] backed by the singleton database.
final taskDaoProvider = Provider<TaskDao>(
  (ref) => ref.watch(databaseProvider).taskDao,
);

/// Provides the [TaskRepository] implementation.
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.watch(taskDaoProvider)),
);
