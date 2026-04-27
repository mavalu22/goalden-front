import 'dart:io';

import 'package:drift/drift.dart';

import '../local/daos/goal_dao.dart';
import '../local/daos/task_dao.dart';
import '../local/database.dart';
import '../local/sync_meta_storage.dart';
import '../remote/api_client.dart';

/// Status reported by [SyncService] after a sync attempt.
enum SyncResult { success, offline, error }

/// Handles bi-directional synchronisation between the local SQLite database
/// and the Goalden backend.
///
/// The sync protocol:
///  1. [initialPull] — fires once after login to hydrate the local store.
///  2. [pushSync] — sends pending local changes to the cloud, applies server
///     changes back to local. Called after every task mutation and on reconnect.
class SyncService {
  SyncService({
    required ApiClient apiClient,
    required TaskDao dao,
    required GoalDao goalDao,
    required SyncMetaStorage metaStorage,
  })  : _client = apiClient,
        _dao = dao,
        _goalDao = goalDao,
        _meta = metaStorage;

  final ApiClient _client;
  final TaskDao _dao;
  final GoalDao _goalDao;
  final SyncMetaStorage _meta;

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

      // 2. Pull all non-deleted cloud tasks and goals in parallel.
      final results = await Future.wait([
        _client.getAllTasks(),
        _client.getAllGoals(),
      ]);
      final rawTasks = results[0];
      final rawGoals = results[1];

      // 3. Upsert each task and goal — last-write-wins enforced in upsertFromCloud.
      for (final raw in rawTasks) {
        await _dao.upsertFromCloud(_rawToCompanion(raw));
      }
      for (final raw in rawGoals) {
        await _goalDao.upsertFromCloud(_rawGoalToCompanion(raw));
      }

      // 4. Record sync time.
      await _meta.setLastSyncAt(DateTime.now().toUtc());
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

  // ── Push sync ─────────────────────────────────────────────────────────────

