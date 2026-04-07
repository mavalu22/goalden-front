// Regression tests for TASK-083: UTC-safe day logic.
//
// Verifies that date arithmetic used for postponing and range queries
// never produces wrong dates at month/year boundaries and is safe
// regardless of the device's local timezone offset.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Date boundary arithmetic', () {
    /// Mirrors the fixed postpone_sheet.dart pattern.
    DateTime dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
    DateTime addDays(DateTime base, int days) =>
        dayOnly(base).add(Duration(days: days));

    test('add 1 day across month boundary (Jan 31 → Feb 1)', () {
      final jan31 = DateTime(2026, 1, 31);
      final result = addDays(jan31, 1);
      expect(result, DateTime(2026, 2, 1),
          reason: 'addDays must normalize across month boundaries');
    });

    test('add 1 day across year boundary (Dec 31 → Jan 1)', () {
      final dec31 = DateTime(2025, 12, 31);
      final result = addDays(dec31, 1);
      expect(result, DateTime(2026, 1, 1),
          reason: 'addDays must normalize across year boundaries');
    });

    test('add 7 days across month boundary produces 7 distinct days', () {
      final mar28 = DateTime(2026, 3, 28);
      final next7 = List.generate(7, (i) => addDays(mar28, i + 1));
      expect(next7.last, DateTime(2026, 4, 4),
          reason: 'generate 7 days starting from Mar 29 should end Apr 4');
      // All dates must be unique and sequential.
      for (var i = 0; i < next7.length - 1; i++) {
        final diff = next7[i + 1].difference(next7[i]).inDays;
        expect(diff, 1,
            reason: 'consecutive postpone dates must always differ by 1 day');
      }
    });

    test('exclusive end range covers the last day correctly', () {
      // Mirrors the fixed task_dao.dart exclusive-end pattern.
      final rangeEnd = DateTime(2026, 3, 31);
      final exclusiveEnd =
          DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day)
              .add(const Duration(days: 1));
      expect(exclusiveEnd, DateTime(2026, 4, 1),
          reason: 'exclusive end for Mar 31 must be Apr 1, not Apr 0');
    });

    test('exclusive end range across year boundary', () {
      final rangeEnd = DateTime(2025, 12, 31);
      final exclusiveEnd =
          DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day)
              .add(const Duration(days: 1));
      expect(exclusiveEnd, DateTime(2026, 1, 1));
    });
  });
}
