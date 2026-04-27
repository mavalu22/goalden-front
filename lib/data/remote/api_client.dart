import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin HTTP client for the Goalden Go backend.
///
/// Every request automatically attaches the current Supabase access token
/// as a Bearer header. If no session is active the call will return a 401
/// from the server, which is surfaced as a [SyncApiException].
class ApiClient {
  ApiClient({required String baseUrl, required SupabaseClient supabase})
      : _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        _supabase = supabase;

  final String _baseUrl;
  final SupabaseClient _supabase;

  // ── Auth helpers ──────────────────────────────────────────────────────────

  Map<String, String> get _headers {
    final token = _supabase.auth.currentSession?.accessToken ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path) =>
      Uri.parse('$_baseUrl${path.startsWith('/') ? path.substring(1) : path}');

  // ── Endpoints ─────────────────────────────────────────────────────────────

  /// Registers / refreshes the authenticated user record on the server.
  /// Call this once after every successful login.
  Future<void> syncUser({required String email}) async {
    final response = await http
        .post(
          _uri('auth/sync-user'),
          headers: _headers,
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 15));

    _assertOk(response, 'sync-user');
  }

  /// Bidirectional sync endpoint.
  ///
  /// [tasks] — tasks created/modified locally since [lastSyncAt].
  /// [deletedIds] — IDs of tasks soft-deleted locally since [lastSyncAt].
  /// [lastSyncAt] — timestamp of the last successful sync (pass DateTime(0) for first sync).
  ///
  /// Returns a map with:
  ///   - "tasks": list of tasks updated on the server since lastSyncAt
  ///   - "deleted_tasks": list of {id, deleted_at} for server-side deletions (LWW)
  Future<Map<String, dynamic>> syncTasks({
    required List<Map<String, dynamic>> tasks,
    required List<String> deletedIds,
    required DateTime lastSyncAt,
  }) async {
    final response = await http
        .post(
          _uri('tasks/sync'),
          headers: _headers,
          body: jsonEncode({
            'tasks': tasks,
            'deleted_ids': deletedIds,
            'last_sync_at': lastSyncAt.toUtc().toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 30));

    _assertOk(response, 'POST /tasks/sync');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Returns all non-deleted tasks for the authenticated user.
  /// Use for the initial pull after login on a new device.
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final response = await http
        .get(_uri('tasks'), headers: _headers)
        .timeout(const Duration(seconds: 30));

    _assertOk(response, 'GET /tasks');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final tasks = body['tasks'] as List<dynamic>? ?? [];
    return tasks.cast<Map<String, dynamic>>();
  }

  /// Returns all non-deleted goals for the authenticated user.
  /// Use for the initial pull after login on a new device.
  Future<List<Map<String, dynamic>>> getAllGoals() async {
    final response = await http
        .get(_uri('goals'), headers: _headers)
        .timeout(const Duration(seconds: 30));

    _assertOk(response, 'GET /goals');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final goals = body['goals'] as List<dynamic>? ?? [];
    return goals.cast<Map<String, dynamic>>();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _assertOk(http.Response response, String endpoint) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncApiException(
        endpoint: endpoint,
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}

/// Thrown when the backend returns a non-2xx response.
class SyncApiException implements Exception {
  const SyncApiException({
    required this.endpoint,
    required this.statusCode,
    required this.body,
  });

  final String endpoint;
  final int statusCode;
  final String body;

  @override
  String toString() =>
      'SyncApiException[$endpoint]: HTTP $statusCode — $body';
}