  /// Pushes all locally-dirty tasks to the cloud and applies any server
  /// changes that occurred since the last sync.
  ///
  /// - `pending_create` / `pending_update` tasks are sent as upserts.
  /// - `pending_delete` tasks contribute their IDs to `deleted_ids`.
  /// - Server response tasks are merged in (last-write-wins).
  /// - Server deleted IDs are removed from the local store.
  /// - Successfully pushed tasks are marked `synced`.
  ///
  /// Never throws — returns [SyncResult] to communicate outcome.
  Future<SyncResult> pushSync() async {
    try {
      final pending = await _dao.getPendingSyncTasks();
      if (pending.isEmpty) return SyncResult.success;

      final now = DateTime.now().toUtc();
      final lastSyncAt = await _meta.getLastSyncAt();

      // Separate dirty mutations from soft-deletes.
      final toUpsert = <TaskEntry>[];
      final deletedIds = <String>[];

      for (final entry in pending) {
        if (entry.syncStatus == 'pending_delete') {
          deletedIds.add(entry.id);
        } else {
          toUpsert.add(entry);
        }
      }

      // Build the wire representation of each task to upsert.
      final taskPayloads = toUpsert.map(_entryToWireMap).toList();

      // Call the bidirectional sync endpoint.
      final response = await _client.syncTasks(
        tasks: taskPayloads,
        deletedIds: deletedIds,
        lastSyncAt: lastSyncAt,
      );

      // Apply server-side updates (tasks updated on other devices).
      final serverTasks =
          (response['tasks'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      for (final raw in serverTasks) {
        await _dao.upsertFromCloud(_rawToCompanion(raw));
      }

      // Apply LWW deletion from other devices (server returns deleted_at timestamp).
      final serverDeletedTasks =
          (response['deleted_tasks'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      for (final d in serverDeletedTasks) {
        final id = d['id'] as String;
        final deletedAt = _parseDateTime(d['deleted_at']) ?? DateTime.now().toUtc();
        await _dao.applyServerDeletion(id, deletedAt);
      }

      // Mark all successfully pushed tasks as synced, then purge deleted rows.
      for (final entry in pending) {
        await _dao.markSynced(entry.id);
      }
      await _dao.purgeDeletedSyncedTasks();

      await _meta.setLastSyncAt(now);
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

  /// Converts a [TaskEntry] from the local DB into the wire map format
  /// expected by the backend's sync endpoint.
  Map<String, dynamic> _entryToWireMap(TaskEntry e) {
    return {
      'id': e.id,
      'user_id': '', // server derives user_id from the JWT; omit or blank
      'title': e.title,
      'date': _fmtDate(e.date),
      'priority': e.priority,
      'note': e.note,
      'done': e.done,
      'recurrence': e.recurrence,
      'recurrence_days': e.recurrenceDays,
      'sort_order': e.sortOrder,
      'source_task_id': e.sourceTaskId,
      'start_time_minutes': e.startTimeMinutes,
      'end_time_minutes': e.endTimeMinutes,
      'goal_id': e.goalId,
      'created_at': e.createdAt.toUtc().toIso8601String(),
      'updated_at': e.updatedAt.toUtc().toIso8601String(),
      'completed_at': e.completedAt?.toUtc().toIso8601String(),
      'deleted_at': e.deletedAt?.toUtc().toIso8601String(),
    };
  }

  /// Converts a raw JSON task map from the API into a [TasksCompanion]
  /// suitable for insertion into the local Drift database.
  TasksCompanion _rawToCompanion(Map<String, dynamic> raw) {
    final id = raw['id'] as String;
    final title = raw['title'] as String? ?? '';
    final dateStr = raw['date'] as String? ?? '';
    final date = dateStr.isNotEmpty ? DateTime.parse(dateStr) : DateTime.now();

    final createdAt = _parseDateTime(raw['created_at']) ?? DateTime.now();
    final updatedAt = _parseDateTime(raw['updated_at']) ?? createdAt;
    final completedAt = _parseDateTime(raw['completed_at']);
    final deletedAt = _parseDateTime(raw['deleted_at']);

    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      date: Value(date),
      priority: Value(raw['priority'] as String? ?? 'normal'),
      note: Value(raw['note'] as String?),
      done: Value(raw['done'] as bool? ?? false),
      recurrence: Value(raw['recurrence'] as String? ?? 'none'),
      recurrenceDays: Value(raw['recurrence_days'] as String?),
      sortOrder: Value(raw['sort_order'] as int? ?? 0),
      sourceTaskId: Value(raw['source_task_id'] as String?),
      startTimeMinutes: Value(raw['start_time_minutes'] as int?),
      endTimeMinutes: Value(raw['end_time_minutes'] as int?),
      goalId: Value(raw['goal_id'] as String?),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: Value(completedAt),
      deletedAt: Value(deletedAt),
      syncStatus: const Value('synced'),
      lastSyncedAt: Value(DateTime.now().toUtc()),
    );
  }

  /// Formats a calendar date as YYYY-MM-DD for the wire format.
  /// [dt] must be a date-only value (local midnight from the task's date field).
  /// Do NOT pass a UTC-shifted timestamp — use the raw date field directly.
  String _fmtDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  /// Converts a raw JSON goal map from the API into a [GoalsCompanion].
  GoalsCompanion _rawGoalToCompanion(Map<String, dynamic> raw) {
    final id = raw['id'] as String;
    final createdAt = _parseDateTime(raw['created_at']) ?? DateTime.now().toUtc();
    final updatedAt = _parseDateTime(raw['updated_at']) ?? createdAt;
    final deadlineStr = raw['deadline'] as String?;
    final deadline = deadlineStr != null && deadlineStr.isNotEmpty
        ? DateTime.parse(deadlineStr)
        : null;

    return GoalsCompanion(
      id: Value(id),
      userId: Value(raw['user_id'] as String? ?? ''),
      title: Value(raw['title'] as String? ?? ''),
      description: Value(raw['description'] as String?),
      color: Value(raw['color'] as String? ?? ''),
      status: Value(raw['status'] as String? ?? 'active'),
      deadline: Value(deadline),
      starred: Value(raw['starred'] as bool? ?? true),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: Value(_parseDateTime(raw['archived_at'])),
      deletedAt: Value(_parseDateTime(raw['deleted_at'])),
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
