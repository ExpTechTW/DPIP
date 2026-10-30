/// The ranking page is how a station becomes a map focus. An error that looks
/// empty, or a tap that never hands the station across, would rank weather
/// the user cannot open.
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/rain_trend.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:dpip/features/weather/domain/weather_ranking.dart';
import 'package:dpip/features/weather/presentation/pages/weather_ranking_page.dart';
import 'package:dpip/features/weather/presentation/widgets/ranking_time_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const Size _tall = Size(900, 1600);

const _down = NetworkFailure('down');

WeatherStation _station(String town) => WeatherStation(
  name: town,
  county: '臺北市',
  town: town,
  altitude: 10,
  latitude: 25.0,
  longitude: 121.5,
);

WeatherObservation _obs(String id) => WeatherObservation(
  id: id,
  weatherCode: 100,
  temperature: id == 'A' ? 32.4 : 18,
  humidity: id == 'A' ? 80 : 40,
  pressure: id == 'A' ? 1013.2 : 1000,
  windDirection: 90,
  windSpeed: id == 'A' ? 5.5 : 0,
  gustSpeed: id == 'A' ? 12 : 1,
  gustDirection: 180,
  gustTime: 1_700_000_000,
  high: id == 'A' ? 33 : 20,
  highTime: 1_700_000_100,
  low: id == 'A' ? 16 : 12,
  lowTime: 1_700_000_200,
);

RainObservation _rain(String id) => RainObservation(
  id: id,
  now: id == 'A' ? 12.5 : 4,
  min10: 1,
  hour1: 2,
  hour3: 3,
  hour6: 4,
  hour12: 5,
  hour24: 6,
  day2: 7,
  day3: 8,
);

class _Weather implements MeteorWeatherRepository {
  _Weather(
    this.stationsResult,
    this.latestResult, {
    this.historyResult = const Ok(<int>[]),
    Map<int, WeatherSnapshot>? past,
  }) : past = past ?? {};

  Result<Map<String, WeatherStation>> stationsResult;
  Result<WeatherSnapshot> latestResult;
  Result<List<int>> historyResult;
  final Map<int, WeatherSnapshot> past;
  Completer<void>? holdStations;
  bool explode = false;

  /// Every second the page actually asked the API for.
  final List<int> requested = [];

  @override
  Future<Result<Map<String, WeatherStation>>> stations() async {
    final hold = holdStations;
    if (hold != null) await hold.future;
    if (explode) throw StateError('stations exploded');
    return stationsResult;
  }

  @override
  Future<Result<WeatherSnapshot>> latest() async => latestResult;

  @override
  Future<Result<WeatherSnapshot>> at(int second) async {
    requested.add(second);
    final snapshot = past[second];
    if (snapshot != null) return Ok(snapshot);
    return Err<WeatherSnapshot>(const NetworkFailure('no such snapshot'));
  }

  @override
  Future<Result<WeatherForecast>> forecast(String code) =>
      throw UnimplementedError();

  @override
  Future<Result<List<int>>> history() async => historyResult;

  @override
  Future<Result<WeatherRealtime?>> realtime(
    double latitude,
    double longitude,
  ) => throw UnimplementedError();

  @override
  Future<Result<WeatherTrend>> trend(String id, {String range = '24h'}) =>
      throw UnimplementedError();
}

class _Rain implements MeteorRainRepository {
  _Rain(
    this.stationsResult,
    this.latestResult, {
    this.historyResult = const Ok(<int>[]),
    Map<int, RainSnapshot>? past,
  }) : past = past ?? {};

  Result<Map<String, WeatherStation>> stationsResult;
  Result<RainSnapshot> latestResult;
  Result<List<int>> historyResult;
  final Map<int, RainSnapshot> past;

  /// Every second the page actually asked the API for.
  final List<int> requested = [];

  @override
  Future<Result<Map<String, WeatherStation>>> stations() async =>
      stationsResult;

  @override
  Future<Result<RainSnapshot>> latest() async => latestResult;

  @override
  Future<Result<RainSnapshot>> at(int second) async {
    requested.add(second);
    final snapshot = past[second];
    if (snapshot != null) return Ok(snapshot);
    return Err<RainSnapshot>(const NetworkFailure('no such snapshot'));
  }

  @override
  Future<Result<List<int>>> history() async => historyResult;

