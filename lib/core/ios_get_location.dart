import 'dart:async';

import "package:dpip/app/page/history/history.dart";
import "package:dpip/app/page/home/home.dart";
import "package:dpip/app/page/map/monitor/monitor.dart";
import "package:dpip/app/page/map/radar/radar.dart";
import "package:dpip/global.dart";
import "package:dpip/route/settings/content/location.dart";
import "package:dpip/util/location_to_code.dart";
import "package:dpip/util/log.dart";
import "package:flutter/services.dart";

const _channel = MethodChannel("com.exptech.dpip/data");
Completer<void>? _completer;

Future<void> getSavedLocation() async {
  if (_completer != null && !_completer!.isCompleted) {
    return _completer!.future;
  }

  _completer = Completer<void>();

  try {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>("getSavedLocation");
    final data = result?.map((key, value) => MapEntry(key, value.toDouble()));
    await Global.preference.setDouble("user-lat", data?["lat"] ?? 0.0);
    await Global.preference.setDouble("user-lon", data?["lon"] ?? 0.0);

    GeoJsonProperties? location = GeoJsonHelper.checkPointInPolygons(data?["lat"], data?["lon"]);

    if (location != null) {
      await Global.preference.setInt("user-code", location.code);
    } else {
      await Global.preference.remove("user-code");
    }
    _updateAllPositions();
  } catch (e) {
    TalkerManager.instance.error("Error in getSavedLocation: $e");
  } finally {
    _completer?.complete();
    _completer = null;
  }
}

void _updateAllPositions() {
  SettingsLocationView.updatePosition();
  RadarMap.updatePosition();
  HomePage.updatePosition();
  HistoryPage.updatePosition();
  MonitorPage.updatePosition();
}

void cancelSavedLocationOperation() {
  if (_completer != null && !_completer!.isCompleted) {
    _completer?.completeError('Operation cancelled');
    _completer = null;
  }
}
