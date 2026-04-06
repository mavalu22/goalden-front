import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../data/remote/api_client.dart';
import '../data/services/sync_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

// ── Sync status ───────────────────────────────────────────────────────────────

/// Current synchronisation state exposed to the UI.
enum SyncStatus {
  /// No sync has been attempted yet in this session.
  idle,

  /// A sync is currently in progress.
  syncing,

  /// The last sync completed successfully.
  synced,

  /// The device is offline; local changes are queued.
  offline,

  /// The last sync failed due to a server or parsing error.
  error,
}

final syncStatusProvider = StateProvider<SyncStatus>(
  (ref) => SyncStatus.idle,
);

// ── Infrastructure ────────────────────────────────────────────────────────────

/// Provides the [ApiClient] pointed at the configured backend base URL.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: Env.apiBaseUrl,
    supabase: Supabase.instance.client,
  );
});

/// Provides the [SyncService] once the local database is ready.
final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final dao = await ref.watch(taskDaoProvider.future);
  final apiClient = ref.watch(apiClientProvider);
  return SyncService(apiClient: apiClient, dao: dao);
});

// ── Initial pull ──────────────────────────────────────────────────────────────

/// Triggers the initial cloud→local pull once the user is authenticated
/// and the per-user database is open.
///
/// This provider rebuilds automatically whenever the authenticated user
/// changes (i.e. on login and logout). On logout the user is null and
/// nothing is done.
///
/// The result is surfaced via [syncStatusProvider] so the UI can show
/// a subtle "Synced" / "Offline" / "Sync error" indicator.
final initialSyncProvider = FutureProvider<void>((ref) async {
  final authUser = await ref.watch(authUserProvider.future);
  if (authUser == null) {
    // Not logged in — nothing to sync.
    ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
    return;
  }

  // Wait for the per-user database to be open before syncing.
  await ref.watch(databaseProvider.future);

  final syncService = await ref.watch(syncServiceProvider.future);

  ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

  final result = await syncService.initialPull(
    userEmail: authUser.email ?? '',
  );

  ref.read(syncStatusProvider.notifier).state = switch (result) {
    SyncResult.success => SyncStatus.synced,
    SyncResult.offline => SyncStatus.offline,
    SyncResult.error => SyncStatus.error,
  };
});
