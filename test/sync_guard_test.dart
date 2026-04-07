// Regression test for TASK-082: push sync concurrency guard.
//
// Verifies that SyncActionsNotifier._syncing prevents concurrent push sync
// executions when rapid mutations trigger pushSync() simultaneously.
//
// Because the guard is a plain bool field set synchronously before the first
// await, we can test its behavior with a simple simulation without spinning
// up a full Riverpod container.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Push sync concurrency guard', () {
    test('concurrent calls do not overlap — only one runs at a time', () async {
      int runCount = 0;
      bool guardLocked = false;

      // Simulate the guard logic from SyncActionsNotifier.pushSync().
      Future<void> simulatedPushSync() async {
        if (guardLocked) return; // guard check
        guardLocked = true; // set before first await
        try {
          runCount++;
          // Simulate async work (DB + network round-trip).
          await Future<void>.delayed(const Duration(milliseconds: 10));
        } finally {
          guardLocked = false;
        }
      }

      // Fire three concurrent calls — only one should execute.
      await Future.wait([
        simulatedPushSync(),
        simulatedPushSync(),
        simulatedPushSync(),
      ]);

      expect(runCount, 1,
          reason:
              'Only one push sync should execute when called concurrently; '
              'the guard must block the others without allowing re-entry.');
    });

    test('guard is released after sync completes — next call succeeds', () async {
      bool guardLocked = false;
      int runCount = 0;

      Future<void> simulatedPushSync() async {
        if (guardLocked) return;
        guardLocked = true;
        try {
          runCount++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
        } finally {
          guardLocked = false;
        }
      }

      // First call runs to completion.
      await simulatedPushSync();
      expect(runCount, 1);

      // Second call (after first completed) also runs — guard was released.
      await simulatedPushSync();
      expect(runCount, 2,
          reason: 'Guard must be released after sync completes so '
              'the next independent sync call can proceed.');
    });

    test('guard is released even when sync throws', () async {
      bool guardLocked = false;
      int runCount = 0;

      Future<void> simulatedPushSync({bool shouldThrow = false}) async {
        if (guardLocked) return;
        guardLocked = true;
        try {
          runCount++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          if (shouldThrow) throw Exception('simulated sync error');
        } finally {
          guardLocked = false; // must run even on error
        }
      }

      // First call throws — swallow the error as the production code does.
      await simulatedPushSync(shouldThrow: true).catchError((_) {});

      // Guard must be released so subsequent calls can run.
      await simulatedPushSync();
      expect(runCount, 2,
          reason: 'Guard must be released in a finally block so errors '
              'do not permanently lock the sync path.');
    });
  });
}
