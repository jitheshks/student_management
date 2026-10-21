/// Represents the application-wide internet connectivity status.
enum ConnectivityStatus {
  /// Actively probing network interfaces and external reachability.
  checking,

  /// Physical interface connected and external internet reachability confirmed.
  online,

  /// No physical or wireless network interface available (e.g. airplane mode, Wi-Fi & cellular disabled).
  noNetwork,

  /// Network interface active (e.g. connected to Wi-Fi/router), but internet/WAN reachability failed.
  networkWithoutInternet;

  /// Whether the device has confirmed, active internet access.
  bool get isOnline => this == ConnectivityStatus.online;

  /// Whether the device lacks functional internet access.
  bool get isOffline =>
      this == ConnectivityStatus.noNetwork ||
      this == ConnectivityStatus.networkWithoutInternet;

  /// Whether a connectivity check is currently in progress.
  bool get isChecking => this == ConnectivityStatus.checking;

  /// User-friendly status message for notifications or banners.
  String get message {
    switch (this) {
      case ConnectivityStatus.checking:
        return 'Checking connection...';
      case ConnectivityStatus.online:
        return 'Back online';
      case ConnectivityStatus.noNetwork:
        return 'No internet connection. Some features may be unavailable.';
      case ConnectivityStatus.networkWithoutInternet:
        return 'Connected to a network, but internet access is unavailable.';
    }
  }
}
