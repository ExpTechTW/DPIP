/// The home rain card is the only place the next hour's minutes become a
/// sentence. A dry hour that still draws bars, or a failed fetch with no
/// retry, would either invent rain or leave the sheet stuck on a grey pane.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_rain_trend_section.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Weather implements MeteorWeatherRepository {
  @override
  Future<Result<WeatherRealtime?>> realtime(double lat, double lng) async =>
      const Ok(null);

  @override
  Future<Result<WeatherForecast>> forecast(String code) async =>
      Ok(WeatherForecast(updateTime: 0, forecast: const []));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Trend implements RainHourTrendRepository {
  Result<RainHourTrend> next = const Err(NetworkFailure('down'));
  int calls = 0;

  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async {
    calls++;
    return next;
  }
}

RainHourTrend _series(double peak, {int wetUntil = 10}) {
  return RainHourTrend(
    startSecond: 1786362600,
    mm: [for (var i = 0; i < 60; i++) i < wetUntil ? peak : 0],
  );
}

Future<HomeWeatherController> _pump(
  WidgetTester tester, {
  required _Trend trends,
  RainHourTrend? trend,
  RainHourTrendSummary? summary,
  double reveal = 0,
  double rain = 0,
  Color? sky,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final regions = RegionStore(SettingsStore.inMemory());
  const directory = TownDirectory({
    '6300100': Town(
      code: '6300100',
      city: '臺北',
      town: '中正',
      lat: 25.03,
      lng: 121.52,
      cityLevel: '市',
      townLevel: '區',
    ),
  });
  final controller = HomeWeatherController(
    _Weather(),
    trends,
    regions,
    directory,
  );
  addTearDown(controller.dispose);
  addTearDown(regions.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RegionStore>.value(value: regions),
        ChangeNotifierProvider<HomeWeatherController>.value(value: controller),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeRainTrendSection(
            trend: trend,
            summary: summary,
            reveal: reveal,
            rain: rain,
            sky: sky,
            weatherMode: WeatherMode.rain,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  testWidgets('grades and a dry hour', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final trends = _Trend();

    await _pump(tester, trends: trends, trend: _series(0));
    expect(find.text(l10n.homeRainTrendTitle), findsNothing);

    await _pump(
      tester,
      trends: trends,
      trend: _series(2),
      reveal: 1,
      rain: 0.4,
      sky: const Color(0xFF88AADD),
    );
    expect(find.text(l10n.homeRainTrendScattered), findsOneWidget);

    await _pump(tester, trends: trends, trend: _series(8, wetUntil: 20));
    expect(find.text(l10n.homeRainTrendLightStopping(20)), findsOneWidget);

    await _pump(tester, trends: trends, trend: _series(20, wetUntil: 60));
    expect(find.text(l10n.homeRainTrendHeavySustained), findsOneWidget);
    expect(find.textContaining(':'), findsWidgets);
  });

  testWidgets('no fix is an empty pane; a failed township offers retry', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final trends = _Trend();
    await _pump(tester, trends: trends);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(find.text(l10n.homeRainTrendNoData), findsOneWidget);
    final regions = tester
        .element(find.byType(HomeRainTrendSection))
        .read<RegionStore>();
    regions.setCurrentCode('6300100');
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.homeForecastEmpty), findsOneWidget);
    expect(trends.calls, 1);

    trends.next = Ok(_series(3));
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.homeRainTrendScattered), findsOneWidget);
    expect(trends.calls, 2);
  });

  testWidgets('light rain that lasts, and heavy rain that stops', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final trends = _Trend();

    await _pump(tester, trends: trends, trend: _series(8, wetUntil: 60));
    expect(find.text(l10n.homeRainTrendLightSustained), findsOneWidget);

    await _pump(tester, trends: trends, trend: _series(20, wetUntil: 20));
    expect(find.text(l10n.homeRainTrendHeavyStopping(20)), findsOneWidget);
  });

  testWidgets('minutes before the forecast window are a narrow no-data band', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final trends = _Trend();
    // AppTime is the device clock until a sync is installed. Put the hour
    // two minutes ahead of that clock so the chart has a head it cannot plot.
    final start = DateTime.now().toUtc().add(const Duration(minutes: 2));
    final trend = RainHourTrend(
      startSecond: start.millisecondsSinceEpoch ~/ 1000,
      mm: [for (var i = 0; i < 60; i++) i < 20 ? 8.0 : 0],
    );

    await _pump(tester, trends: trends, trend: trend, reveal: 1);
    expect(find.text(l10n.homeRainTrendNoData), findsWidgets);
    expect(find.byType(RotatedBox), findsWidgets);

    // Same series again: the chart state is kept, and the repaint conditions
    // after the data identity all have to be read.
    await _pump(tester, trends: trends, trend: trend, reveal: 1);
    expect(find.text(l10n.homeRainTrendLightStopping(20)), findsOneWidget);
  });
}
