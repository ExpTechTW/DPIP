/// Base exception for all Meshtastic-related errors
abstract class MeshtasticException implements Exception {
  final String message;
  final dynamic cause;

  const MeshtasticException(this.message, [this.cause]);

  @override
  String toString() =>
      'MeshtasticException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when Bluetooth operations fail
class BluetoothException extends MeshtasticException {
  const BluetoothException(super.message, [super.cause]);

  @override
  String toString() =>
      'BluetoothException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when connection to device fails or is lost
class ConnectionException extends MeshtasticException {
  const ConnectionException(super.message, [super.cause]);

  @override
  String toString() =>
      'ConnectionException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when protobuf parsing fails
class ProtocolException extends MeshtasticException {
  const ProtocolException(super.message, [super.cause]);

  @override
  String toString() =>
      'ProtocolException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when device configuration is invalid
class ConfigurationException extends MeshtasticException {
  const ConfigurationException(super.message, [super.cause]);

  @override
  String toString() =>
      'ConfigurationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when permissions are not granted
class PermissionException extends MeshtasticException {
  const PermissionException(super.message, [super.cause]);

  @override
  String toString() =>
      'PermissionException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when operation times out
class TimeoutException extends MeshtasticException {
  const TimeoutException(super.message, [super.cause]);

  @override
  String toString() =>
      'TimeoutException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
