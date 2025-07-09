import 'dart:async';

import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/location_to_code.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.exptech.dpip/data');
Completer<void>? _completer;

Future<void> getSavedLocation() async {
  if (_completer != null && !_completer!.isCompleted) {
    return _completer!.future;
  }

  _completer = Completer<void>();

  try {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSavedLocation');
    final data = result?.map((key, value) => MapEntry(key, value.toDouble()));

    final latitude = data?['lat'] as double?;
    final longitude = data?['lon'] as double?;

    GlobalProviders.location.setLatLng(latitude: latitude, longitude: longitude);

    if (latitude != null && longitude != null) {
      final location = GeoJsonHelper.checkPointInPolygons(latitude, longitude);
      print(location);
      GlobalProviders.location.setCode(location?.code.toString());
    }
  } catch (e) {
    TalkerManager.instance.error('Error in getSavedLocation: $e');
  } finally {
    _completer?.complete();
    _completer = null;
  }
}
