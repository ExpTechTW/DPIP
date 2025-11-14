import 'dart:async';
import 'dart:io';

import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/map_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

Completer<void>? _completer;

Future<void> updateSavedLocationIOS() async {
  if (!Platform.isIOS) return;

  final completer = _completer;

  if (completer != null && !completer.isCompleted) return completer.future;

  _completer = Completer();

  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      TalkerManager.instance.debug('📍 [iOS GPS] Location services are disabled');
      GlobalProviders.location.setCode(null);
      GlobalProviders.location.setCoordinates(null);
      _completer?.complete();
      return;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      TalkerManager.instance.debug('📍 [iOS GPS] Location permission denied');
      GlobalProviders.location.setCode(null);
      GlobalProviders.location.setCoordinates(null);
      _completer?.complete();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      TalkerManager.instance.debug('📍 [iOS GPS] Location permission denied forever');
      GlobalProviders.location.setCode(null);
      GlobalProviders.location.setCoordinates(null);
      _completer?.complete();
      return;
    }

    Position? position = await Geolocator.getLastKnownPosition();

    if (position == null) {
      TalkerManager.instance.debug('📍 [iOS GPS] No last known position, getting current position');
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
      );
    }

    final latitude = position.latitude;
    final longitude = position.longitude;

    final code = getTownCodeFromCoordinates(LatLng(latitude, longitude));
    TalkerManager.instance.debug('📍 [iOS GPS] Updated location: ($latitude, $longitude) → code: $code');

    GlobalProviders.location.setCode(code);
    GlobalProviders.location.setCoordinates(LatLng(latitude, longitude));
  } catch (e, s) {
    TalkerManager.instance.error('📍 [iOS GPS] Error getting location', e, s);
  } finally {
    _completer?.complete();
  }
}
