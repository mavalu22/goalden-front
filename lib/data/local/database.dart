import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/goal_dao.dart';
import 'daos/milestone_dao.dart';
import 'daos/task_dao.dart';
import 'tables/goal_table.dart';
import 'tables/milestone_table.dart';
import 'tables/task_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tasks, Goals, Milestones], daos: [TaskDao, GoalDao, MilestoneDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.sortOrder);
          }
          if (from < 3) {
            await m.addColumn(tasks, tasks.sourceTaskId);
          }
          if (from < 4) {
            await m.addColumn(tasks, tasks.startTimeMinutes);
            await m.addColumn(tasks, tasks.endTimeMinutes);
          }
          if (from < 5) {
            // updated_at uses currentDateAndTime default which is non-constant;
            // ALTER TABLE ADD COLUMN requires a constant default in SQLite < 3.37.
            // Use epoch (0) as placeholder then backfill from created_at.
            await customStatement(
              'ALTER TABLE tasks ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
            );
            await customStatement(
              'UPDATE tasks SET updated_at = created_at',
            );
            await m.addColumn(tasks, tasks.lastSyncedAt);
            await m.addColumn(tasks, tasks.syncStatus);
            await m.addColumn(tasks, tasks.deletedAt);
          }
          if (from < 6) {
            await m.createTable(goals);
          }
          if (from < 7) {
            await m.addColumn(tasks, tasks.goalId);
          }
          if (from < 8) {
            await m.createTable(milestones);
          }
          // from < 9: priority column removed from Dart schema; SQLite column
          // stays in place and is silently ignored by Drift.
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
