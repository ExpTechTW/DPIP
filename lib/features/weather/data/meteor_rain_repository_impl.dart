/// [MeteorRainRepository] backed by [MeteorSnapshotApi].
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_repository_impl.dart';
import 'package:dpip/features/weather/data/meteor_station_decode.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/rain_trend.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';

/// Maps the datasource's raw JSON to domain models, converting transport/decode
/// errors to typed failures via [guardResult].
class MeteorRainRepositoryImpl
    extends MeteorSnapshotRepositoryImpl<RainSnapshot>
    implements MeteorRainRepository {
  const MeteorRainRepositoryImpl(super.api);

  @override
  RainSnapshot decodeSnapshot(Map<String, dynamic> json) =>
      RainSnapshot.decode(json);

  @override
  Future<Result<Map<String, WeatherStation>>> stations() =>
      fetchStations(api.getStation);

  @override
  Future<Result<RainTrend>> trend(String id, {String range = '24h'}) =>
      guardResult(() async => RainTrend.decode(await api.getTrend(id, range)));
}
