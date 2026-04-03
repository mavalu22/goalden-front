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
    DateTime? completedAt,
  }) = _Task;
}
