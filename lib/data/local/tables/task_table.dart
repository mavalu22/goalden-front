import 'package:drift/drift.dart';

@DataClassName('TaskEntry')
class Tasks extends Table {
  /// UUID primary key
  TextColumn get id => text()();

  TextColumn get title => text()();

  /// Stored as ISO-8601 date (UTC midnight)
  DateTimeColumn get date => dateTime()();

  TextColumn get note => text().nullable()();

  BoolColumn get done =>
      boolean().withDefault(const Constant(false))();

  /// 'none' | 'daily' | 'weekly' | 'custom_days'
  TextColumn get recurrence =>
      text().withDefault(const Constant('none'))();

  /// JSON-encoded list of weekday ints (1=Mon … 7=Sun).
  /// Only meaningful when recurrence == 'custom_days'.
  TextColumn get recurrenceDays => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  /// Last modification time — used for last-write-wins conflict resolution
  /// during sync. Defaults to the current timestamp at insert time.
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get completedAt => dateTime().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// If this is a generated instance of a recurring task, this holds the
  /// source task's id. Null for original (non-instance) tasks.
  TextColumn get sourceTaskId => text().nullable()();

  /// Optional reference to the Goal this task belongs to.
  TextColumn get goalId => text().nullable()();

  /// Optional start time in minutes from midnight (0–1439).
  IntColumn get startTimeMinutes => integer().nullable()();

  /// Optional end time in minutes from midnight (0–1439).
  IntColumn get endTimeMinutes => integer().nullable()();

  // ── Sync metadata ─────────────────────────────────────────────────────────

  /// When this task was last successfully pushed to or pulled from the cloud.
  /// Null means it has never been synced.
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// Dirty-state marker for incremental sync.
  /// Values: 'pending_create' | 'pending_update' | 'pending_delete' | 'synced'
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();

  /// Soft-delete timestamp. Non-null means the task has been logically deleted
  /// and should be hidden from the UI, but the row is kept until the deletion
  /// is propagated to the cloud.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
