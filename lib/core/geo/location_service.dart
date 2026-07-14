import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/geo/location_status.dart';
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

  /// The combined location-availability [LocationStatus] (services + permission).
  /// Never throws — a fault degrades to [LocationStatus.denied].
  Future<LocationStatus> status() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationStatus.serviceOff;
      }
      return switch (await Geolocator.checkPermission()) {
        LocationPermission.always => LocationStatus.ready,
        LocationPermission.whileInUse => LocationStatus.whileInUseOnly,
        LocationPermission.deniedForever => LocationStatus.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => LocationStatus.denied,
      };
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'location status');
      return LocationStatus.denied;
    }
  }

  /// Emits `true`/`false` when the OS location services are toggled on/off — the
  /// signal used to recover a dead position stream and refresh the status.
  Stream<bool> serviceEnabledStream() => Geolocator.getServiceStatusStream()
      .map((s) => s == ServiceStatus.enabled);

  /// Opens the system app-settings so the user can grant a permission that can't
  /// be requested in-app (permanently denied, or Android 11+ background
  /// location). Best-effort.
  Future<void> openSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'openAppSettings');
    }
  }

  /// Requests **foreground** location permission (call from a screen, after
  /// explaining why); returns whether a fix is now permitted. If permission is
  /// permanently denied, re-requesting can't prompt, so it routes to Settings.
  /// Never throws.
  Future<bool> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return false;
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'requestPermission');
      return false;
    }
  }

  /// Whether any location permission (while-in-use or Always) is granted. Never
  /// throws.
  Future<bool> granted() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'granted');
      return false;
    }
  }

  /// Whether background ("Always") location is granted — the precondition for
  /// native background reporting. On Android the background geofence can't fetch
  /// a fix (or prompt) with only "while in use", so callers must gate on this.
  /// Never throws.
  Future<bool> backgroundGranted() async {
    try {
      return await Geolocator.checkPermission() == LocationPermission.always;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'backgroundGranted');
      return false;
    }
  }

  /// Best-effort escalation to background ("Always") permission — call it as a
  /// **separate** step, only after foreground is already granted (Android 11+
  /// rejects a bundled request).
  ///
  /// In-app escalation only works on Android ≤10 (and a never-yet-shown iOS
  /// "Always" prompt). It **cannot** happen in-app on iOS once "While Using" is
  /// granted (geolocator's `requestPermission` returns the current status
  /// without ever calling `requestAlwaysAuthorization`) nor on Android 11+ —
  /// there "Allow all the time" only exists in system Settings. So: try the
  /// in-app prompt, and if that doesn't land on "Always", open Settings, where
  /// the grant lives. Either way the caller re-checks on resume. Never throws.
  Future<bool> requestBackground() async {
    try {
      final current = await Geolocator.checkPermission();
      if (current == LocationPermission.always) return true;
      if (current == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return false;
      }
      if (await Geolocator.requestPermission() == LocationPermission.always) {
        return true;
      }
      // Couldn't escalate in-app (iOS after "While Using", or Android 11+) —
      // "Always" lives in system Settings.
      await Geolocator.openAppSettings();
      return false;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'requestBackground');
      return false;
    }
  }

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