  @override
  Future<Result<RainTrend>> trend(String id, {String range = '24h'}) =>
      throw UnimplementedError();
}

/// The newest snapshot the fakes serve, and the one an hour before it — the
/// second is what the picker hands to `at()`.
const int _now = 1_700_000_000;
const int _earlier = _now - 3600;

Result<Map<String, WeatherStation>> _catalogue() =>
    Ok({'A': _station('大同區'), 'B': _station('信義區')});

Result<WeatherSnapshot> _weatherSnap() =>
    Ok(WeatherSnapshot(time: _now, stations: [_obs('A'), _obs('B')]));

Result<RainSnapshot> _rainSnap() =>
    Ok(RainSnapshot(time: _now, stations: [_rain('A'), _rain('B')]));

/// The snapshot an hour back: different readings, so a list that ignored the
/// picked time cannot accidentally look right.
WeatherObservation _pastObs(String id) => WeatherObservation(
  id: id,
  weatherCode: 100,
  temperature: id == 'A' ? 41.5 : 9,
  humidity: 55,
  pressure: 990,
  windSpeed: 2,
  gustSpeed: 3,
  high: 42,
  low: 39,
  highTime: _earlier + 600,
  lowTime: _earlier,
);

Result<WeatherSnapshot> _pastWeatherSnap() => Ok(
  WeatherSnapshot(time: _earlier, stations: [_pastObs('A'), _pastObs('B')]),
);

/// Rain an hour back: `now` accumulation 21 mm, so the rain tab's default
/// interval proves it ranked the historical snapshot.
RainObservation _pastRain(String id) => RainObservation(
  id: id,
  now: id == 'A' ? 21 : 2,
  min10: 1,
  hour1: 2,
  hour3: 3,
  hour6: 4,
  hour12: 5,
  hour24: 6,
  day2: 7,
  day3: 8,
);

Result<RainSnapshot> _pastRainSnap() => Ok(
  RainSnapshot(time: _earlier, stations: [_pastRain('A'), _pastRain('B')]),
);

