import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial valid-region sync does not invalidate realtime', () async {
    final regions = _savedRegions(['660'])..select(2);
    addTearDown(regions.dispose);
    var invalidationCount = 0;
    final controller = HomeWeatherController(
      _FakeWeatherRepository(onRealtime: (_, _) async => const Ok(null)),
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeInvalidated: () async {
        invalidationCount += 1;
      },
    );
    addTearDown(controller.dispose);

    await _waitUntilSettled(controller);

    expect(regions.selectedCode, '660');
    expect(invalidationCount, 0);
  });

  test('initial null-region sync does not invalidate realtime', () {
    final regions = _savedRegions(['660']);
    addTearDown(regions.dispose);
    var invalidationCount = 0;
    final controller = HomeWeatherController(
      _FakeWeatherRepository(onRealtime: (_, _) async => const Ok(null)),
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeInvalidated: () async {
        invalidationCount += 1;
      },
    );
    addTearDown(controller.dispose);

    expect(regions.selectedCode, isNull);
    expect(invalidationCount, 0);
  });

  test('valid region change invalidates realtime exactly once', () async {
    final regions = _savedRegions(['660', '100'])..select(2);
    addTearDown(regions.dispose);
    var invalidationCount = 0;
    final controller = HomeWeatherController(
      _FakeWeatherRepository(onRealtime: (_, _) async => const Ok(null)),
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeInvalidated: () async {
        invalidationCount += 1;
      },
    );
    addTearDown(controller.dispose);
    await _waitUntilSettled(controller);

    regions.select(3);
    await _waitUntilSettled(controller);

    expect(regions.selectedCode, '100');
    expect(invalidationCount, 1);
  });

  test('successful changed-region response loads after invalidation', () async {
    final weather = _weather();
    final regions = _savedRegions(['660', '100'])..select(2);
    addTearDown(regions.dispose);
    final events = <String>[];
    final controller = HomeWeatherController(
      _FakeWeatherRepository(onRealtime: (_, _) async => Ok(weather)),
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeLoaded: (regionCode, _) async {
        events.add('loaded:$regionCode');
      },
      onRealtimeInvalidated: () async {
        events.add('invalidated');
      },
    );
    addTearDown(controller.dispose);
    await _waitUntilSettled(controller);
    events.clear();

    regions.select(3);
    await _waitUntilSettled(controller);

    expect(events, ['invalidated', 'loaded:100']);
  });

  test('valid region to Nationwide invalidates realtime once', () async {
    final regions = _savedRegions(['660'])..select(2);
    addTearDown(regions.dispose);
    var invalidationCount = 0;
    final controller = HomeWeatherController(
      _FakeWeatherRepository(onRealtime: (_, _) async => const Ok(null)),
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeInvalidated: () async {
        invalidationCount += 1;
      },
    );
    addTearDown(controller.dispose);
    await _waitUntilSettled(controller);

    regions.select(0);

    expect(regions.selectedCode, isNull);
    expect(invalidationCount, 1);
  });

  test('null region to valid region invalidates realtime once', () async {
    final regions = _savedRegions(['660']);
    addTearDown(regions.dispose);
    var invalidationCount = 0;
    final controller = HomeWeatherController(
      _FakeWeatherRepository(onRealtime: (_, _) async => const Ok(null)),
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeInvalidated: () async {
        invalidationCount += 1;
      },
    );
    addTearDown(controller.dispose);

    regions.select(2);
    await _waitUntilSettled(controller);

    expect(regions.selectedCode, '660');
    expect(invalidationCount, 1);
  });

  test(
    'notification with unchanged selected region does not invalidate',
    () async {
      final regions = _savedRegions(['660'])..select(2);
      addTearDown(regions.dispose);
      var invalidationCount = 0;
      final controller = HomeWeatherController(
        _FakeWeatherRepository(onRealtime: (_, _) async => const Ok(null)),
        const _FakeHourTrendRepository(),
        regions,
        _directory,
        onRealtimeInvalidated: () async {
          invalidationCount += 1;
        },
      );
      addTearDown(controller.dispose);
      await _waitUntilSettled(controller);

      expect(regions.addSaved('100'), isTrue);

      expect(regions.selectedCode, '660');
      expect(invalidationCount, 0);
    },
  );

  test('successful realtime weather invokes the callback once', () async {
    final weather = _weather();
    final repository = _FakeWeatherRepository(
      onRealtime: (_, _) async => Ok(weather),
    );
    final regions = _savedRegions(['660'])..select(2);
    addTearDown(regions.dispose);

    final callbackRelease = Completer<void>();
    final callbackCalls = <(String, WeatherRealtime)>[];
    final controller = HomeWeatherController(
      repository,
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeLoaded: (regionCode, result) {
        callbackCalls.add((regionCode, result));
        return callbackRelease.future;
      },
    );
    addTearDown(controller.dispose);

    await _waitUntilSettled(controller);

    expect(callbackCalls, hasLength(1));
    expect(callbackCalls.single.$1, '660');
    expect(callbackCalls.single.$2, same(weather));
    callbackRelease.complete();
  });

  test('Ok(null) realtime weather does not invoke the callback', () async {
    final repository = _FakeWeatherRepository(
      onRealtime: (_, _) async => const Ok(null),
    );
    final regions = _savedRegions(['660'])..select(2);
    addTearDown(regions.dispose);
    var callbackCount = 0;
    final controller = HomeWeatherController(
      repository,
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeLoaded: (_, _) async {
        callbackCount += 1;
      },
    );
    addTearDown(controller.dispose);

    await _waitUntilSettled(controller);

    expect(callbackCount, 0);
  });

  test('realtime failure does not invoke the callback', () async {
    final repository = _FakeWeatherRepository(
      onRealtime: (_, _) async => const Err(NetworkFailure('offline')),
    );
    final regions = _savedRegions(['660'])..select(2);
    addTearDown(regions.dispose);
    var callbackCount = 0;
    final controller = HomeWeatherController(
      repository,
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeLoaded: (_, _) async {
        callbackCount += 1;
      },
    );
    addTearDown(controller.dispose);

    await _waitUntilSettled(controller);

    expect(callbackCount, 0);
  });

  test('superseded realtime response does not invoke the callback', () async {
    final regionAResult = Completer<Result<WeatherRealtime?>>();
    final regionBResult = Completer<Result<WeatherRealtime?>>();
    final repository = _FakeWeatherRepository(
      onRealtime: (latitude, _) => switch (latitude) {
        24.18 => regionAResult.future,
        25.04 => regionBResult.future,
        _ => throw StateError('Unexpected latitude: $latitude'),
      },
    );
    final regions = _savedRegions(['660', '100'])..select(2);
    addTearDown(regions.dispose);
    final callbackRegions = <String>[];
    final controller = HomeWeatherController(
      repository,
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeLoaded: (regionCode, _) async {
        callbackRegions.add(regionCode);
      },
    );
    addTearDown(controller.dispose);

    regions.select(3);
    final settled = _waitUntilSettled(controller);
    regionAResult.complete(Ok(_weather()));
    regionBResult.complete(const Ok(null));
    await settled;

    expect(regions.selectedCode, '100');
    expect(callbackRegions, isEmpty);
  });
}

