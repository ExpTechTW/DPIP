import 'package:flutter/services.dart';

/// A single device-heading sample.
class HeadingEvent {
  const HeadingEvent({required this.heading, this.accuracy});

  /// Heading in degrees clockwise from true north (0–360), or null if the
  /// platform cannot currently determine it.
  final double? heading;

  /// Reported heading accuracy in degrees (smaller is better), if available.
  final double? accuracy;
}

/// Native compass/heading stream backed by a platform [EventChannel], replacing
/// the `flutter_compass` package.
///
/// iOS emits CoreLocation heading updates; Android fuses the rotation-vector
/// sensor. The native side sends `{heading, accuracy}` maps.
abstract final class CompassService {
  static const EventChannel _channel = EventChannel('com.exptech.dpip/compass');

  static Stream<HeadingEvent>? _events;

  /// A broadcast stream of heading updates; the same instance is returned on
  /// repeated access.
  static Stream<HeadingEvent> get events {
    return _events ??= _channel.receiveBroadcastStream().map((dynamic event) {
      final map = (event as Map).cast<String, dynamic>();
      return HeadingEvent(
        heading: (map['heading'] as num?)?.toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble(),
      );
    });
  }
}
