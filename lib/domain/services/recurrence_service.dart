import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';

const _uuid = Uuid();

/// Generates recurring task instances for a given date.
///
/// For each source recurring task:
/// - **daily**: creates an instance for every day.
/// - **weekly**: creates an instance on the same weekday as the source task's date.
/// - **customDays**: creates an instance on each weekday in [recurrenceDays].
///
/// Instances are only generated if they don't already exist (idempotent).
/// Generation is NOT retroactive — only the requested [date] is processed.
class RecurrenceService {
  const RecurrenceService(this._repository);

  final TaskRepository _repository;

  Future<void> generateForDate(DateTime date) async {
    final today = DateTime(date.year, date.month, date.day);
    final sources = await _repository.getRecurringSourceTasks();

    for (final source in sources) {
      final sourceDate =
          DateTime(source.date.year, source.date.month, source.date.day);

      // Only generate for dates on or after the source task's date.
      if (today.isBefore(sourceDate)) continue;

      // The source itself already covers its own date — skip generation for it.
      if (today == sourceDate) continue;

      final shouldGenerate = switch (source.recurrence) {
        TaskRecurrence.none => false,
        TaskRecurrence.daily => true,
        TaskRecurrence.weekly =>
          today.weekday == source.date.weekday,
        TaskRecurrence.customDays =>
          source.recurrenceDays.contains(today.weekday),
      };

      if (!shouldGenerate) continue;

      final exists =
          await _repository.recurringInstanceExists(source.id, today);
      if (exists) continue;

      await _repository.createTask(
        Task(
          id: _uuid.v4(),
          title: source.title,
          date: today,
          priority: source.priority,
          note: source.note,
          recurrence: TaskRecurrence.none,
          recurrenceDays: const [],
          createdAt: DateTime.now(),
          sourceTaskId: source.id,
        ),
      );
    }
  }
}
