/// Connection state for the Meshtastic device
enum MeshtasticConnectionState {
  /// Not connected to any device
  disconnected,

  /// Currently attempting to connect
  connecting,

  /// Connected and receiving configuration
  configuring,

  /// Connected and ready for communication
  connected,

  /// Connection lost or error occurred
  error,
}

/// Represents the current connection state with additional metadata
class ConnectionStatus {
  final MeshtasticConnectionState state;
  final String? deviceAddress;
  final String? deviceName;
  final String? errorMessage;
  final DateTime timestamp;

  const ConnectionStatus({
    required this.state,
    this.deviceAddress,
    this.deviceName,
    this.errorMessage,
    required this.timestamp,
  });

  ConnectionStatus copyWith({
    MeshtasticConnectionState? state,
    String? deviceAddress,
    String? deviceName,
    String? errorMessage,
    DateTime? timestamp,
  }) {
    return ConnectionStatus(
      state: state ?? this.state,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      deviceName: deviceName ?? this.deviceName,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'ConnectionStatus(state: $state, deviceAddress: $deviceAddress, '
        'deviceName: $deviceName, errorMessage: $errorMessage, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionStatus &&
        other.state == state &&
        other.deviceAddress == deviceAddress &&
        other.deviceName == deviceName &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return state.hashCode ^
        deviceAddress.hashCode ^
        deviceName.hashCode ^
        errorMessage.hashCode;
  }
}