final _directory = TownDirectory.fromJson({
  '660': {
    'city': '臺中',
    'town': '西屯',
    'lat': 24.18,
    'lng': 120.64,
    'cityLevel': '市',
    'townLevel': '區',
  },
  '100': {
    'city': '臺北',
    'town': '中正',
    'lat': 25.04,
    'lng': 121.52,
    'cityLevel': '市',
    'townLevel': '區',
  },
});

RegionStore _savedRegions(List<String> codes) =>
    RegionStore(SettingsStore.inMemory({'home.savedRegionCodes': codes}));

Future<void> _waitUntilSettled(HomeWeatherController controller) async {
  if (!controller.loading) return;

  final settled = Completer<void>();
  void listener() {
    if (!controller.loading && !settled.isCompleted) settled.complete();
  }

  controller.addListener(listener);
  await settled.future;
  controller.removeListener(listener);
}

WeatherRealtime _weather() => WeatherRealtime(
  id: 'C0X160',
  station: const WeatherRealtimeStation(
    name: '西屯',
    latitude: 24.18,
    longitude: 120.64,
    altitude: 85,
    distance: 1.2,
  ),
  time: 1789398000,
  data: const WeatherRealtimeData(
    weather: '多雲',
    weatherCode: 200,
    temperature: 28.4,
    humidity: 76,
    rain: 0,
    wind: WeatherWind(direction: '北', speed: 1.5, beaufort: 1),
    gust: WeatherWind(speed: 3, beaufort: 2),
  ),
);

final class _FakeWeatherRepository implements MeteorWeatherRepository {
  const _FakeWeatherRepository({required this.onRealtime});

  final Future<Result<WeatherRealtime?>> Function(double, double) onRealtime;

  @override
  Future<Result<WeatherRealtime?>> realtime(
    double latitude,
    double longitude,
  ) => onRealtime(latitude, longitude);

  @override
  Future<Result<WeatherForecast>> forecast(String code) async =>
      Ok(WeatherForecast(updateTime: 0, forecast: const []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeHourTrendRepository implements RainHourTrendRepository {
  const _FakeHourTrendRepository();

  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async =>
      Ok(RainHourTrend(startSecond: 0, mm: List.filled(60, 0)));
}
