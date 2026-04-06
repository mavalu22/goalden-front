import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../data/local/sync_meta_storage.dart';
import '../data/remote/api_client.dart';
import '../data/services/sync_service.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';
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

/// Provides the [SyncMetaStorage] for the currently authenticated user.
final syncMetaStorageProvider = Provider<SyncMetaStorage>((ref) {
  final userId = ref.watch(authUserProvider).valueOrNull?.id ?? 'anonymous';
  return SyncMetaStorage(userId);
});

/// Provides the [SyncService] once the local database is ready.
final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final dao = await ref.watch(taskDaoProvider.future);
  final apiClient = ref.watch(apiClientProvider);
  final metaStorage = ref.watch(syncMetaStorageProvider);
  return SyncService(
    apiClient: apiClient,
    dao: dao,
    metaStorage: metaStorage,
  );
});

// ── Initial pull ──────────────────────────────────────────────────────────────

/// Triggers the initial cloud→local pull once the user is authenticated
/// and the per-user database is open.
///
/// This provider rebuilds automatically whenever the authenticated user
/// changes (i.e. on login and logout). On logout the user is null and
/// nothing is done.
final initialSyncProvider = FutureProvider<void>((ref) async {
  final authUser = await ref.watch(authUserProvider.future);
  if (authUser == null) {
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

// ── Push sync ─────────────────────────────────────────────────────────────────

/// Notifier that exposes [pushSync] to any part of the app.
///
/// Call `ref.read(syncActionsProvider.notifier).pushSync()` after any task
/// mutation to flush local dirty state to the cloud.
///
/// Also automatically retries when the device comes back online.
final syncActionsProvider =
    AsyncNotifierProvider<SyncActionsNotifier, void>(SyncActionsNotifier.new);

class SyncActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Watch connectivity; trigger a push sync when we come back online.
    ref.listen(isOnlineProvider, (previous, next) {
      final wasOffline = previous?.valueOrNull == false;
      final isNowOnline = next.valueOrNull == true;
      if (wasOffline && isNowOnline) {
        pushSync();
      }
    });
  }

  /// Pushes all locally-dirty tasks to the cloud.
  ///
  /// Safe to call concurrently — if a sync is already in progress the new
  /// call is debounced by checking the current [syncStatusProvider] state.
  Future<void> pushSync() async {
    // Avoid overlapping sync runs.
    if (ref.read(syncStatusProvider) == SyncStatus.syncing) return;

    final syncService = await ref.read(syncServiceProvider.future);

    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    final result = await syncService.pushSync();

    ref.read(syncStatusProvider.notifier).state = switch (result) {
      SyncResult.success => SyncStatus.synced,
      SyncResult.offline => SyncStatus.offline,
      SyncResult.error => SyncStatus.error,
    };
  }
}
