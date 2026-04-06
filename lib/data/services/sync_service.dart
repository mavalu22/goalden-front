import 'dart:io';

import 'package:drift/drift.dart';

import '../local/daos/task_dao.dart';
import '../local/database.dart';
import '../remote/api_client.dart';

/// Status reported by [SyncService] after a sync attempt.
enum SyncResult { success, offline, error }

/// Handles bi-directional synchronisation between the local SQLite database
/// and the Goalden backend.
///
/// For TASK-076 this service exposes [initialPull] — the one-time pull that
/// fires after login to hydrate the local store from the cloud.
/// Push sync (TASK-077) and periodic background sync (TASK-079) build on top
/// of this foundation.
class SyncService {
  SyncService({required ApiClient apiClient, required TaskDao dao})
      : _client = apiClient,
        _dao = dao;

  final ApiClient _client;
  final TaskDao _dao;

  // ── Initial pull ──────────────────────────────────────────────────────────

  /// Pulls all of the user's tasks from the cloud and merges them into the
  /// local database (last-write-wins on `updated_at`).
  ///
  /// Safe to call on every login — it will not overwrite newer local changes.
  /// Returns [SyncResult.offline] if no network connection is available, and
  /// [SyncResult.error] for any other failure. Never throws.
  Future<SyncResult> initialPull({
    required String userEmail,
  }) async {
    try {
      // 1. Register / refresh the user record on the server.
      await _client.syncUser(email: userEmail);

      // 2. Pull all non-deleted cloud tasks.
      final rawTasks = await _client.getAllTasks();

      // 3. Upsert each task — last-write-wins enforced in upsertFromCloud.
      for (final raw in rawTasks) {
        final companion = _rawToCompanion(raw);
        await _dao.upsertFromCloud(companion);
      }

      return SyncResult.success;
    } on SocketException {
      return SyncResult.offline;
    } on HttpException {
      return SyncResult.offline;
    } on SyncApiException {
      return SyncResult.error;
    } catch (_) {
      return SyncResult.error;
    }
  }

  // ── Conversion ────────────────────────────────────────────────────────────

  /// Converts a raw JSON task map from the API into a [TasksCompanion]
  /// suitable for insertion into the local Drift database.
  TasksCompanion _rawToCompanion(Map<String, dynamic> raw) {
    // Required fields
    final id = raw['id'] as String;
    final title = raw['title'] as String? ?? '';
    final dateStr = raw['date'] as String? ?? '';
    final date = dateStr.isNotEmpty
        ? DateTime.parse(dateStr)
        : DateTime.now();

    // Optional timestamps
    final createdAt = _parseDateTime(raw['created_at']) ?? DateTime.now();
    final updatedAt = _parseDateTime(raw['updated_at']) ?? createdAt;
    final completedAt = _parseDateTime(raw['completed_at']);
    final deletedAt = _parseDateTime(raw['deleted_at']);

    // Scalars
    final priority = raw['priority'] as String? ?? 'normal';
    final note = raw['note'] as String?;
    final done = raw['done'] as bool? ?? false;
    final recurrence = raw['recurrence'] as String? ?? 'none';
    final recurrenceDays = raw['recurrence_days'] as String?;
    final sortOrder = raw['sort_order'] as int? ?? 0;
    final sourceTaskId = raw['source_task_id'] as String?;
    final startTimeMinutes = raw['start_time_minutes'] as int?;
    final endTimeMinutes = raw['end_time_minutes'] as int?;

    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      date: Value(date),
      priority: Value(priority),
      note: Value(note),
      done: Value(done),
      recurrence: Value(recurrence),
      recurrenceDays: Value(recurrenceDays),
      sortOrder: Value(sortOrder),
      sourceTaskId: Value(sourceTaskId),
      startTimeMinutes: Value(startTimeMinutes),
      endTimeMinutes: Value(endTimeMinutes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: Value(completedAt),
      deletedAt: Value(deletedAt),
      syncStatus: const Value('synced'),
      lastSyncedAt: Value(DateTime.now().toUtc()),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return null;
    }
  }
}
