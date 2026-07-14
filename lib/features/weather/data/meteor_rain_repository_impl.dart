/// [MeteorRainRepository] backed by [MeteorRainApi].
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/meteor_decode.dart';
import 'package:dpip/features/weather/data/meteor_rain_api.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/rain_trend.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';

/// Maps the datasource's raw JSON to domain models, converting transport/decode
/// errors to typed failures via [guardResult].
class MeteorRainRepositoryImpl implements MeteorRainRepository {
  const MeteorRainRepositoryImpl(this._api);

  final MeteorRainApi _api;

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
  Future<Result<RainSnapshot>> latest() =>
      guardResult(() async => RainSnapshot.decode(await _api.getLatest()));

  @override
  Future<Result<List<int>>> history() =>
      guardResult(() async => MeteorDecode.deltaSeconds(await _api.getList()));

  @override
  Future<Result<RainSnapshot>> at(int second) =>
      guardResult(() async => RainSnapshot.decode(await _api.getAt(second)));

  @override
  Future<Result<RainTrend>> trend(String id, {String range = '24h'}) =>
      guardResult(() async => RainTrend.decode(await _api.getTrend(id, range)));
}
