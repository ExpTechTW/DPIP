/// Guarded decodes shared by the meteor repo family (weather / rain /
/// lightning): the `code → station` map and the delta-seconds history list.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/meteor_decode.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';

/// The station catalogue as `code → model`, from any meteor `getStation()`.
Future<Result<Map<String, WeatherStation>>> fetchStations(
  Future<Map<String, dynamic>> Function() fetch,
) => guardResult(() async {
  final raw = await fetch();
  return raw.map(
    (code, value) =>
        MapEntry(code, WeatherStation.fromJson(value as Map<String, dynamic>)),
  );
});

/// The delta-seconds history list, from any meteor `getList()`.
Future<Result<List<int>>> fetchHistory(
  Future<List<dynamic>> Function() fetch,
) => guardResult(() async => MeteorDecode.deltaSeconds(await fetch()));
