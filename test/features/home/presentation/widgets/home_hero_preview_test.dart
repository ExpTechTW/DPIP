@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_content.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders the hero block ([HomeContent] flush, on a located township) at a
/// real device size, so the "does the rain trend card actually reach the
/// bottom, and does anything overflow past it" question can be *looked at*
/// instead of re-derived from arithmetic a second time.
///
/// `mise exec -- flutter test --run-skipped --tags preview
/// test/features/home/presentation/widgets/home_hero_preview_test.dart`
/// → `build/home_hero_preview/`.
class _FakeWeatherRepository implements MeteorWeatherRepository {
  @override
  Future<Result<WeatherRealtime?>> realtime(double lat, double lng) async =>
      const Ok(
        WeatherRealtime(
          id: '467410',
          station: WeatherRealtimeStation(
            name: '臺南',
            latitude: 23.0,
            longitude: 120.2,
            altitude: 40,
            distance: 1.2,
          ),
          time: 0,
          data: WeatherRealtimeData(
            weather: '多雲',
            weatherCode: 200,
            temperature: 28.7,
            humidity: 89,
            rain: 0.0,
            wind: WeatherWind(),
            gust: WeatherWind(),
          ),
        ),
      );

  @override
  Future<Result<WeatherForecast>> forecast(String code) async =>
      Ok(WeatherForecast(updateTime: 0, forecast: const []));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// A mid-hour pulse so the preview chart has visible shape.
class _FakeHourTrendRepository implements RainHourTrendRepository {
  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async => Ok(
    RainHourTrend(
      startSecond: 1786362600,
      mm: [
        for (var i = 0; i < 60; i++)
          (i >= 22 && i <= 40)
              ? (0.5 + (0.9 * (1 - ((i - 31).abs() / 9))))
              : 0.4,
      ],
    ),
  );
}

class _FakeEventRepository implements EventRepository {
  @override
  Future<Result<List<Event>>> events({String? regionCode}) async =>
      const Ok([]);

  @override
  Future<Result<List<Event>>> activeEvents({String? regionCode}) async =>
      const Ok([]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('render the hero block at a real device size', (tester) async {
    // The screenshots this is chasing were 1206x2622 physical at what reads
    // as 3x — 402x874 logical. iOS status bar + Dynamic Island ~59, home
    // indicator ~34: the same figures `HomeSheet`/`HomeContent` compute from
    // MediaQuery in the real app.
    const dpr = 3.0;
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = dpr;
    tester.view.padding = const FakeViewPadding(
      top: 59 * dpr,
      bottom: 34 * dpr,
    );
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'home.savedRegionCodes': ['100'],
    });
    final store = RegionStore(Prefs(await SharedPreferences.getInstance()));
    store
      ..select(1) // 所在地
      ..setCurrentCode('100'); // located, so the hero block is in play
    const directory = TownDirectory(<String, Town>{
      '100': Town(
        code: '100',
        city: '臺南',
        town: '永康',
        lat: 23.0,
        lng: 120.2,
        cityLevel: '市',
        townLevel: '區',
      ),
    });
    final events = _FakeEventRepository();

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'TW'),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<RegionStore>.value(value: store),
            Provider<TownDirectory>.value(value: directory),
            Provider<EventRepository>.value(value: events),
            ChangeNotifierProvider<HomeWeatherController>(
              create: (_) => HomeWeatherController(
                _FakeWeatherRepository(),
                _FakeHourTrendRepository(),
                store,
                directory,
              ),
            ),
            ChangeNotifierProvider<HomeActiveEventsController>(
              create: (_) => HomeActiveEventsController(events, store),
            ),
          ],
          // Mirrors HomePage's own structure — Scaffold → Stack →
          // Positioned.fill — rather than handing HomeContent to Scaffold.body
          // directly, so it sees the same StackFit.expand-derived constraints
          // the real sheet gives it, not whatever Scaffold.body loosely offers
          // on its own.
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    key: key,
                    child: HomeContent(
                      scrollController: ScrollController(),
                      expanded: true,
                      reveal: 1,
                      topInset: 59 + 44, // regionBarInset at flush=1
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Not pumpAndSettle: RainOnCard's splash keeps its own ticker running for
    // as long as the card is on screen, so nothing here ever "settles" — a
    // fixed handful of frames is enough for images (weather icon, area name)
    // to resolve and layout to finish.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/home_hero_preview')
      ..createSync(recursive: true);
    File('${dir.path}/hero.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${dir.path}/hero.png at ${image.width}x${image.height}');
  });
}
