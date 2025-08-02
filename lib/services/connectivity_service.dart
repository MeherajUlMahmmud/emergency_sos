import 'dart:io';
import 'dart:async';

enum ConnectivityStatus {
  connected,
  disconnected,
  unknown,
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Stream controller for connectivity changes
  final StreamController<ConnectivityStatus> _connectivityController =
      StreamController<ConnectivityStatus>.broadcast();

  // Timer for periodic connectivity checks
  Timer? _connectivityTimer;

  // Current connectivity status
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;

  // Configuration
  static const Duration _checkInterval = Duration(seconds: 10);
  static const String _pingHost = 'google.com';
  static const int _pingPort = 80;
  static const Duration _pingTimeout = Duration(seconds: 5);

  // Initialize the service
  Future<void> initialize() async {
    // Perform initial connectivity check
    await _checkConnectivity();

    // Start periodic connectivity checks
    _startPeriodicChecks();
  }

  // Start periodic connectivity checks
  void _startPeriodicChecks() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(_checkInterval, (timer) {
      _checkConnectivity();
    });
  }

  // Stop periodic connectivity checks
  void _stopPeriodicChecks() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
  }

  // Check connectivity by pinging google.com
  Future<void> _checkConnectivity() async {
    final newStatus = await _pingGoogle();

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _connectivityController.add(newStatus);
    }
  }

  // Ping google.com to check internet connectivity
  Future<ConnectivityStatus> _pingGoogle() async {
    try {
      final socket =
          await Socket.connect(_pingHost, _pingPort, timeout: _pingTimeout);
      await socket.close();
      return ConnectivityStatus.connected;
    } catch (e) {
      return ConnectivityStatus.disconnected;
    }
  }

  // Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    final status = await _pingGoogle();
    return status == ConnectivityStatus.connected;
  }

  // Stream of connectivity changes
  Stream<ConnectivityStatus> get connectivityStream {
    return _connectivityController.stream;
  }

  // Get current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  // Get current connectivity status as Future (for backward compatibility)
  Future<ConnectivityStatus> getConnectivityStatus() async {
    return _currentStatus;
  }

  // Manual connectivity check
  Future<void> checkConnectivity() async {
    await _checkConnectivity();
  }

  // Dispose resources
  void dispose() {
    _stopPeriodicChecks();
    _connectivityController.close();
  }

  // Convert ConnectivityStatus to ConnectivityResult for backward compatibility
  ConnectivityResult _statusToResult(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.connected:
        return ConnectivityResult.wifi; // Assume wifi for connected state
      case ConnectivityStatus.disconnected:
        return ConnectivityResult.none;
      case ConnectivityStatus.unknown:
        return ConnectivityResult.none;
    }
  }

  // Get connectivity result stream for backward compatibility
  Stream<ConnectivityResult> get connectivityResultStream {
    return connectivityStream.map(_statusToResult);
  }
}

// Backward compatibility class to mimic connectivity_plus
class ConnectivityResult {
  static const ConnectivityResult none = ConnectivityResult._('none');
  static const ConnectivityResult wifi = ConnectivityResult._('wifi');
  static const ConnectivityResult mobile = ConnectivityResult._('mobile');
  static const ConnectivityResult ethernet = ConnectivityResult._('ethernet');
  static const ConnectivityResult bluetooth = ConnectivityResult._('bluetooth');
  static const ConnectivityResult vpn = ConnectivityResult._('vpn');
  static const ConnectivityResult other = ConnectivityResult._('other');

  final String _value;
  const ConnectivityResult._(this._value);

  @override
  String toString() => _value;

  @override
  bool operator ==(Object other) {
    return other is ConnectivityResult && other._value == _value;
  }

  @override
  int get hashCode => _value.hashCode;
}
