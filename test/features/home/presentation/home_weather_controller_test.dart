/// The home sheet follows the selected township. A nationwide selection that
/// still shows the previous town, a failed forecast that looks like "no rain",
/// or a response that arrives after the user has already switched, would put
/// the wrong weather on the card.
library;

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
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial valid-region sync invalidates persisted realtime', () async {
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
    expect(invalidationCount, 1);
  });

  test('initial null-region sync invalidates persisted realtime', () {
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
    expect(invalidationCount, 1);
  });

  test(
    'initial valid-region sync clears before publishing fresh data',
    () async {
      final regions = _savedRegions(['660'])..select(2);
      addTearDown(regions.dispose);
      final events = <String>[];
      final controller = HomeWeatherController(
        _FakeWeatherRepository(onRealtime: (_, _) async => Ok(_weather())),
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

      expect(events, ['invalidated', 'loaded:660']);
    },
  );

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
    invalidationCount = 0;

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
    invalidationCount = 0;

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
    invalidationCount = 0;

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
      invalidationCount = 0;

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

  test('latest same-region request wins across all weather state', () async {
    final firstRealtime = Completer<Result<WeatherRealtime?>>();
    final secondRealtime = Completer<Result<WeatherRealtime?>>();
    var realtimeCall = 0;
    var forecastCall = 0;
    var hourTrendCall = 0;
    final oldWeather = _weather(id: 'old', temperature: 20);
    final newWeather = _weather(id: 'new', temperature: 30);
    final newForecast = WeatherForecast(updateTime: 2, forecast: const []);
    final newHourTrend = RainHourTrend(startSecond: 2, mm: List.filled(60, 2));
    final repository = _FakeWeatherRepository(
      onRealtime: (_, _) {
        final call = realtimeCall++;
        return call == 0 ? firstRealtime.future : secondRealtime.future;
      },
      onForecast: (_) async {
        final call = forecastCall++;
        return call == 0
            ? const Err(NetworkFailure('old forecast failure'))
            : Ok(newForecast);
      },
    );
    final hourTrendRepository = _FakeHourTrendRepository(
      onHourTrend: (_) async {
        final call = hourTrendCall++;
        return call == 0
            ? const Err(NetworkFailure('old trend failure'))
            : Ok(newHourTrend);
      },
    );
    final regions = _savedRegions(['660'])..select(2);
    addTearDown(regions.dispose);
    final callbackWeather = <WeatherRealtime>[];
    final controller = HomeWeatherController(
      repository,
      hourTrendRepository,
      regions,
      _directory,
      onRealtimeLoaded: (_, weather) async {
        callbackWeather.add(weather);
      },
    );
    addTearDown(controller.dispose);

    final refresh = controller.refresh();
    secondRealtime.complete(Ok(newWeather));
    await refresh;

    expect(controller.weather, same(newWeather));
    expect(controller.forecast, same(newForecast));
    expect(controller.hourTrend, same(newHourTrend));
    expect(controller.failure, isNull);
    expect(controller.forecastFailure, isNull);
    expect(controller.hourTrendFailure, isNull);
    expect(controller.loading, isFalse);
    expect(callbackWeather, hasLength(1));
    expect(callbackWeather.single, same(newWeather));

    firstRealtime.complete(Ok(oldWeather));
    await pumpEventQueue();

    expect(controller.weather, same(newWeather));
    expect(controller.forecast, same(newForecast));
    expect(controller.hourTrend, same(newHourTrend));
    expect(controller.failure, isNull);
    expect(controller.forecastFailure, isNull);
    expect(controller.hourTrendFailure, isNull);
    expect(controller.loading, isFalse);
    expect(callbackWeather, hasLength(1));
    expect(callbackWeather.single, same(newWeather));
  });

  test('A1 cannot overwrite or publish after B then A2', () async {
    final firstA = Completer<Result<WeatherRealtime?>>();
    final secondA = Completer<Result<WeatherRealtime?>>();
    var aCall = 0;
    final repository = _FakeWeatherRepository(
      onRealtime: (latitude, _) {
        if (latitude == 25.04) return Future.value(const Ok(null));
        if (latitude != 24.18) {
          throw StateError('Unexpected latitude: $latitude');
        }

        final call = aCall++;
        return call == 0 ? firstA.future : secondA.future;
      },
    );
    final regions = _savedRegions(['660', '100'])..select(2);
    addTearDown(regions.dispose);
    final callbackWeather = <WeatherRealtime>[];
    final controller = HomeWeatherController(
      repository,
      const _FakeHourTrendRepository(),
      regions,
      _directory,
      onRealtimeLoaded: (_, weather) async {
        callbackWeather.add(weather);
      },
    );
    addTearDown(controller.dispose);

    regions.select(3);
    regions.select(2);
    final newWeather = _weather(id: 'A2', temperature: 30);
    secondA.complete(Ok(newWeather));
    await _waitUntilSettled(controller);

    expect(controller.weather, same(newWeather));
    expect(callbackWeather, hasLength(1));
    expect(callbackWeather.single, same(newWeather));

    firstA.complete(Ok(_weather(id: 'A1', temperature: 20)));
    await pumpEventQueue();

    expect(controller.weather, same(newWeather));
    expect(controller.loading, isFalse);
    expect(callbackWeather, hasLength(1));
    expect(callbackWeather.single, same(newWeather));
  });

  test(
    'late valid-region response cannot mutate or publish after Nationwide',
    () async {
      final realtime = Completer<Result<WeatherRealtime?>>();
      final oldForecast = WeatherForecast(updateTime: 1, forecast: const []);
      final oldHourTrend = RainHourTrend(
        startSecond: 1,
        mm: List.filled(60, 1),
      );
      final repository = _FakeWeatherRepository(
        onRealtime: (_, _) => realtime.future,
        onForecast: (_) async => Ok(oldForecast),
      );
      final regions = _savedRegions(['660'])..select(2);
      addTearDown(regions.dispose);
      final callbackWeather = <WeatherRealtime>[];
      final controller = HomeWeatherController(
        repository,
        _FakeHourTrendRepository(onHourTrend: (_) async => Ok(oldHourTrend)),
        regions,
        _directory,
        onRealtimeLoaded: (_, weather) async {
          callbackWeather.add(weather);
        },
      );
      addTearDown(controller.dispose);

      expect(controller.loading, isTrue);
      regions.select(0);

      expect(controller.areaCode, isNull);
      expect(controller.weather, isNull);
      expect(controller.weatherCode, isNull);
      expect(controller.forecast, isNull);
      expect(controller.hourTrend, isNull);
      expect(controller.failure, isNull);
      expect(controller.forecastFailure, isNull);
      expect(controller.hourTrendFailure, isNull);
      expect(controller.loading, isFalse);

      var lateNotificationCount = 0;
      controller.addListener(() {
        lateNotificationCount += 1;
      });
      realtime.complete(Ok(_weather(id: 'late')));
      await pumpEventQueue();

      expect(controller.weather, isNull);
      expect(controller.weatherCode, isNull);
      expect(controller.forecast, isNull);
      expect(controller.hourTrend, isNull);
      expect(controller.failure, isNull);
      expect(controller.forecastFailure, isNull);
      expect(controller.hourTrendFailure, isNull);
      expect(controller.loading, isFalse);
      expect(callbackWeather, isEmpty);
      expect(lateNotificationCount, 0);
    },
  );

  test('late response cannot mutate or publish after dispose', () async {
    final realtime = Completer<Result<WeatherRealtime?>>();
    final repository = _FakeWeatherRepository(
      onRealtime: (_, _) => realtime.future,
      onForecast: (_) async =>
          Ok(WeatherForecast(updateTime: 1, forecast: const [])),
    );
    final regions = _savedRegions(['660'])..select(2);
    addTearDown(regions.dispose);
    final callbackWeather = <WeatherRealtime>[];
    final controller = HomeWeatherController(
      repository,
      _FakeHourTrendRepository(
        onHourTrend: (_) async =>
            Ok(RainHourTrend(startSecond: 1, mm: List.filled(60, 1))),
      ),
      regions,
      _directory,
      onRealtimeLoaded: (_, weather) async {
        callbackWeather.add(weather);
      },
    );

    expect(controller.loading, isTrue);
    controller.dispose();

    realtime.complete(Ok(_weather(id: 'late')));
    await pumpEventQueue();

    expect(controller.weather, isNull);
    expect(controller.weatherCode, isNull);
    expect(controller.forecast, isNull);
    expect(controller.hourTrend, isNull);
    expect(controller.failure, isNull);
    expect(controller.forecastFailure, isNull);
    expect(controller.hourTrendFailure, isNull);
    expect(controller.loading, isTrue);
    expect(callbackWeather, isEmpty);
  });

  test('nationwide and a missing GPS town clear every feed', () async {
    final regions = RegionStore(SettingsStore.inMemory())..select(0);
    final weather = _Weather(Ok(_realtime()), Ok(_forecast()));
    final controller = HomeWeatherController(
      weather,
      _Trend(Ok(_trend())),
      regions,
      _towns(),
    );
    await pumpEventQueue();
    expect(controller.areaCode, isNull);
    expect(controller.weather, isNull);
    expect(controller.forecast, isNull);
    expect(weather.realtimeCalls, 0);

    regions.setCurrentCode(null);
    await controller.refresh();
    expect(controller.loading, isFalse);
    controller.dispose();
  });

  test('a township load keeps the reading, and a failure clears it', () async {
    final regions = RegionStore(SettingsStore.inMemory())
      ..addSaved(_code)
      ..select(2);
    final weather = _Weather(Ok(_realtime()), Ok(_forecast()));
    final trends = _Trend(Ok(_trend()));
    final controller = HomeWeatherController(
      weather,
      trends,
      regions,
      _towns(),
      gpsFix: () async => (lat: 25.033, lng: 121.565),
    );
    await pumpEventQueue();
    expect(controller.loading, isFalse);
    expect(controller.weatherCode, _code);
    expect(controller.forecast?.forecast, isNotEmpty);
    expect(controller.hourTrend?.mm, hasLength(60));
    expect(controller.failure, isNull);

    weather.realtimeResult = const Err(NetworkFailure('down'));
    weather.forecastResult = const Err(DecodeFailure('bad'));
    trends.result = const Err(TimeoutFailure('slow'));
    await controller.refresh();
    expect(controller.failure, isA<NetworkFailure>());
    expect(controller.forecastFailure, isA<DecodeFailure>());
    expect(controller.hourTrendFailure, isA<TimeoutFailure>());
    expect(controller.weather, isNull);
    expect(controller.forecast, isNull);
    expect(controller.hourTrend, isNull);
    controller.dispose();
  });

  test('a response for the previous town is dropped', () async {
    final regions = RegionStore(SettingsStore.inMemory())
      ..addSaved(_code)
      ..select(2);
    final gate = Completer<void>();
    final weather = _Weather(Ok(_realtime()), Ok(_forecast()))..gate = gate;
    final trends = _Trend(Ok(_trend()))..gate = gate;
    final controller = HomeWeatherController(
      weather,
      trends,
      regions,
      _towns(),
    );
    expect(controller.loading, isTrue);
    regions.select(0);
    gate.complete();
    await pumpEventQueue();
    expect(controller.areaCode, isNull);
    expect(controller.weather, isNull);
    expect(controller.forecast, isNull);
    controller.dispose();
  });

  test('a null realtime reading does not pretend to be the town', () async {
    final regions = RegionStore(SettingsStore.inMemory())
      ..addSaved(_code)
      ..select(2);
    final controller = HomeWeatherController(
      _Weather(const Ok(null), Ok(_forecast())),
      _Trend(Ok(_trend())),
      regions,
      _towns(),
      gpsFix: () async => null,
    );
    await pumpEventQueue();
    expect(controller.weather, isNull);
    expect(controller.weatherCode, isNull);
    expect(controller.forecast, isNotNull);
    controller.dispose();
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

WeatherRealtime _weather({String id = 'C0X160', double temperature = 28.4}) =>
    WeatherRealtime(
      id: id,
      station: const WeatherRealtimeStation(
        name: '西屯',
        latitude: 24.18,
        longitude: 120.64,
        altitude: 85,
        distance: 1.2,
      ),
      time: 1789398000,
      data: WeatherRealtimeData(
        weather: '多雲',
        weatherCode: 200,
        temperature: temperature,
        humidity: 76,
        rain: 0,
        wind: WeatherWind(direction: '北', speed: 1.5, beaufort: 1),
        gust: WeatherWind(speed: 3, beaufort: 2),
      ),
    );

final class _FakeWeatherRepository implements MeteorWeatherRepository {
  const _FakeWeatherRepository({required this.onRealtime, this.onForecast});

  final Future<Result<WeatherRealtime?>> Function(double, double) onRealtime;
  final Future<Result<WeatherForecast>> Function(String)? onForecast;

  @override
  Future<Result<WeatherRealtime?>> realtime(
    double latitude,
    double longitude,
  ) => onRealtime(latitude, longitude);

  @override
  Future<Result<WeatherForecast>> forecast(String code) async {
    final callback = onForecast;
    return callback == null
        ? Ok(WeatherForecast(updateTime: 0, forecast: const []))
        : callback(code);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeHourTrendRepository implements RainHourTrendRepository {
  const _FakeHourTrendRepository({this.onHourTrend});

  final Future<Result<RainHourTrend>> Function(String)? onHourTrend;

  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async {
    final callback = onHourTrend;
    return callback == null
        ? Ok(RainHourTrend(startSecond: 0, mm: List.filled(60, 0)))
        : callback(code);
  }
}

const _code = '6300100';

TownDirectory _towns() => TownDirectory.fromJson({
  _code: {
    'city': '臺北',
    'town': '中正',
    'lat': 25.0,
    'lng': 121.5,
    'cityLevel': '市',
    'townLevel': '區',
  },
});

WeatherForecast _forecast() => WeatherForecast(
  updateTime: 1,
  forecast: [
    WeatherForecastPoint(
      time: '14:00',
      temperature: 28,
      apparentTemp: 30,
      humidity: 70,
      weather: '多雲',
      weatherCode: 200,
      pop: 20,
      wind: const ForecastWind(direction: 'NE', speed: 2, beaufort: 2),
    ),
  ],
);

WeatherRealtime _realtime() => WeatherRealtime(
  id: 'C0X160',
  station: const WeatherRealtimeStation(
    name: 'Taipei',
    latitude: 25,
    longitude: 121.5,
    altitude: 8,
    distance: 1.2,
  ),
  time: 1,
  data: const WeatherRealtimeData(
    weather: '多雲',
    weatherCode: 200,
    temperature: 28,
    rain: 0,
    wind: WeatherWind(speed: 1.5, beaufort: 1),
    gust: WeatherWind(),
  ),
);

RainHourTrend _trend() =>
    RainHourTrend(startSecond: 0, mm: List<double>.filled(60, 0));

class _Weather implements MeteorWeatherRepository {
  _Weather(this.realtimeResult, this.forecastResult);

  Result<WeatherRealtime?> realtimeResult;
  Result<WeatherForecast> forecastResult;
  Completer<void>? gate;
  int realtimeCalls = 0;

  Future<void> _wait() async {
    final gate = this.gate;
    if (gate != null) await gate.future;
  }

  @override
  Future<Result<WeatherRealtime?>> realtime(
    double latitude,
    double longitude,
  ) async {
    realtimeCalls++;
    await _wait();
    return realtimeResult;
  }

  @override
  Future<Result<WeatherForecast>> forecast(String code) async {
    await _wait();
    return forecastResult;
  }

  @override
  Future<Result<Map<String, WeatherStation>>> stations() async => const Ok({});

  @override
  Future<Result<WeatherSnapshot>> latest() async =>
      const Err(NetworkFailure('unused'));

  @override
  Future<Result<List<int>>> history() async => const Ok([]);

  @override
  Future<Result<WeatherSnapshot>> at(int second) async =>
      const Err(NetworkFailure('unused'));

  @override
  Future<Result<WeatherTrend>> trend(String id, {String range = '24h'}) async =>
      const Err(NetworkFailure('unused'));
}

class _Trend implements RainHourTrendRepository {
  _Trend(this.result);

  Result<RainHourTrend> result;
  Completer<void>? gate;

  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async {
    final gate = this.gate;
    if (gate != null) await gate.future;
    return result;
  }
}
