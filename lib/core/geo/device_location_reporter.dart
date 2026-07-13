import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;

/// Reports the device location to the backend when it **moves a threshold
/// distance** — not when the user switches the Home region.
///
/// Driven by a distance-filtered position stream (in production
/// `Geolocator.getPositionStream(distanceFilter: …)`); each emission is a
/// meaningful move, so it just forwards to [onMoved] (the
/// `LocationApi.updateDeviceLocation` POST). Consecutive identical fixes are
/// skipped, and a report failure is logged, never thrown — a missed update
/// self-heals on the next move. The stream + reporter are injected so the
/// lifecycle is unit-testable without geolocator.
///
/// Foreground only; the app-closed case is the native background-location task.
class DeviceLocationReporter {
  DeviceLocationReporter({required this._positions, required this._onMoved});

  final Stream<GpsFix> _positions;
  final Future<void> Function(GpsFix fix) _onMoved;

  StreamSubscription<GpsFix>? _sub;
  GpsFix? _last;

  /// Begins reporting on each distance-triggered position (idempotent).
  void start() {
    _sub ??= _positions.listen(
      _handle,
      onError: (Object error, StackTrace stackTrace) {
        Log.handle(error, stackTrace, 'location stream');
      },
    );
  }

  Future<void> _handle(GpsFix fix) async {
    if (fix == _last) return; // records compare by value
    _last = fix;
    try {
      await _onMoved(fix);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'updateDeviceLocation');
    }
  }

  /// Stops reporting; safe to [start] again.
  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() => stop();
}
