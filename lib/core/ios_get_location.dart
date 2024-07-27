import 'package:dpip/core/location.dart';
import 'package:dpip/model/location/location.dart';
import 'package:flutter/services.dart';

import 'package:dpip/global.dart';

const _channel = MethodChannel('com.exptech.dpip/data');

Future<void> getSavedLocation() async {
  try {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSavedLocation');
    final data = result?.map((key, value) => MapEntry(key, value.toDouble()));
    Global.preference.setDouble("user-lat", data?["lat"] ?? 0.0);
    Global.preference.setDouble("user-lon", data?["lon"] ?? 0.0);

    LocationResult positionData = await LocationService().getLatLngLocation(data?["lat"] ?? 0.0, data?["lon"] ?? 0.0);
    var position = positionData.toJson();
    String country = position['cityTown'];
    List<String> parts = country.split(' ');

    if (parts.length == 3) {
      String code = parts[2];

      if (Global.location.containsKey(code)) {
        Location locationInfo = Global.location[code]!;

        Global.preference.setString("location-auto", " (啟用自動定位)");
        Global.preference.setString("location-city", locationInfo.city);
        Global.preference.setString("location-town", locationInfo.town);

        print('Updated location: ${locationInfo.city}, ${locationInfo.town}');
      } else {
        print('Code $code not found in location data');

        Global.preference.setString("location-city", "解析失敗");
        Global.preference.setString("location-town", "解析失敗");
      }
    }
    return;
  } on PlatformException catch (e) {
    return;
  }
}
