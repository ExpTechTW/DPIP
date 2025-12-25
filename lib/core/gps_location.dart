import 'dart:async';

import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/map_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

Completer<void>? _completer;
DateTime? _lastUpdateTime;

const _kMinUpdateInterval = Duration(seconds: 30);

Future<void> updateLocationFromGPS() async {
  if (_completer != null && !_completer!.isCompleted) {
    return _completer!.future;
  }

  final now = DateTime.now();
  if (_lastUpdateTime != null &&
      now.difference(_lastUpdateTime!) < _kMinUpdateInterval) {
    TalkerManager.instance.debug(
      '📍 [GPS] Skipping update (throttle: ${now.difference(_lastUpdateTime!).inSeconds}s)',
    );
    return;
  }

  _completer = Completer();

  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      TalkerManager.instance.debug('📍 [GPS] Location services are disabled');
      _clearLocation();
      return;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      TalkerManager.instance.debug('📍 [GPS] Location permission denied');
      _clearLocation();
      return;
    }

    Position? position = await Geolocator.getLastKnownPosition();
    if (position == null) {
      TalkerManager.instance.debug(
        '📍 [GPS] No last known position, getting current position',
      );
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    }

    final coordinates = LatLng(position.latitude, position.longitude);
    final code = getTownCodeFromCoordinates(coordinates);

    TalkerManager.instance.debug(
      '📍 [GPS] Updated location: (${position.latitude}, ${position.longitude}) → code: $code',
    );

    GlobalProviders.location.setCoordinates(coordinates);
    GlobalProviders.location.setCode(code);

    _lastUpdateTime = now;
  } catch (e, s) {
    TalkerManager.instance.error('📍 [GPS] Error getting location', e, s);
  } finally {
    _completer?.complete();
    _completer = null;
  }
}

@Deprecated('Use updateLocationFromGPS() instead')
Future<void> updateSavedLocationIOS() => updateLocationFromGPS();

void _clearLocation() {
  GlobalProviders.location.setCoordinates(null);
  GlobalProviders.location.setCode(null);
}
