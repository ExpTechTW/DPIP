/// [MeteorWeatherRepository] backed by [MeteorWeatherApi].
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_repository_impl.dart';
import 'package:dpip/features/weather/data/meteor_station_decode.dart';
import 'package:dpip/features/weather/data/meteor_weather_api.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';

/// Maps the datasource's raw JSON to domain models, converting transport/decode
/// errors to typed failures via [guardResult].
class MeteorWeatherRepositoryImpl
    extends MeteorSnapshotRepositoryImpl<WeatherSnapshot>
    implements MeteorWeatherRepository {
  MeteorWeatherRepositoryImpl(this._weatherApi) : super(_weatherApi.snapshots);

  final MeteorWeatherApi _weatherApi;

  @override
  WeatherSnapshot decodeSnapshot(Map<String, dynamic> json) =>
      WeatherSnapshot.decode(json);

  @override
  Future<Result<Map<String, WeatherStation>>> stations() =>
      fetchStations(_weatherApi.snapshots.getStation);

  @override
  Future<Result<WeatherTrend>> trend(String id, {String range = '24h'}) =>
      guardResult(
        () async => WeatherTrend.decode(
          await _weatherApi.snapshots.getTrend(id, range),
        ),
      );

  @override
  Future<Result<WeatherRealtime?>> realtime(
    double latitude,
    double longitude,
  ) => guardResult(() async {
    final raw = await _weatherApi.getRealtime(latitude, longitude);
    // Outside Taiwan the API returns `{}` — a valid "no station", not an error.
    return raw.isEmpty ? null : WeatherRealtime.fromJson(raw);
  });

  @override
  Future<Result<WeatherForecast>> forecast(String code) => guardResult(
    () async => WeatherForecast.fromJson(await _weatherApi.getForecast(code)),
  );
}
