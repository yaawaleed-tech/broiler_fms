import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../sync_service.dart';

/// Listens for the device regaining network connectivity and triggers a
/// queue drain. Does not drain on losing connectivity, obviously — only
/// on transitions into a connected state.
class ConnectivitySyncTrigger {
  ConnectivitySyncTrigger(this._syncService, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final SyncService _syncService;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void start() {
    // Idempotent: starting twice would listen twice and drain twice.
    _subscription ??= _connectivity.onConnectivityChanged.listen((result) {
      final isConnected = !result.contains(ConnectivityResult.none);
      if (isConnected) {
        unawaited(_syncService.drain());
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
