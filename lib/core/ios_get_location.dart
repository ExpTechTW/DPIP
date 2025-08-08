import 'dart:async';

import 'package:flutter/services.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/map_utils.dart';

const _channel = MethodChannel('com.exptech.dpip/data');
Completer<void>? _completer;

Future<void> getSavedLocation() async {
  if (_completer != null && !_completer!.isCompleted) {
    return _completer!.future;
  }

  _completer = Completer<void>();

  try {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSavedLocation');

    if (result == null) return;

    final latitude = result['lat'] as double?;
    final longitude = result['lon'] as double?;

    if (latitude != null && longitude != null) {
      final code = getTownCodeFromCoordinates(LatLng(latitude, longitude));
      GlobalProviders.location.setCode(code);
      GlobalProviders.location.setCoordinates(LatLng(latitude, longitude));
    } else {
      GlobalProviders.location.setCode(null);
      GlobalProviders.location.setCoordinates(null);
    }
  } catch (e, s) {
    TalkerManager.instance.error('Error in getSavedLocation', e, s);
  } finally {
    _completer?.complete();
    _completer = null;
  }
}
