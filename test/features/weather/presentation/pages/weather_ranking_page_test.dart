/// The ranking page is how a station becomes a map focus. An error that looks
/// empty, or a tap that never hands the station across, would rank weather
/// the user cannot open.
library;

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
import 'package:dpip/features/weather/presentation/pages/weather_ranking_page.dart';
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
  _Weather(this.stationsResult, this.latestResult);

  Result<Map<String, WeatherStation>> stationsResult;
  Result<WeatherSnapshot> latestResult;

  @override
  Future<Result<Map<String, WeatherStation>>> stations() async =>
      stationsResult;

  @override
  Future<Result<WeatherSnapshot>> latest() async => latestResult;

  @override
  Future<Result<WeatherSnapshot>> at(int second) => throw UnimplementedError();

  @override
  Future<Result<WeatherForecast>> forecast(String code) =>
      throw UnimplementedError();

  @override
  Future<Result<List<int>>> history() => throw UnimplementedError();

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
  _Rain(this.stationsResult, this.latestResult);

  Result<Map<String, WeatherStation>> stationsResult;
  Result<RainSnapshot> latestResult;

  @override
  Future<Result<Map<String, WeatherStation>>> stations() async =>
      stationsResult;

  @override
  Future<Result<RainSnapshot>> latest() async => latestResult;

  @override
  Future<Result<RainSnapshot>> at(int second) => throw UnimplementedError();

  @override
  Future<Result<List<int>>> history() => throw UnimplementedError();

  @override
  Future<Result<RainTrend>> trend(String id, {String range = '24h'}) =>
      throw UnimplementedError();
}

Result<Map<String, WeatherStation>> _catalogue() =>
    Ok({'A': _station('大同區'), 'B': _station('信義區')});

Result<WeatherSnapshot> _weatherSnap() =>
    Ok(WeatherSnapshot(time: 1_700_000_000, stations: [_obs('A'), _obs('B')]));

Result<RainSnapshot> _rainSnap() =>
    Ok(RainSnapshot(time: 1_700_000_000, stations: [_rain('A'), _rain('B')]));

Future<MapStationHandoff> _pump(
  WidgetTester tester, {
  required MeteorWeatherRepository weather,
  required MeteorRainRepository rain,
  WeatherRankingTab tab = WeatherRankingTab.rain,
}) async {
  tester.view.physicalSize = _tall;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final handoff = MapStationHandoff();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => WeatherRankingPage(initialTab: tab),
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
    expect(WeatherRankingTab.parse('high'), WeatherRankingTab.tempExtremes);
    expect(WeatherRankingTab.parse('low'), WeatherRankingTab.tempExtremes);
    expect(WeatherRankingTab.parse('range'), WeatherRankingTab.tempExtremes);
    expect(WeatherRankingTab.parse('pres'), WeatherRankingTab.pressure);
    expect(WeatherRankingTab.parse('rh'), WeatherRankingTab.humidity);
    expect(WeatherRankingTab.parse(null), WeatherRankingTab.rain);
    expect(WeatherRankingTab.parse('nope'), WeatherRankingTab.rain);
  });

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
    await tester.tap(find.text(l10n.weatherRankingLowest));
    await tester.pumpAndSettle();
    expect(find.text('18.0 °C'), findsOneWidget);

    await tester.ensureVisible(find.text(l10n.weatherRankingMergeCounty));
    await tester.tap(find.text(l10n.weatherRankingMergeCounty));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.weatherRankingMergeCounty));
    await tester.pumpAndSettle();

    await _openTab(tester, l10n.weatherRankingWind);
    expect(find.byIcon(Icons.navigation), findsWidgets);

    await _openTab(tester, l10n.weatherRankingGust);
    expect(find.textContaining('m/s'), findsWidgets);

    await _openTab(tester, l10n.mapLayerHumidity);
    expect(find.text('80 %'), findsOneWidget);

    await _openTab(tester, l10n.mapLayerPressure);
    expect(find.text('1013.2 hPa'), findsOneWidget);

    await _openTab(tester, l10n.weatherRankingTempExtremes);
    expect(find.textContaining('°C'), findsWidgets);
    await tester.tap(find.text(l10n.weatherRankingExtremeLow).hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.weatherRankingExtremeRange).hitTestable());
    await tester.pumpAndSettle();
    await tester.drag(
      find.text(l10n.weatherRankingExtremeHigh).hitTestable(),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.reportFilterOrderAsc).hitTestable());
    await tester.pumpAndSettle();
    await tester.drag(
      find.text(l10n.reportFilterOrderAsc).hitTestable(),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.weatherRankingMergeTown).hitTestable());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, 200));
    await tester.pumpAndSettle();
  });
}
