import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/location/data/town_directory.dart';
import 'package:dpip/features/location/domain/town.dart';
import 'package:geolocator/geolocator.dart';

/// A GPS coordinate fix in decimal degrees.
typedef GpsFix = ({double lat, double lng});

/// Resolves the device's current township from GPS via [TownDirectory].
///
/// Wraps `geolocator` (native `CLLocationManager` / `FusedLocationProvider`).
/// The availability check and the position fetch are injectable seams, so the
/// resolution is unit-testable without the platform. [currentTown] returns null
/// whenever a fix can't be had (services off, permission denied, timeout) — the
/// caller then shows the "can't get current location" state and keeps the last
/// known region.
class LocationService {
  LocationService(
    this._directory, {
    Future<bool> Function()? isAvailable,
    Future<GpsFix?> Function()? fix,
  }) : _isAvailable = isAvailable ?? _geolocatorAvailable,
       _fix = fix ?? _geolocatorFix;

  final TownDirectory _directory;
  final Future<bool> Function() _isAvailable;
  final Future<GpsFix?> Function() _fix;

  /// Whether location services + permission currently allow a fix.
  Future<bool> isAvailable() => _isAvailable();

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

  /// The current township from GPS, or null if unavailable / no fix.
  Future<Town?> currentTown() async {
    try {
      if (!await _isAvailable()) return null;
      final fix = await _fix();
      if (fix == null) return null;
      return _directory.nearest(fix.lat, fix.lng);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'GPS fix');
      return null;
    }
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
