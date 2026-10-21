import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'connectivity_status.dart';

/// Contract for monitoring network interface and internet reachability.
abstract class IConnectivityService {
  /// The latest resolved connectivity status.
  ConnectivityStatus get currentStatus;

  /// Stream of connectivity status transitions.
  Stream<ConnectivityStatus> get onStatusChange;

  /// Actively rechecks network interface and internet reachability.
  Future<ConnectivityStatus> checkConnectivity();

  /// Releases resources, timers, and stream subscriptions.
  void dispose();
}

/// Production implementation of [IConnectivityService] coordinating
/// [Connectivity] for OS interface events and [InternetConnection] for
/// verified external WAN reachability.
class ConnectivityService implements IConnectivityService {
  final Connectivity _connectivity;
  final InternetConnection _internetConnection;
  final Duration _reachabilityTimeout;

  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  ConnectivityStatus _currentStatus = ConnectivityStatus.checking;
  Future<ConnectivityStatus>? _inFlightCheck;
  bool _isDisposed = false;

  ConnectivityService({
    Connectivity? connectivity,
    InternetConnection? internetConnection,
    Duration reachabilityTimeout = const Duration(seconds: 4),
    bool autoInitialize = true,
  }) : _connectivity = connectivity ?? Connectivity(),
       _internetConnection = internetConnection ?? InternetConnection(),
       _reachabilityTimeout = reachabilityTimeout {
    if (autoInitialize) {
      _init();
    }
  }

  @override
  ConnectivityStatus get currentStatus => _currentStatus;

  @override
  Stream<ConnectivityStatus> get onStatusChange => _statusController.stream;

  void _init() {
    // 1. Initial connectivity resolution
    checkConnectivity();

    // 2. Listen to OS network interface transitions
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityResult,
      onError: (error, stackTrace) {
        debugPrint(
          '⚠️ [ConnectivityService] Connectivity stream error: $error',
        );
        _updateStatus(ConnectivityStatus.networkWithoutInternet);
      },
    );

    // 3. Listen to active internet status changes from checker
    _internetSubscription = _internetConnection.onStatusChange.listen(
      _handleInternetStatus,
      onError: (error, stackTrace) {
        debugPrint(
          '⚠️ [ConnectivityService] InternetStatus stream error: $error',
        );
      },
    );
  }

  void _handleConnectivityResult(List<ConnectivityResult> results) {
    if (_isDisposed) return;

    final hasNoInterface =
        results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);

    if (hasNoInterface) {
      _updateStatus(ConnectivityStatus.noNetwork);
    } else {
      // Interface appeared or changed (e.g. Wi-Fi <-> Mobile).
      // Probe external internet access immediately.
      checkConnectivity();
    }
  }

  void _handleInternetStatus(InternetStatus status) {
    if (_isDisposed) return;

    if (status == InternetStatus.connected) {
      _updateStatus(ConnectivityStatus.online);
    } else {
      // If internet disconnected, check if we still have a local interface
      _resolveDisconnectedState();
    }
  }

  Future<void> _resolveDisconnectedState() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasNoInterface =
          results.isEmpty ||
          (results.length == 1 && results.first == ConnectivityResult.none);

      if (hasNoInterface) {
        _updateStatus(ConnectivityStatus.noNetwork);
      } else {
        _updateStatus(ConnectivityStatus.networkWithoutInternet);
      }
    } catch (_) {
      _updateStatus(ConnectivityStatus.networkWithoutInternet);
    }
  }

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    if (_isDisposed) return _currentStatus;

    if (_inFlightCheck != null) {
      return _inFlightCheck!;
    }

    _inFlightCheck = _performConnectivityCheck();
    try {
      final result = await _inFlightCheck!;
      return result;
    } finally {
      _inFlightCheck = null;
    }
  }

  Future<ConnectivityStatus> _performConnectivityCheck() async {
    try {
      // Step 1: Check physical/system network interface
      final results = await _connectivity.checkConnectivity();
      final hasNoInterface =
          results.isEmpty ||
          (results.length == 1 && results.first == ConnectivityResult.none);

      if (hasNoInterface) {
        _updateStatus(ConnectivityStatus.noNetwork);
        return ConnectivityStatus.noNetwork;
      }

      // Step 2: Interface is present; verify actual external reachability
      final hasAccess = await _internetConnection.hasInternetAccess.timeout(
        _reachabilityTimeout,
        onTimeout: () => false,
      );

      final newStatus =
          hasAccess
              ? ConnectivityStatus.online
              : ConnectivityStatus.networkWithoutInternet;

      _updateStatus(newStatus);
      return newStatus;
    } catch (e) {
      debugPrint('⚠️ [ConnectivityService] Exception during probe: $e');
      final fallback = ConnectivityStatus.networkWithoutInternet;
      _updateStatus(fallback);
      return fallback;
    }
  }

  void _updateStatus(ConnectivityStatus newStatus) {
    if (_isDisposed) return;
    if (_currentStatus == newStatus) return;

    _currentStatus = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _internetSubscription?.cancel();
    _internetSubscription = null;
    _statusController.close();
  }
}
