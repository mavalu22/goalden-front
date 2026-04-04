import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/task_dao.dart';
import 'tables/task_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tasks], daos: [TaskDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

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

/// Opens (or creates) the per-user database file inside the app's private
/// support directory. Using [getApplicationSupportDirectory] ensures the file
/// lands in the OS-managed, sandboxed location on every platform:
///   Linux   — ~/.local/share/goalden/
///   macOS   — ~/Library/Application Support/bundle-id/
///   Windows — %APPDATA%/company/app/
///   iOS     — app/Library/Application Support/
///   Android — /data/data/package/files/
Future<QueryExecutor> openDatabase(String userId) async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'goalden_$userId.db'));
  return NativeDatabase.createInBackground(file);
}
