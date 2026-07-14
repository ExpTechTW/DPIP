/// [MeteorWeatherRepository] backed by [MeteorWeatherApi].
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/meteor_decode.dart';
import 'package:dpip/features/weather/data/meteor_weather_api.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';

/// Maps the datasource's raw JSON to domain models, converting transport/decode
/// errors to typed failures via [guardResult].
class MeteorWeatherRepositoryImpl implements MeteorWeatherRepository {
  const MeteorWeatherRepositoryImpl(this._api);

  final MeteorWeatherApi _api;

  @override
  Future<Result<Map<String, WeatherStation>>> stations() =>
      guardResult(() async {
        final raw = await _api.getStation();
        return raw.map(
          (code, value) => MapEntry(
            code,
            WeatherStation.fromJson(value as Map<String, dynamic>),
          ),
        );
      });

  @override
  Future<Result<WeatherSnapshot>> latest() =>
      guardResult(() async => WeatherSnapshot.decode(await _api.getLatest()));

  @override
  Future<Result<List<int>>> history() =>
      guardResult(() async => MeteorDecode.deltaSeconds(await _api.getList()));

  @override
  Future<Result<WeatherSnapshot>> at(int second) =>
      guardResult(() async => WeatherSnapshot.decode(await _api.getAt(second)));
}
