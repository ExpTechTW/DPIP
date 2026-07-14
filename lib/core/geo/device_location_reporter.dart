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
/// skipped, and a report failure is logged, never thrown.
///
/// The positions come from a **factory** (`Stream<GpsFix> Function()`), not a
/// single stream instance, because geolocator's position stream *errors and
/// finishes* when location services are turned off mid-session and does not
/// resume when they return. On a stream error/done the subscription is dropped
/// so [restart] (driven by `LocationMonitor` when services come back) can create
/// a fresh one — otherwise foreground reporting would stay dead until relaunch.
///
/// Foreground only; the app-closed case is the native background-location task.
class DeviceLocationReporter {
  DeviceLocationReporter({required this._positions, required this._onMoved});

  final Stream<GpsFix> Function() _positions;
  final Future<void> Function(GpsFix fix) _onMoved;

  StreamSubscription<GpsFix>? _sub;
  GpsFix? _last;
  bool _running = false;

  /// Begins reporting on each distance-triggered position (idempotent).
  void start() {
    _running = true;
    _subscribe();
  }

  void _subscribe() {
    if (_sub != null) return;
    _sub = _positions().listen(
      _handle,
      // A services-off toggle errors the stream; keeping the error here means it
      // never rides up as an uncaught async error, and dropping the subscription
      // lets [restart] re-create it when services return.
      onError: (Object error, StackTrace stackTrace) {
        Log.handle(error, stackTrace, 'location stream');
        _sub = null;
      },
      onDone: () => _sub = null,
      cancelOnError: true,
    );
  }

  /// Re-subscribes with a fresh stream if running (e.g. after location services
  /// were toggled off then on). A no-op when stopped.
  void restart() {
    if (!_running) return;
    _sub?.cancel();
    _sub = null;
    _subscribe();
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
    _running = false;
    _sub?.cancel();
    _sub = null;
  }

  void dispose() => stop();
}
