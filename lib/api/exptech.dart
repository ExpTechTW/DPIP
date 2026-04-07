import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dpip/api/model/announcement.dart';
import 'package:dpip/api/model/changelog/changelog.dart';
import 'package:dpip/api/model/crowdin/localization_progress.dart';
import 'package:dpip/api/model/eew.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/meteor_station.dart';
import 'package:dpip/api/model/notification_record.dart';
import 'package:dpip/api/model/notify/notify_settings.dart';
import 'package:dpip/api/model/report/earthquake_report.dart';
import 'package:dpip/api/model/report/partial_earthquake_report.dart';
import 'package:dpip/api/model/rts/rts.dart';
import 'package:dpip/api/model/server_status.dart';
import 'package:dpip/api/model/station.dart';
import 'package:dpip/api/model/tsunami/tsunami.dart';
import 'package:dpip/api/model/weather/lightning.dart';
import 'package:dpip/api/model/weather/rain.dart';
import 'package:dpip/api/model/weather/weather.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/api/route.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:option_result/result.dart';
import 'package:zstandard/zstandard.dart';

part '_client.dart';
part 'endpoints/app.dart';
part 'endpoints/device.dart';
part 'endpoints/earthquake.dart';
part 'endpoints/history.dart';
part 'endpoints/station.dart';
part 'endpoints/tsunami.dart';
part 'endpoints/weather.dart';

/// Client for the ExpTech API.
class ExpTech
    with
        EarthquakeEndpoints,
        WeatherEndpoints,
        TsunamiEndpoints,
        HistoryEndpoints,
        StationEndpoints,
        DeviceEndpoints,
        AppEndpoints {
  /// Optional API key for authenticated requests.
  String? apikey;

  /// Creates an [ExpTech] client.
  ExpTech({this.apikey});
}
