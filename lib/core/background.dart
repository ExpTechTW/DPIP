import 'dart:convert';

import 'package:dpip/core/api.dart';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>> FCM(Map data) async {
  print(data);
  var ans = {
    "code": (DateTime.now().millisecondsSinceEpoch / 1000).round(),
    "title": "title",
    "body": "body",
    "channel": "default",
    "sound": "default",
    "level": 0,
  };
  final loc_data =
      json.decode(await rootBundle.loadString('assets/region.json'));
  var eq = jsonDecode(data["data"]);
  if (data["type"] == "eew") {
    List<String> loc_alert = [];
    var eew_loc = eewIntensity(eq["eq"], loc_data);
    if (pgaToIntensity(eew_loc["max_pga"]) > 4) {
      for (String key in eew_loc.keys) {
        if (key != "max_pga") {
          if (pgaToIntensity(eew_loc[key]["pga"]) > 3) {
            String city = key.split(" ")[0];
            if (!loc_alert.contains(city)) loc_alert.add(city);
            if (loc_alert.length > 5) break;
          }
        }
      }
      ans["title"] = "《強震即時警報（警報）》";
      ans["channel"] = "eew-alert";
      ans["sound"] = "eew_alert";
      ans["level"] = 2;
      ans["body"] =
          "${eq["eq"]["loc"]}發生地震　慎防強烈搖晃\n〈預估強烈搖晃區域〉\n${loc_alert.join("　")}";
    } else {
      ans["title"] = "地震速報（注意）";
    }
  }

  return ans;
}
