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
  StreamSubscription<GpsFix>? _fixSub;
  // Optimistic seed so a bad status flashes only after it's actually confirmed.
  LocationStatus _status = LocationStatus.ready;
  bool _started = false;
  bool _seeded = false;

  /// The township last published, so an unchanged one doesn't churn listeners.
  String? _publishedCode;

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
    // Keep 所在地 pinned to where the user actually is. Without this the current
    // township was resolved once at launch and then only on a services-off →
    // on transition, so travelling any distance left the app naming — and
    // alerting for — the township the app happened to start in.
    _fixSub = _reporter.fixes.listen(_onFix, onError: (_, _) {});
  }

  /// Republishes the current township for a fix from the foreground position
  /// stream. Silent when the township is unchanged (the common case: most moves
  /// stay inside one township) or unresolvable.
  Future<void> _onFix(GpsFix fix) async {
    final code = (await _location.townAt(fix.lat, fix.lng))?.code;
    if (code == null || code == _publishedCode) return;
    _publishedCode = code;
    _regions.setCurrentCode(code);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final previous = _status;
    final status = await _location.status();
    _status = status;
    final wasUsable = _usable(previous);
    final nowUsable = _usable(status);
    // GPS lost (services off / permission revoked): 所在地 must not keep
    // presenting the last-known township as where the user is. Clearing the
    // code puts the whole app back in the "can't locate" state (nationwide map
    // + the header's notice) instead of a stale place.
    // The first refresh only seeds [_status] — its "previous" is the optimistic
    // initial value, not a confirmed usable state, so it must never clear a
    // township that a fix may already have published while it was in flight.
    if (_seeded && wasUsable && !nowUsable) {
      _publishedCode = null;
      _regions.setCurrentCode(null);
    }
    // Recover only on an unusable → usable transition (services back / granted),
    // not on every resume — avoids re-subscribing the position stream needlessly.
    if (_seeded && nowUsable && !wasUsable) {
      _reporter.restart();
      final code = (await _location.currentTown())?.code;
      _publishedCode = code;
      _regions.setCurrentCode(code);
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
    _fixSub?.cancel();
    _serviceSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