Future<MapStationHandoff> _pump(
  WidgetTester tester, {
  required MeteorWeatherRepository weather,
  required MeteorRainRepository rain,
  WeatherRankingTab tab = WeatherRankingTab.rain,
  TempRankMetric tempMetric = TempRankMetric.current,
}) async {
  tester.view.physicalSize = _tall;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final handoff = MapStationHandoff();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            WeatherRankingPage(initialTab: tab, initialTempMetric: tempMetric),
      ),
      GoRoute(
        name: AppRoutes.map,
        path: '/map',
        builder: (_, _) => const Scaffold(body: Text('map-tab')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<MeteorWeatherRepository>.value(value: weather),
        Provider<MeteorRainRepository>.value(value: rain),
        ChangeNotifierProvider.value(value: handoff),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return handoff;
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

void main() {
  test('query values round-trip through parse', () {
    for (final tab in WeatherRankingTab.values) {
      expect(WeatherRankingTab.parse(tab.query), tab);
      expect(tab.icon, isNotNull);
      expect(tab.mapLayerId, isNotEmpty);
    }
    expect(WeatherRankingTab.parse('temp'), WeatherRankingTab.temperature);
    expect(WeatherRankingTab.parse('pres'), WeatherRankingTab.pressure);
    expect(WeatherRankingTab.parse('rh'), WeatherRankingTab.humidity);
    expect(WeatherRankingTab.parse(null), WeatherRankingTab.rain);
    expect(WeatherRankingTab.parse('nope'), WeatherRankingTab.rain);
  });

  test(
    'the old daily-extremes tab is now a chip inside the temperature tab',
    () {
      // The value still has to resolve, so a link shared before the merge does
      // not land on rain.
      expect(
        WeatherRankingTab.parse('tempExtremes'),
        WeatherRankingTab.temperature,
      );
      expect(TempRankMetric.parse('tempExtremes'), TempRankMetric.high);
      expect(TempRankMetric.parse('high'), TempRankMetric.high);
      expect(TempRankMetric.parse('low'), TempRankMetric.low);
      expect(TempRankMetric.parse('range'), TempRankMetric.range);
      expect(TempRankMetric.parse('temperature'), TempRankMetric.current);
      expect(TempRankMetric.parse(null), TempRankMetric.current);
    },
  );

  testWidgets('lists rain, switches intervals, and opens the station', (
    tester,
  ) async {
    final handoff = await _pump(
      tester,
      weather: _Weather(_catalogue(), _weatherSnap()),
      rain: _Rain(_catalogue(), _rainSnap()),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.weatherRankingTitle), findsOneWidget);
    expect(find.text('12.5 mm'), findsOneWidget);
    expect(find.text('4 mm'), findsOneWidget);

    await tester.ensureVisible(find.text(l10n.rainInterval3d));
    await tester.tap(find.text(l10n.rainInterval3d));
    await tester.pumpAndSettle();
    expect(find.text('8 mm'), findsWidgets);

    await tester.tap(find.text('大同區').first);
    await tester.pumpAndSettle();
    expect(find.text('map-tab'), findsOneWidget);
    final pending = handoff.takePending();
    expect(pending?.stationId, 'A');
    expect(pending?.layerId, 'rain');
  });

  testWidgets('empty catalogues show the empty ranking', (tester) async {
    await _pump(
      tester,
      weather: _Weather(
        const Ok({}),
        const Ok(WeatherSnapshot(time: 1, stations: [])),
      ),
      rain: _Rain(const Ok({}), const Ok(RainSnapshot(time: 1, stations: []))),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.weatherRankingEmpty), findsOneWidget);
  });

  testWidgets('a failed load offers retry and then the list', (tester) async {
    final weather = _Weather(const Err(_down), _weatherSnap());
    final rain = _Rain(_catalogue(), _rainSnap());
    await _pump(tester, weather: weather, rain: rain);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.commonFetchFailed), findsOneWidget);

    await _pump(
      tester,
      weather: _Weather(_catalogue(), const Err(_down)),
      rain: rain,
    );
    expect(find.text(l10n.commonFetchFailed), findsOneWidget);

    await _pump(
      tester,
      weather: _Weather(_catalogue(), _weatherSnap()),
      rain: _Rain(const Err(_down), _rainSnap()),
    );
    expect(find.text(l10n.commonFetchFailed), findsOneWidget);

    await _pump(
      tester,
      weather: _Weather(_catalogue(), _weatherSnap()),
      rain: _Rain(_catalogue(), const Err(_down)),
    );
    expect(find.text(l10n.commonFetchFailed), findsOneWidget);
  });

  testWidgets('metric tabs sort, merge, and scroll', (tester) async {
    await _pump(
      tester,
      weather: _Weather(_catalogue(), _weatherSnap()),
      rain: _Rain(_catalogue(), _rainSnap()),
      tab: WeatherRankingTab.temperature,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text('32.4 °C'), findsOneWidget);

    // The four figure chips push the sort chips past the screen edge.
    await tester.drag(
      find.text(l10n.weatherRankingCurrent).hitTestable(),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.reportFilterOrderAsc).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('18.0 °C'), findsOneWidget);
    await tester.tap(find.text(l10n.reportFilterOrderDesc).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('32.4 °C'), findsOneWidget);

    // Back to the figure chips.
    await tester.drag(
      find.text(l10n.reportFilterOrderDesc).hitTestable(),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();

    await _openTab(tester, l10n.weatherRankingWind);
    expect(find.byIcon(Icons.navigation), findsWidgets);

    await _openTab(tester, l10n.weatherRankingGust);
    expect(find.textContaining('m/s'), findsWidgets);

    await _openTab(tester, l10n.mapLayerHumidity);
    expect(find.text('80 %'), findsOneWidget);

    await tester.tap(find.text(l10n.weatherRankingMergeTown));
    await tester.pumpAndSettle();

    await _openTab(tester, l10n.mapLayerPressure);
    expect(find.text('1013.2 hPa'), findsOneWidget);

    // The daily extremes are chips on the temperature tab now, not a tab.
    await _openTab(tester, l10n.mapLayerTemperature);
    expect(find.textContaining('°C'), findsWidgets);
    expect(find.text(l10n.weatherRankingTempExtremes), findsNothing);

    await tester.tap(find.text(l10n.weatherRankingExtremeHigh).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('33.0 °C'), findsOneWidget);

    await tester.tap(find.text(l10n.weatherRankingExtremeLow).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('16.0 °C'), findsOneWidget);

    await tester.tap(find.text(l10n.weatherRankingExtremeRange).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('17.0 °C'), findsOneWidget);

    await tester.tap(find.text(l10n.weatherRankingCurrent).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('32.4 °C'), findsOneWidget);

    // Merge chips sit at the far end of the same strip.
    await tester.drag(
      find.text(l10n.weatherRankingCurrent).hitTestable(),
      const Offset(-800, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.weatherRankingMergeTown).hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.weatherRankingMergeCounty).hitTestable());
    await tester.pumpAndSettle();
  });

  testWidgets('a reload keeps the list up until the next snapshot arrives', (
    tester,
  ) async {
    final weather = _Weather(_catalogue(), _weatherSnap());
    await _pump(
      tester,
      weather: weather,
      rain: _Rain(_catalogue(), _rainSnap()),
    );
    expect(find.text('12.5 mm'), findsOneWidget);

    weather.holdStations = Completer<void>();
    final pending = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator).first)
        .onRefresh();
    await tester.pump();
    expect(find.text('12.5 mm'), findsOneWidget);

    weather.holdStations!.complete();
    await pending;
    await tester.pumpAndSettle();
    expect(find.text('12.5 mm'), findsOneWidget);
  });

  testWidgets('a thrown load is the same retry surface as a failed result', (
    tester,
  ) async {
    final weather = _Weather(_catalogue(), _weatherSnap())..explode = true;
    await _pump(
      tester,
      weather: weather,
      rain: _Rain(_catalogue(), _rainSnap()),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.commonFetchFailed), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tabs with nothing to rank say so instead of an empty column', (
    tester,
  ) async {
    WeatherObservation blank(String id) =>
        WeatherObservation(id: id, weatherCode: 100, temperature: 20);
    await _pump(
      tester,
      weather: _Weather(
        _catalogue(),
        Ok(
          WeatherSnapshot(
            time: 1_700_000_000,
            stations: [blank('A'), blank('B')],
          ),
        ),
      ),
      rain: _Rain(_catalogue(), _rainSnap()),
      tab: WeatherRankingTab.humidity,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.weatherRankingEmpty), findsOneWidget);

    await _openTab(tester, l10n.mapLayerTemperature);
    expect(find.text('20.0 °C'), findsWidgets);

    // The stations have a reading but no recorded extremes, so the chip that
    // needs them is the empty one.
    await tester.tap(find.text(l10n.weatherRankingExtremeHigh).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text(l10n.weatherRankingEmpty), findsOneWidget);
  });

  testWidgets('picking a past time re-ranks the list at that snapshot', (
    tester,
  ) async {
    final weather = _Weather(
      _catalogue(),
      _weatherSnap(),
      historyResult: const Ok(<int>[_earlier, _now]),
      past: {_earlier: _pastWeatherSnap().valueOrNull!},
    );
    final rain = _Rain(
      _catalogue(),
      _rainSnap(),
      historyResult: const Ok(<int>[_earlier, _now]),
      past: {_earlier: _pastRainSnap().valueOrNull!},
    );
    await _pump(tester, weather: weather, rain: rain);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text('12.5 mm'), findsOneWidget);

    await tester.tap(find.text(l10n.weatherRankingLatest));
    await tester.pumpAndSettle();
    expect(find.text(l10n.weatherRankingPickTime), findsOneWidget);

    await tester.tap(find.text(rankingTimeLabel(_earlier)));
    await tester.pumpAndSettle();

    // One `at()` per dataset, both for the chosen second.
    expect(weather.requested, [_earlier]);
    expect(rain.requested, [_earlier]);
    expect(find.text('21 mm'), findsOneWidget);
    expect(find.text('12.5 mm'), findsNothing);
    // The bar says where the list is instead of claiming to be live.
    expect(find.text(l10n.weatherRankingLatest), findsNothing);
    expect(find.text(rankingTimeLabel(_earlier)), findsOneWidget);
  });

  testWidgets('the picker walks back to the newest snapshot', (tester) async {
    final weather = _Weather(
      _catalogue(),
      _weatherSnap(),
      historyResult: const Ok(<int>[_earlier, _now]),
      past: {_earlier: _pastWeatherSnap().valueOrNull!},
    );
    final rain = _Rain(
      _catalogue(),
      _rainSnap(),
      historyResult: const Ok(<int>[_earlier, _now]),
      past: {_earlier: _pastRainSnap().valueOrNull!},
    );
    await _pump(tester, weather: weather, rain: rain);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.weatherRankingLatest));
    await tester.pumpAndSettle();
    await tester.tap(find.text(rankingTimeLabel(_earlier)));
    await tester.pumpAndSettle();
    expect(find.text('21 mm'), findsOneWidget);

    await tester.tap(find.text(rankingTimeLabel(_earlier)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.weatherRankingLatest).last);
    await tester.pumpAndSettle();

    expect(find.text('12.5 mm'), findsOneWidget);
    expect(weather.requested, [_earlier]);
  });

  testWidgets('rain lands on its own nearest snapshot, not the weather one', (
    tester,
  ) async {
    final rainSecond = _earlier - 600;
    final weather = _Weather(
      _catalogue(),
      _weatherSnap(),
      historyResult: const Ok(<int>[_earlier, _now]),
      past: {_earlier: _pastWeatherSnap().valueOrNull!},
    );
    final rain = _Rain(
      _catalogue(),
      _rainSnap(),
      // The rain history runs on finer steps than the weather one, with no
      // snapshot on the picked second. The one just after is as close as the
      // one just before, but it is from after the time the user asked for.
      historyResult: const Ok(<int>[_earlier - 600, _earlier + 600, _now]),
      past: {rainSecond: _pastRainSnap().valueOrNull!},
    );
    await _pump(tester, weather: weather, rain: rain);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.weatherRankingLatest));
    await tester.pumpAndSettle();
    await tester.tap(find.text(rankingTimeLabel(_earlier)));
    await tester.pumpAndSettle();

    expect(weather.requested, [_earlier]);
    expect(rain.requested, [rainSecond]);
    expect(find.text('21 mm'), findsOneWidget);
  });

  testWidgets('a time older than the rain history shows no rain, not a later '
      'snapshot', (tester) async {
    final weather = _Weather(
      _catalogue(),
      _weatherSnap(),
      historyResult: const Ok(<int>[_earlier, _now]),
      past: {_earlier: _pastWeatherSnap().valueOrNull!},
    );
    final rain = _Rain(
      _catalogue(),
      _rainSnap(),
      // Rain keeps less history than weather: its oldest snapshot is ten
      // minutes after the hour the user is about to pick.
      historyResult: const Ok(<int>[_earlier + 600, _now]),
      past: {_earlier + 600: _pastRainSnap().valueOrNull!},
    );
    await _pump(tester, weather: weather, rain: rain);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.weatherRankingLatest));
    await tester.pumpAndSettle();
    await tester.tap(find.text(rankingTimeLabel(_earlier)));
    await tester.pumpAndSettle();

    expect(find.text(rankingTimeLabel(_earlier)), findsOneWidget);
    expect(rain.requested, isEmpty, reason: 'nothing at or before the pick');
    expect(find.text('21 mm'), findsNothing, reason: 'a later snapshot');
    expect(find.text('12.5 mm'), findsNothing, reason: 'the newest snapshot');
  });

  testWidgets('no rain history does not pass the newest rain off as the '
      'picked time', (tester) async {
    final weather = _Weather(
      _catalogue(),
      _weatherSnap(),
      historyResult: const Ok(<int>[_earlier, _now]),
      past: {_earlier: _pastWeatherSnap().valueOrNull!},
    );
    final rain = _Rain(
      _catalogue(),
      _rainSnap(),
      historyResult: Err<List<int>>(const NetworkFailure('offline')),
    );
    await _pump(tester, weather: weather, rain: rain);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text('12.5 mm'), findsOneWidget);

    await tester.tap(find.text(l10n.weatherRankingLatest));
    await tester.pumpAndSettle();
    await tester.tap(find.text(rankingTimeLabel(_earlier)));
    await tester.pumpAndSettle();

    expect(find.text(rankingTimeLabel(_earlier)), findsOneWidget);
    expect(find.text('12.5 mm'), findsNothing, reason: 'the newest snapshot');
  });

  testWidgets('no history means no picker, and the newest list still works', (
    tester,
  ) async {
    await _pump(
      tester,
      weather: _Weather(_catalogue(), _weatherSnap()),
      rain: _Rain(_catalogue(), _rainSnap()),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byIcon(Icons.schedule), findsNothing);
    expect(find.text(l10n.weatherRankingLatest), findsNothing);
    expect(find.text('12.5 mm'), findsOneWidget);
  });
}
