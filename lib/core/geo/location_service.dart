import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/permissions/permission_outcome.dart';
import 'package:dpip/core/permissions/system_settings.dart';
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
    Future<GpsFix?> Function()? lastKnown,
    Future<LocationStatus> Function()? status,
  }) : _isAvailable = isAvailable ?? _geolocatorAvailable,
       _fix = fix ?? _geolocatorFix,
       _lastKnownFix = lastKnown ?? _geolocatorLastKnown,
       _status = status ?? _geolocatorStatus;

  final TownDirectory _directory;

  /// Township boundary polygons for exact point-in-polygon resolution, loaded
  /// in the background (nullable / may still be pending — see [_resolve]).
  final Future<TownBoundaries>? _boundaries;

  final Future<bool> Function() _isAvailable;
  final Future<GpsFix?> Function() _fix;
  final Future<GpsFix?> Function() _lastKnownFix;
  final Future<LocationStatus> Function() _status;

  /// The combined location-availability [LocationStatus] (services + permission).
  /// Never throws — a fault degrades to [LocationStatus.denied].
  Future<LocationStatus> status() async {
    try {
      return await _status();
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
    Log.info('permission: opening app settings');
    await openAppSettingsPage();
  }

  /// Requests **foreground** location permission (call from a screen, after
  /// explaining why).
  ///
  /// Reports what happened rather than opening Settings itself. It used to
  /// jump straight there on a permanent denial, which drops the user into a
  /// system screen with no idea why they are looking at it — the caller can
  /// explain first now. Never throws.
  Future<PermissionOutcome> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        return PermissionOutcome.needsSettings;
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Log.info('permission: location request -> $permission');
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return PermissionOutcome.granted;
      }
      // A refusal at the prompt turns into a permanent one on both platforms:
      // iOS never asks twice, and Android stops after the second refusal.
      return permission == LocationPermission.deniedForever
          ? PermissionOutcome.needsSettings
          : PermissionOutcome.denied;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'requestPermission');
      return PermissionOutcome.denied;
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
  Future<PermissionOutcome> requestBackground() async {
    try {
      final current = await Geolocator.checkPermission();
      Log.info('permission: background location, current = $current');
      if (current == LocationPermission.always) {
        return PermissionOutcome.granted;
      }
      if (current == LocationPermission.deniedForever) {
        return PermissionOutcome.needsSettings;
      }
      if (await Geolocator.requestPermission() == LocationPermission.always) {
        return PermissionOutcome.granted;
      }
      // Couldn't escalate in-app (iOS after "While Using", or Android 11+) —
      // "Always" lives in system Settings, and the caller says so before
      // sending anyone there.
      return PermissionOutcome.needsSettings;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'requestBackground');
      return PermissionOutcome.denied;
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

  /// Best-effort current fix: a cached position if it's fresh enough
  /// ([_maxLastKnownAge] — which the OS may have derived from network/Wi-Fi
  /// rather than GPS), else a medium-accuracy live read. Never throws; null
  /// when location is unavailable/denied or no position could be resolved.
  Future<GpsFix?> currentFix() async {
    try {
      if (!await _isAvailable()) return null;
      return await _fix();
    } on TimeoutException {
      Log.warning('GPS fix timed out — no current location available');
      return null;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'GPS fix');
      return null;
    }
  }

  /// The most recent cached fix if it's fresh enough ([_maxLastKnownAge]),
  /// else null — never a live read, so it returns immediately.
  ///
  /// For surfaces that must frame instantly (the home backdrop) and would
  /// otherwise wait out a GPS timeout: on a simulator with no location the
  /// cached fix is null, so it can fall back to the nationwide view right away
  /// instead of holding the previous frame for the live-read window.
  Future<GpsFix?> lastKnownFix() async {
    try {
      return await _lastKnownFix();
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'last-known GPS fix');
      return null;
    }
  }

  /// The current township from GPS, or null if unavailable / no fix.
  Future<Town?> currentTown() async {
    try {
      if (!await _isAvailable()) return null;
      final fix = await _fix();
      if (fix == null) return null;
      return await _resolve(fix.lat, fix.lng);
    } on TimeoutException {
      // No fix within the window (indoors, moving, or a simulator with no set
      // location) is a normal outcome, not an error — don't forward routine "no
      // fix" to crash reporting; the caller keeps the last known region.
      Log.warning('GPS fix timed out — no current location available');
      return null;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'GPS fix');
      return null;
    }
  }

  /// The township containing ([lat], [lng]) — for callers that already hold a
  /// fix (the foreground position stream) and must not pay for another one.
  Future<Town?> townAt(double lat, double lng) => _resolve(lat, lng);

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

  static Future<GpsFix?> _geolocatorLastKnown() async {
    final cached = await Geolocator.getLastKnownPosition();
    if (cached != null && _isFresh(cached.timestamp)) {
      return (lat: cached.latitude, lng: cached.longitude);
    }
    return null;
  }

  static Future<LocationStatus> _geolocatorStatus() async {
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
  }

  /// How old a cached OS fix may be and still stand in for a live one. The
  /// cached fix is only a head start on the first frame, so it has to be recent
  /// enough that it still describes where the user *is*: an hours-old fix from
  /// another county would name the wrong 所在地, which for a disaster app means
  /// showing someone another region's hazards.
  static const Duration _maxLastKnownAge = Duration(minutes: 10);

  static Future<GpsFix?> _geolocatorFix() async {
    final cached = await Geolocator.getLastKnownPosition();
    if (cached != null && _isFresh(cached.timestamp)) {
      return (lat: cached.latitude, lng: cached.longitude);
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return (lat: position.latitude, lng: position.longitude);
  }

  static bool _isFresh(DateTime timestamp) =>
      DateTime.now().toUtc().difference(timestamp.toUtc()) <= _maxLastKnownAge;
}
