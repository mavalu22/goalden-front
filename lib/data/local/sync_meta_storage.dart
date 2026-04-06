import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persists per-user sync metadata (currently just `last_sync_at`) in a small
/// JSON file stored alongside the SQLite database.
///
/// Using a dedicated file (rather than a DB table) keeps sync bookkeeping
/// independent of the task schema and avoids additional migrations.
class SyncMetaStorage {
  SyncMetaStorage(this._userId);

  final String _userId;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'goalden_sync_meta_$_userId.json'));
  }

  /// Returns the timestamp of the last successful sync, or the zero value
  /// (`DateTime(0)`) for a first-time sync.
  Future<DateTime> getLastSyncAt() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return DateTime(0);
      final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final raw = data['last_sync_at'] as String?;
      if (raw == null) return DateTime(0);
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime(0);
    }
  }

  /// Persists [timestamp] as the new `last_sync_at`.
  Future<void> setLastSyncAt(DateTime timestamp) async {
    final f = await _file();
    await f.writeAsString(
      jsonEncode({'last_sync_at': timestamp.toUtc().toIso8601String()}),
    );
  }
}
