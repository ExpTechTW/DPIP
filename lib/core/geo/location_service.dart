import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:geolocator/geolocator.dart';

/// A GPS coordinate fix in decimal degrees.
typedef GpsFix = ({double lat, double lng});

/// Resolves the device's current township from GPS.
///
/// Wraps `geolocator` (native `CLLocationManager` / `FusedLocationProvider`).
/// The availability check and the position fetch are injectable seams, so the
/// resolution is unit-testable without the platform. A fix resolves by exact
/// **point-in-polygon** ([TownBoundaries]) when the boundary data is available,
/// falling back to nearest-centroid ([TownDirectory]) at sea or before the
/// boundaries finish loading. [currentTown] returns null whenever a fix can't be
/// had (services off, permission denied, timeout) — the caller then shows the
/// "can't get current location" state and keeps the last known region.
class LocationService {
  LocationService(
    this._directory, {
    this._boundaries,
    Future<bool> Function()? isAvailable,
    Future<GpsFix?> Function()? fix,
  }) : _isAvailable = isAvailable ?? _geolocatorAvailable,
       _fix = fix ?? _geolocatorFix;

  final TownDirectory _directory;

  /// Township boundary polygons for exact point-in-polygon resolution, loaded
  /// in the background (nullable / may still be pending — see [_resolve]).
  final Future<TownBoundaries>? _boundaries;

  final Future<bool> Function() _isAvailable;
  final Future<GpsFix?> Function() _fix;

  /// Requests location permission (call from a screen, after explaining why).
  /// Returns whether a fix is now permitted.
  Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Whether any location permission (while-in-use or Always) is granted.
  Future<bool> granted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Whether background ("Always") location is granted — the precondition for
  /// native background reporting. On Android the background geofence can't fetch
  /// a fix (or prompt) with only "while in use", so callers must gate on this;
  /// iOS requests Always from its own plugin.
  Future<bool> backgroundGranted() async =>
      await Geolocator.checkPermission() == LocationPermission.always;

  /// Best-effort escalation to background ("Always") permission, returning
  /// whether it's now granted. On Android 10 this can grant inline; on Android
  /// 11+ the OS requires the user to choose "Allow all the time" in Settings, so
  /// it often can't grant here — a full staged rationale flow belongs in
  /// onboarding. Safe to call when already granted (no re-prompt).
  Future<bool> requestBackground() async =>
      await Geolocator.requestPermission() == LocationPermission.always;

  /// A distance-filtered stream of GPS fixes — each emission is a move of at
  /// least [distanceFilterMeters], which is exactly the trigger for a device-
  /// location report (see `DeviceLocationReporter`). Foreground only.
  Stream<GpsFix> positionStream({int distanceFilterMeters = 250}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: distanceFilterMeters,
        ),
      ).map((position) => (lat: position.latitude, lng: position.longitude));

  /// The current township from GPS, or null if unavailable / no fix.
  Future<Town?> currentTown() async {
    try {
      if (!await _isAvailable()) return null;
      final fix = await _fix();
      if (fix == null) return null;
      return await _resolve(fix.lat, fix.lng);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'GPS fix');
      return null;
    }
  }

  /// Resolves ([lat], [lng]) to a township: exact point-in-polygon when the
  /// boundary data is loaded, else nearest-centroid (at sea, in a boundary gap,
  /// or before the background boundary load completes).
  Future<Town?> _resolve(double lat, double lng) async {
    final boundaries = _boundaries;
    if (boundaries != null) {
      final code = (await boundaries).codeAt(lat, lng);
      if (code != null) return _directory.byCode(code);
    }
    return _directory.nearest(lat, lng);
  }

  static Future<bool> _geolocatorAvailable() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<GpsFix?> _geolocatorFix() async {
    final position =
        await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
    return (lat: position.latitude, lng: position.longitude);
  }
}
