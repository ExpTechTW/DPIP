import 'dart:async';

import 'package:flutter/services.dart';

import 'package:dpip/app_old/page/home/home.dart';
import 'package:dpip/app_old/page/map/radar/radar.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/location_to_code.dart';
import 'package:dpip/utils/log.dart';

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

    GlobalProviders.location.setLatLng(latitude: data?['lat'], longitude: data?['lon']);

    final GeoJsonProperties? location = GeoJsonHelper.checkPointInPolygons(data?['lat'], data?['lon']);

    GlobalProviders.location.setCode(location?.code.toString());

    _updateAllPositions();
  } catch (e) {
    TalkerManager.instance.error('Error in getSavedLocation: $e');
  } finally {
    _completer?.complete();
    _completer = null;
  }
}

void _updateAllPositions() {
  RadarMap.updatePosition();
  HomePage.updatePosition();
}

void cancelSavedLocationOperation() {
  if (_completer != null && !_completer!.isCompleted) {
    _completer?.completeError('Operation cancelled');
    _completer = null;
  }
}
