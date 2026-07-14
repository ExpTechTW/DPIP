/// App-wide location health monitor — the single place a mid-session GPS or
/// permission change becomes a clear status (for a banner) and a recovery,
/// instead of an uncaught exception or a silently-dead reporter.
library;

import 'dart:async';

import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:flutter/widgets.dart';

/// Tracks the combined [LocationStatus] and recovers reporting when the OS
/// location toggle or permission changes while the app runs.
///
/// It watches `Geolocator.getServiceStatusStream()` (via [LocationService]) and
/// every foreground resume. When location transitions from unusable back to
/// usable (services re-enabled, or permission granted in Settings), it restarts
/// the position reporter — whose stream geolocator kills on a services-off
/// toggle and never resumes — and re-resolves the current township. The
/// [status] drives a "fix it" banner.
class LocationMonitor extends ChangeNotifier with WidgetsBindingObserver {
  LocationMonitor({
    required this._location,
    required this._reporter,
    required this._regions,
  });

  final LocationService _location;
  final DeviceLocationReporter _reporter;
  final RegionStore _regions;

  StreamSubscription<bool>? _serviceSub;
  // Optimistic seed so a bad status flashes only after it's actually confirmed.
  LocationStatus _status = LocationStatus.ready;
  bool _started = false;
  bool _seeded = false;

  /// The current combined location status.
  LocationStatus get status => _status;

  /// Whether the current status warrants a user-facing banner (can't locate).
  bool get needsAttention =>
      _status == LocationStatus.serviceOff ||
      _status == LocationStatus.denied ||
      _status == LocationStatus.deniedForever;

  /// Begins monitoring (idempotent): seeds the status, watches the OS location
  /// toggle, and re-checks on every foreground resume.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _serviceSub = _location.serviceEnabledStream().listen(
      (_) => _refresh(),
      onError: (_, _) {},
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final previous = _status;
    final status = await _location.status();
    _status = status;
    // Recover only on an unusable → usable transition (services back / granted),
    // not on every resume — avoids re-subscribing the position stream needlessly.
    if (_seeded && _usable(status) && !_usable(previous)) {
      _reporter.restart();
      _regions.setCurrentCode((await _location.currentTown())?.code);
    }
    _seeded = true;
    if (status != previous) notifyListeners();
  }

  static bool _usable(LocationStatus s) =>
      s == LocationStatus.ready || s == LocationStatus.whileInUseOnly;

  /// Sends the user to system settings to fix the permission / services toggle.
  Future<void> openSettings() => _location.openSettings();

  @override
  void dispose() {
    _serviceSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
