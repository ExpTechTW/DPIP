/// Which optional sensors this device has, asked once per launch and held for
/// every surface that offers something only a sensor can do.
library;

import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/accelerometer.dart';
import 'package:flutter/foundation.dart';

/// A sensor a feature can need.
///
/// Adding one is a value here plus its probe in [DeviceSensors]'s default
/// map; anything that lists itself by sensor (an Experimental features
/// option's `requiredSensors`, for one) can then ask for it.
enum DeviceSensor {
  /// What the seismometer reads — `accelerometer.dart`.
  accelerometer,
}

/// Asks the platform whether one sensor is present.
typedef SensorProbe = Future<bool> Function();

/// The sensors this device is known to have.
///
/// **Unknown counts as absent.** Until [resolve] hears back, [has] is false
/// for every sensor, so whatever needs one can appear a moment late but is
/// never shown and then taken away. The answer is fixed for the life of the
/// process: a phone does not grow or lose an accelerometer while the app is
/// running, so it is asked once and never again.
///
/// Provided app-wide by `coreProviders`, which starts [resolve] as soon as the
/// tree is built so the answer is in long before anyone opens a page that
/// needs it.
class DeviceSensors extends ChangeNotifier {
  /// Probes the platform with [probes], one per sensor; tests pass their own.
  DeviceSensors({Map<DeviceSensor, SensorProbe>? probes})
    : _probes = probes ?? _platformProbes;

  /// A device whose answer is already in: exactly [present], nothing pending.
  @visibleForTesting
  DeviceSensors.known(Set<DeviceSensor> present)
    : _probes = const {},
      _present = Set.unmodifiable(present),
      _resolution = Future.value();

  static const Map<DeviceSensor, SensorProbe> _platformProbes = {
    DeviceSensor.accelerometer: accelerometerPresent,
  };

  final Map<DeviceSensor, SensorProbe> _probes;
  Set<DeviceSensor> _present = const {};
  Future<void>? _resolution;
  bool _disposed = false;

  /// Whether [sensor] is known to be on this device — false while it is still
  /// being asked about.
  bool has(DeviceSensor sensor) => _present.contains(sensor);

  /// The sensors known to be present. Unmodifiable, and the same instance
  /// until the answer changes, so a `select` on it rebuilds only then.
  Set<DeviceSensor> get present => _present;

  /// Asks every probe at once. Only the first call asks; later ones return
  /// its future. Notifies once, when the answers are in, if any sensor turned
  /// out to be present.
  Future<void> resolve() => _resolution ??= _resolve();

  Future<void> _resolve() async {
    final answers = await Future.wait([
      for (final MapEntry(key: sensor, value: probe) in _probes.entries)
        _ask(sensor, probe),
    ]);
    final present = {
      for (final (sensor, isPresent) in answers)
        if (isPresent) sensor,
    };
    Log.info(
      'Device sensors: '
      '${present.isEmpty ? 'none' : present.map((s) => s.name).join(', ')}',
    );
    if (_disposed || present.isEmpty) return;
    _present = Set.unmodifiable(present);
    notifyListeners();
  }

  /// One probe's answer. A probe that throws counts as absent, for the reason
  /// `accelerometerPresent` gives.
  static Future<(DeviceSensor, bool)> _ask(
    DeviceSensor sensor,
    SensorProbe probe,
  ) async {
    try {
      return (sensor, await probe());
    } catch (error) {
      Log.warning(
        'Sensor probe for ${sensor.name} failed; treating it as absent: '
        '$error',
      );
      return (sensor, false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
