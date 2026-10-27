/// Unit tests for client-side weather/rain ranking.
library;

import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_ranking.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:flutter_test/flutter_test.dart';

WeatherStation _station({
  required String name,
  required String county,
  required String town,
}) => WeatherStation(
  name: name,
  county: county,
  town: town,
  altitude: 0,
  latitude: 0,
  longitude: 0,
);

void main() {
  final stations = {
    'A': _station(name: '甲', county: '臺北市', town: '中正區'),
    'B': _station(name: '乙', county: '臺北市', town: '大同區'),
    'C': _station(name: '丙', county: '新北市', town: '板橋區'),
  };

  group('rankRain', () {
    test('drops null and non-positive, sorts descending', () {
      final ranked = rankRain(
        stations: stations,
        snapshot: const RainSnapshot(
          time: 0,
          stations: [
            RainObservation(id: 'A', hour1: 12),
            RainObservation(id: 'B', hour1: 0),
            RainObservation(id: 'C', hour1: 30),
            RainObservation(id: 'Z', hour1: 99), // unknown station
          ],
        ),
        interval: RainInterval.hour1,
      );
      expect(ranked.map((e) => e.id).toList(), ['C', 'A']);
      expect(ranked.first.value, 30);
    });
  });

  group('rankWeather', () {
    test('merges to county keeping extreme', () {
      final ranked = rankWeather(
        stations: stations,
        snapshot: const WeatherSnapshot(
          time: 0,
          stations: [
            WeatherObservation(id: 'A', weatherCode: 0, temperature: 28),
            WeatherObservation(id: 'B', weatherCode: 0, temperature: 32),
            WeatherObservation(id: 'C', weatherCode: 0, temperature: 30),
          ],
        ),
        valueOf: (o) => o.temperature,
        ascending: false,
        merge: RankingMerge.county,
      );
      expect(ranked.map((e) => e.id).toList(), ['B', 'C']);
      expect(ranked.first.title(RankingMerge.county), '臺北市');
    });

    test('ascending + requirePositive for wind', () {
      final ranked = rankWeather(
        stations: stations,
        snapshot: const WeatherSnapshot(
          time: 0,
          stations: [
            WeatherObservation(
              id: 'A',
              weatherCode: 0,
              windSpeed: 5,
              windDirection: 90,
            ),
            WeatherObservation(id: 'B', weatherCode: 0, windSpeed: 0),
            WeatherObservation(id: 'C', weatherCode: 0, windSpeed: 2),
          ],
        ),
        valueOf: (o) => o.windSpeed,
        windDirectionOf: (o) => o.windDirection,
        ascending: true,
        merge: RankingMerge.none,
        requirePositive: true,
      );
      expect(ranked.map((e) => e.id).toList(), ['C', 'A']);
      expect(ranked.last.windDirection, 90);
    });

    test('temp extremes rank hi−lo range with detail', () {
      final ranked = rankTempExtremes(
        stations: stations,
        snapshot: const WeatherSnapshot(
          time: 0,
          stations: [
            WeatherObservation(
              id: 'A',
              weatherCode: 0,
              temperature: 28,
              high: 32,
              highTime: 100,
              low: 24,
              lowTime: 50,
            ),
            WeatherObservation(
              id: 'B',
              weatherCode: 0,
              temperature: 30,
              high: 31,
              highTime: 110,
              low: 29,
              lowTime: 60,
            ),
            WeatherObservation(
              id: 'C',
              weatherCode: 0,
              temperature: 27,
              high: 33,
              // missing low → skipped
            ),
          ],
        ),
        metric: TempExtremeMetric.range,
        ascending: false,
        merge: RankingMerge.none,
      );
      expect(ranked.map((e) => e.id).toList(), ['A', 'B']);
      expect(ranked.first.value, 8); // 32−24
      expect(ranked.first.tempExtreme!.highTime, 100);
      expect(ranked.first.eventTime, isNull); // range has no single event time
    });
  });

  group('rankTemperature', () {
    const snapshot = WeatherSnapshot(
      time: 0,
      stations: [
        WeatherObservation(
          id: 'A',
          weatherCode: 0,
          temperature: 28,
          high: 32,
          highTime: 100,
          low: 24,
          lowTime: 50,
        ),
        WeatherObservation(
          id: 'B',
          weatherCode: 0,
          temperature: 30,
          high: 31,
          highTime: 110,
          low: 29,
          lowTime: 60,
        ),
        WeatherObservation(
          id: 'C',
          weatherCode: 0,
          temperature: 33,
          high: 33,
          highTime: 120,
          // no low → skipped by the extreme metrics, still ranked as current
        ),
      ],
    );

    List<RankedObservation> rank(
      TempRankMetric metric, {
      bool ascending = false,
    }) => rankTemperature(
      stations: stations,
      snapshot: snapshot,
      metric: metric,
      ascending: ascending,
      merge: RankingMerge.none,
    );

    test('current ranks the reading in the snapshot, with no clock', () {
      final ranked = rank(TempRankMetric.current);
      expect(ranked.map((e) => e.id).toList(), ['C', 'B', 'A']);
      expect(ranked.first.value, 33);
      expect(ranked.first.eventTime, isNull);
    });

    // The chip strip is one entry point over the old separate tab, so each
    // metric must behave exactly as its own list used to.
    test('high ranks the recorded maximum with its occurrence time', () {
      // C has no recorded low, so the extremes cannot place it — the snapshot's
      // `hi` and `lo` always come as a pair.
      final ranked = rank(TempRankMetric.high);
      expect(ranked.map((e) => e.id).toList(), ['A', 'B']);
      expect(ranked.first.value, 32);
      expect(ranked.first.eventTime, 100);
    });

    test('low ranks coldest-first and skips stations without one', () {
      final ranked = rank(TempRankMetric.low, ascending: true);
      expect(ranked.map((e) => e.id).toList(), ['A', 'B']);
      expect(ranked.first.value, 24);
      expect(ranked.first.eventTime, 50);
    });

    test('range ranks the diurnal spread, which has no single time', () {
      final ranked = rank(TempRankMetric.range);
      expect(ranked.map((e) => e.id).toList(), ['A', 'B']);
      expect(ranked.first.value, 8);
      expect(ranked.first.eventTime, isNull);
    });
  });
}
