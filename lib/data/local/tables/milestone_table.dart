import 'package:drift/drift.dart';

import 'goal_table.dart';

@DataClassName('MilestoneEntry')
class Milestones extends Table {
  TextColumn get id => text()();

  TextColumn get goalId =>
      text().references(Goals, #id)();

  TextColumn get userId => text()();

  TextColumn get title => text()();

  /// Target date for this milestone (stored as local midnight).
  DateTimeColumn get date => dateTime()();

  BoolColumn get done =>
      boolean().withDefault(const Constant(false))();

  /// Set when done is toggled to true.
  DateTimeColumn get completedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  // ── Sync metadata ─────────────────────────────────────────────────────────

  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// 'pending_create' | 'pending_update' | 'pending_delete' | 'synced'
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
