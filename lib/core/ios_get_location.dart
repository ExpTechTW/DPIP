import 'dart:async';

import "package:dpip/app/page/history/history.dart";
import "package:dpip/app/page/home/home.dart";
import "package:dpip/app/page/map/monitor/monitor.dart";
import "package:dpip/app/page/map/radar/radar.dart";
import "package:dpip/core/location.dart";
import "package:dpip/global.dart";
import "package:dpip/model/location/location.dart";
import "package:dpip/route/settings/content/location.dart";
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

    LocationResult positionData = await LocationService().getLatLngLocation(data?["lat"] ?? 0.0, data?["lon"] ?? 0.0);
    var position = positionData.toJson();
    String country = position["cityTown"];
    List<String> parts = country.split(" ");

    if (parts.length == 3) {
      String code = parts[2];

      if (Global.location.containsKey(code)) {
        Location locationInfo = Global.location[code]!;

        await Global.preference.setString("location-city", locationInfo.city);
        await Global.preference.setString("location-town", locationInfo.town);

        _updateAllPositions();
      }
    } else {
      await Global.preference.remove("location-city");
      await Global.preference.remove("location-town");
      await Global.preference.setDouble("user-lat", 0.0);
      await Global.preference.setDouble("user-lon", 0.0);
      _updateAllPositions();
    }
  } on PlatformException catch (e) {
    TalkerManager.instance.error("PlatformException in getSavedLocation: ${e.message}");
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
