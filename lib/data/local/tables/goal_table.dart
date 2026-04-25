import 'package:drift/drift.dart';

@DataClassName('GoalEntry')
class Goals extends Table {
  /// UUID primary key
  TextColumn get id => text()();

  /// Authenticated user who owns this goal
  TextColumn get userId => text()();

  TextColumn get title => text()();

  TextColumn get description => text().nullable()();

  /// Hex color string from the goal color palette (e.g. '#E57373')
  TextColumn get color => text()();

  /// 'active' | 'archived'
  TextColumn get status =>
      text().withDefault(const Constant('active'))();

  /// Optional deadline date (UTC midnight)
  DateTimeColumn get deadline => dateTime().nullable()();

  BoolColumn get starred =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  /// Last modification time — used for last-write-wins conflict resolution
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Set when the goal is archived
  DateTimeColumn get archivedAt => dateTime().nullable()();

  // ── Sync metadata ─────────────────────────────────────────────────────────

  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// 'pending_create' | 'pending_update' | 'pending_delete' | 'synced'
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
