import 'package:drift/drift.dart';

@DataClassName('TaskEntry')
class Tasks extends Table {
  /// UUID primary key
  TextColumn get id => text()();

  TextColumn get title => text()();

  /// Stored as ISO-8601 date (UTC midnight)
  DateTimeColumn get date => dateTime()();

  /// 'normal' | 'high'
  TextColumn get priority =>
      text().withDefault(const Constant('normal'))();

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

  DateTimeColumn get completedAt => dateTime().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
