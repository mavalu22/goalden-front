import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';

enum TaskPriority { normal, high }

enum TaskRecurrence { none, daily, weekly, customDays }

@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    required DateTime date,
    @Default(TaskPriority.normal) TaskPriority priority,
    String? note,
    @Default(false) bool done,
    @Default(TaskRecurrence.none) TaskRecurrence recurrence,
    @Default([]) List<int> recurrenceDays,
    required DateTime createdAt,
    /// Last modification time. Null for tasks created before sync was introduced.
    /// The sync layer treats null as equivalent to [createdAt].
    DateTime? updatedAt,
    DateTime? completedAt,
    @Default(0) int sortOrder,
    /// Non-null when this task is a generated instance of a recurring source task.
    String? sourceTaskId,
    /// Optional start time stored as minutes from midnight (0–1439).
    int? startTimeMinutes,
    /// Optional end time stored as minutes from midnight (0–1439).
    int? endTimeMinutes,
  }) = _Task;
}
