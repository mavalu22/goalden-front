import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/task_dao.dart';
import 'tables/task_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tasks], daos: [TaskDao])
class AppDatabase extends _$AppDatabase {
  /// [userId] is used to name the SQLite file so every account gets its own
  /// isolated store. Pass `'anonymous'` (or any stable fallback) when no user
  /// is signed in — in practice the app never writes tasks in that state.
  AppDatabase([String userId = 'anonymous'])
      : super(_openConnection(userId));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.sortOrder);
          }
        },
      );
}

QueryExecutor _openConnection([String userId = 'anonymous']) {
  return driftDatabase(
    name: 'goalden_$userId',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
