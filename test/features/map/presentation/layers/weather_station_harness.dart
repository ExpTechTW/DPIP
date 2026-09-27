/// Shared fixtures for the station-value map layers (wind, humidity,
/// temperature, pressure): one repository whose single snapshot carries three
/// stations — fully observed, entirely unobserved, and wind-only — so every
/// layer's null-skip branch is exercised the same way its value-reading branch
/// is, without a bespoke fake per file.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';

/// Every field set — what each layer's `valueOf`/`reading`/`valueColor`
/// should resolve to a real value for.
const stationFullId = 'A0A010';

/// Every optional field left null — what every layer must treat as "nothing
/// to draw, nothing to read, no tap target".
const stationEmptyId = 'A0A020';

/// Wind speed set, direction absent — wind's own "reading without a degree
/// suffix, no arrow to rotate" branch, which the other two stations never
/// reach. Harmless noise for the other three layers, which read it as just
/// another station with nothing to show.
const stationSpeedOnlyId = 'A0A030';

const fullObservation = WeatherObservation(
  id: stationFullId,
  weatherCode: 100,
  temperature: 27.8,
  humidity: 65,
  pressure: 1008.2,
  windDirection: 90,
  windSpeed: 7.4,
);

const emptyObservation = WeatherObservation(id: stationEmptyId, weatherCode: 0);

const speedOnlyObservation = WeatherObservation(
  id: stationSpeedOnlyId,
  weatherCode: 100,
  windSpeed: 3.1,
);

/// A two-sample trend carrying every series a concrete layer's `trendOf`
/// might read, aligned by index to [WeatherTrend.times].
const fixtureTrend = WeatherTrend(
  id: stationFullId,
  range: '24h',
  times: [1699996400, 1700000000],
  temperature: [26.5, 27.8],
  humidity: [70, 65],
  pressure: [1009.0, 1008.2],
  windSpeed: [5.0, 7.4],
  windDirection: [80, 90],
);

/// A weather repository with the three-station catalogue above baked into its
/// one snapshot, plus [fixtureTrend] for every trend request.
///
/// Only the three calls `WeatherStationLayer` makes (`stations`, `latest`,
/// `trend`) are implemented — the rest (`history`, `at`, `realtime`,
/// `forecast`) fall through [noSuchMethod], following `EmptyWeatherRepository`
/// in `raster_timeline_harness.dart`: no station layer test goes near them.
class FakeStationWeatherRepository implements MeteorWeatherRepository {
  /// Station ids [trend] was asked for, in call order.
  final List<String> trendRequests = [];

  /// Ranges [trend] was asked for, in call order, parallel to [trendRequests].
  final List<String> trendRanges = [];

  @override
  Future<Result<Map<String, WeatherStation>>> stations() async => const Ok({
    stationFullId: WeatherStation(
      name: '測站一',
      county: '臺北市',
      town: '中正區',
      altitude: 6,
      latitude: 25.04,
      longitude: 121.51,
    ),
    stationEmptyId: WeatherStation(
      name: '測站二',
      county: '高雄市',
      town: '苓雅區',
      altitude: 3,
      latitude: 22.62,
      longitude: 120.31,
    ),
    stationSpeedOnlyId: WeatherStation(
      name: '測站三',
      county: '花蓮縣',
      town: '吉安鄉',
      altitude: 12,
      latitude: 23.98,
      longitude: 121.58,
    ),
  });

  @override
  Future<Result<WeatherSnapshot>> latest() async => const Ok(
    WeatherSnapshot(
      time: 1700000000,
      stations: [fullObservation, emptyObservation, speedOnlyObservation],
    ),
  );

  @override
  Future<Result<WeatherTrend>> trend(String id, {String range = '24h'}) async {
    trendRequests.add(id);
    trendRanges.add(range);
    return const Ok(fixtureTrend);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
