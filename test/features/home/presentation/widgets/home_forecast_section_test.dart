/// The forecast card is the only 24-hour readout on Home. A township with no
/// hours must not offer a retry, a failed fetch must, and pulling the sheet
/// up is what reveals the feels-like band — a collapsed card that already
/// shows it, or an expanded one that hides it, lies about the hour.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_forecast_section.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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

WeatherForecastPoint _point(String time, double temperature) =>
    WeatherForecastPoint(
      time: time,
      temperature: temperature,
      apparentTemp: temperature + 1,
      humidity: 61,
      weather: '多雲',
      weatherCode: 200,
      pop: 30,
      wind: const ForecastWind(direction: 'NE', speed: 3, beaufort: 2),
    );

class _Weather implements MeteorWeatherRepository {
  _Weather(this.forecastResult);

  Result<WeatherForecast> forecastResult;

  @override
  Future<Result<WeatherRealtime?>> realtime(
    double latitude,
    double longitude,
  ) async => const Ok(null);

  @override
  Future<Result<WeatherForecast>> forecast(String code) async => forecastResult;

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
  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async =>
      Ok(RainHourTrend(startSecond: 0, mm: List<double>.filled(60, 0)));
}

Future<HomeWeatherController> _pump(
  WidgetTester tester, {
  required RegionStore regions,
  required _Weather weather,
  double expansion = 1,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = HomeWeatherController(
    weather,
    _Trend(),
    regions,
    _towns(),
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeWeatherController>.value(value: controller),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HomeForecastSection(expansion: expansion)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('nationwide asks for a township', (tester) async {
    final regions = RegionStore(SettingsStore.inMemory())..select(0);
    await _pump(
      tester,
      regions: regions,
      weather: _Weather(const Err(NetworkFailure('x'))),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeForecastSection)),
    );
    expect(find.text(l10n.homeForecastUnavailable), findsOneWidget);
  });

  testWidgets('an empty series has no retry; a failure does', (tester) async {
    final regions = RegionStore(SettingsStore.inMemory())
      ..addSaved(_code)
      ..select(2);
    final weather = _Weather(
      Ok(WeatherForecast(updateTime: 1, forecast: const [])),
    );
    final controller = await _pump(tester, regions: regions, weather: weather);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeForecastSection)),
    );
    expect(find.text(l10n.homeForecastEmpty), findsOneWidget);
    expect(find.text(l10n.commonRetry), findsNothing);

    weather.forecastResult = const Err(NetworkFailure('down'));
    await controller.refresh();
    await tester.pumpAndSettle();
    expect(find.text(l10n.commonRetry), findsOneWidget);
    weather.forecastResult = Ok(
      WeatherForecast(updateTime: 2, forecast: [_point('14:00', 28)]),
    );
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text(l10n.homeForecastTitle), findsOneWidget);
    controller.dispose();
  });

  testWidgets('the detail band opens only once the card is expanded', (
    tester,
  ) async {
    final regions = RegionStore(SettingsStore.inMemory())
      ..addSaved(_code)
      ..select(2);
    final weather = _Weather(
      Ok(
        WeatherForecast(
          updateTime: 1,
          forecast: [_point('14:00', 22), _point('15:00', 31)],
        ),
      ),
    );
    final controller = await _pump(
      tester,
      regions: regions,
      weather: weather,
      expansion: 0,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeForecastSection)),
    );
    expect(find.text(l10n.homeForecastTitle), findsOneWidget);
    expect(find.text(l10n.homeForecastHighLow('31', '22')), findsOneWidget);
    expect(find.text(l10n.homeForecastFeelsLike('23')), findsNothing);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeWeatherController>.value(
            value: controller,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HomeForecastSection(expansion: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.homeForecastFeelsLike('23')), findsOneWidget);
    await tester.tap(find.text('15h'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.homeForecastFeelsLike('32')), findsOneWidget);
    expect(find.textContaining('多雲'), findsWidgets);
    controller.dispose();
  });
}
