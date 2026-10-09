import 'dart:async';

import '../sync_service.dart';

/// Debounced drain trigger for "after a local write". Call
/// `scheduleDrain()` from wherever local writes happen (or, more simply,
/// from one central point — see the provider in sync_providers.dart)
/// rather than calling SyncService.drain() directly after every write,
/// so a burst of writes (e.g. logging several mortality entries in a row)
/// collapses into one drain instead of one per write.
class LifecycleSyncTrigger {
  LifecycleSyncTrigger(
    this._syncService, {
    this.debounce = const Duration(seconds: 3),
  });

  final SyncService _syncService;
  final Duration debounce;
  Timer? _timer;

  void scheduleDrain() {
    _timer?.cancel();
    _timer = Timer(debounce, () {
      unawaited(_syncService.drain());
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
