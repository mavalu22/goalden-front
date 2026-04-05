import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits `true` when the device has any network connection, `false` when offline.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  // Emit current state immediately.
  final initial = await connectivity.checkConnectivity();
  yield _isConnected(initial);
  // Then stream changes.
  await for (final results in connectivity.onConnectivityChanged) {
    yield _isConnected(results);
  }
});

bool _isConnected(List<ConnectivityResult> results) =>
    results.isNotEmpty && results.first != ConnectivityResult.none;
