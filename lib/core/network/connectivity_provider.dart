import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';
import 'connectivity_status.dart';

/// Provides the singleton [IConnectivityService] application-wide.
final connectivityServiceProvider = Provider<IConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Exposes the real-time [ConnectivityStatus] stream.
final connectivityStreamProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChange;
});

/// StateNotifier that manages and exposes the synchronous current [ConnectivityStatus].
class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  final IConnectivityService _service;
  StreamSubscription<ConnectivityStatus>? _subscription;

  ConnectivityNotifier(this._service) : super(_service.currentStatus) {
    _subscription = _service.onStatusChange.listen((newStatus) {
      if (mounted) {
        state = newStatus;
      }
    });
  }

  /// Explicitly triggers a network reachability probe.
  Future<void> recheck() async {
    if (!mounted) return;
    state = ConnectivityStatus.checking;
    final status = await _service.checkConnectivity();
    if (mounted) {
      state = status;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Primary Riverpod provider for application-wide connectivity state.
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
      final service = ref.watch(connectivityServiceProvider);
      return ConnectivityNotifier(service);
    });
