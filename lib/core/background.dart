// import 'dart:convert';
//
// import 'package:dpip/core/api.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// Future<Map<String, dynamic>> FCM(Map data) async {
//   print(data);
//   var ans = {
//     "code": (DateTime.now().millisecondsSinceEpoch / 1000).round(),
//     "title": "title",
//     "body": "body",
//     "channel": "default",
//     "sound": "default",
//     "level": 0,
//   };
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   String loc_name =
//       "${prefs.getString('loc-city') ?? "臺南市"} ${prefs.getString('loc-town') ?? "歸仁區"}";
//   if (data["type"] != null) {
//     if (data["type"] == "eew") {
//       final loc_data =
//           json.decode(await rootBundle.loadString('assets/region.json'));
//       List<String> loc_alert = [];
//       var eq = jsonDecode(data["data"]);
//       var eew_loc = eewIntensity(eq["eq"], loc_data);
//       if (pgaToIntensity(eew_loc["max_pga"]) > 4) {
//         for (String key in eew_loc.keys) {
//           if (key != "max_pga") {
//             if (pgaToIntensity(eew_loc[key]["pga"]) > 3) {
//               String city = key.split(" ")[0];
//               if (!loc_alert.contains(city)) loc_alert.add(city);
//               if (loc_alert.length > 5) break;
//             }
//           }
//         }
//         int LV = pgaToIntensity(eew_loc[loc_name]["pga"]);
//         ans["title"] = "《強震即時警報（警報）》";
//         ans["channel"] = (LV > 3) ? "eew_alert" : "eew_warn";
//         ans["sound"] = (LV > 3) ? "eew_alert" : "eew_warn";
//         ans["level"] = (LV > 3) ? 2 : 1;
//         var arr = speed(double.parse(eq["eq"]["depth"].toString()),
//             eew_loc[loc_name]["dist"]);
//         ans["body"] =
//             "『本地預估震度${int_to_str_zh(LV)}　${arr["Stime"]?.floor()}秒後抵達』\n${eq["eq"]["loc"]}發生地震　慎防強烈搖晃\n〈預估強烈搖晃區域〉\n${loc_alert.join("　")}";
//       } else {
//         int LV = pgaToIntensity(eew_loc[loc_name]["pga"]);
//         ans["title"] = "地震速報（注意）";
//         ans["channel"] = (LV > 2) ? "eew_warn" : "default";
//         ans["sound"] = (LV > 2) ? "eew_warn" : "default";
//         ans["level"] = (LV > 2) ? 1 : 0;
//         DateTime dateTime =
//             DateTime.fromMillisecondsSinceEpoch(eq["eq"]["time"]);
//         String formattedTime = DateFormat('HH時mm分左右').format(dateTime);
//         var arr = speed(double.parse(eq["eq"]["depth"].toString()),
//             eew_loc[loc_name]["dist"]);
//         ans["body"] =
//             "『本地預估震度${int_to_str_zh(LV)}　${arr["Stime"]?.floor()}秒後抵達』\n$formattedTime，${eq["eq"]["loc"]}發生地震。震源深度${eq["eq"]["depth"]}公里，地震規模M${eq["eq"]["mag"].toStringAsFixed(1)}，最大預估震度${int_to_str_zh(pgaToIntensity(eew_loc["max_pga"]))}。";
//       }
//     } else if (data["type"] == "broadcast") {
//       if (data["list"].contains(prefs.getString('loc-city') ?? "臺南市") ||
//           data["list"].contains(
//               "${prefs.getString('loc-city') ?? "臺南市"}${prefs.getString('loc-town') ?? "歸仁區"}")) {
//         ans["title"] = data["title"];
//         ans["channel"] =
//             (data["channel"] != null) ? data["channel"] : "default";
//         ans["sound"] = (data["sound"] != null) ? data["sound"] : "default";
//         ans["level"] = (data["level"] != null) ? data["level"] : 0;
//         ans["body"] = data["body"];
//       } else {
//         ans["cancel"] = true;
//       }
//     }
//   } else {
//     ans["title"] = data["title"];
//     ans["channel"] = (data["channel"] != null) ? data["channel"] : "default";
//     ans["sound"] = (data["sound"] != null) ? data["sound"] : "default";
//     ans["level"] = (data["level"] != null) ? data["level"] : 0;
//     ans["body"] = data["body"];
//   }
//   return ans;
// }
