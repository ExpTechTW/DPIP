import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_content.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_sky_background.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWeatherRepository implements MeteorWeatherRepository {
  @override
  Future<Result<WeatherRealtime?>> realtime(double lat, double lng) async =>
      const Ok(null);

  @override
  Future<Result<WeatherForecast>> forecast(String code) async =>
      Ok(WeatherForecast(updateTime: 0, forecast: const []));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeHourTrendRepository implements RainHourTrendRepository {
  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async =>
      Ok(RainHourTrend(startSecond: 1786362600, mm: List.filled(60, 0.5)));
}

class _FakeEventRepository implements EventRepository {
  @override
  Future<Result<List<Event>>> events({String? regionCode}) async =>
      const Ok([]);

  @override
  Future<Result<List<Event>>> activeEvents({String? regionCode}) async =>
      const Ok([]);
}

/// Pumps [HomeSheet] wired the same way `HomePage` wires it — the [extent]
/// notifier is both the app-wide provider and the widget's own constructor
/// argument, so a test can drive it exactly like a real drag would.
Widget _wrap(RegionStore store, HomeSheetExtent extent) {
  const directory = TownDirectory(<String, Town>{});
  final events = _FakeEventRepository();
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<RegionStore>.value(value: store),
        ChangeNotifierProvider<HomeSheetExtent>.value(value: extent),
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
      child: Scaffold(
        body: HomeSheet(
          scrollController: ScrollController(),
          extent: extent,
          weatherMode: WeatherMode.auto,
          skyTimeMode: SkyTimeMode.auto,
        ),
      ),
    ),
  );
}

Future<RegionStore> _store() async {
  SharedPreferences.setMockInitialValues({
    'home.savedRegionCodes': ['100'],
  });
  return RegionStore(Prefs(await SharedPreferences.getInstance()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The content layer re-derives `expanded` / `reveal` / `topInset` straight
  /// from [HomeSheetExtent] via `context.select` (see `home_sheet.dart`),
  /// separately from the chrome's own per-tick rebuild — this pins that the
  /// derivation still lands on the same values that the widget's own
  /// `HomeChrome` thresholds imply, across the sheet's whole travel.
  testWidgets(
    'HomeContent tracks extent the same at rest, mid-drag, and full',
    (tester) async {
      final extent = HomeSheetExtent();
      await tester.pumpWidget(_wrap(await _store(), extent));
      await tester.pumpAndSettle();

      HomeContent content() =>
          tester.widget<HomeContent>(find.byType(HomeContent));

      // Rest: below every threshold — collapsed, no weather reveal.
      expect(content().expanded, isFalse);
      expect(content().reveal, 0);
      expect(content().topInset, 0);

      // Mid-drag, still below HomeChrome's weather/flush thresholds (0.85/0.9):
      // the content layer must not have picked up any reveal yet.
      extent.value = 0.6;
      await tester.pump();
      expect(content().expanded, isFalse);
      expect(content().reveal, 0);
      expect(content().topInset, 0);

      // Past the weather threshold but short of full: reveal ramps, still
      // collapsed (not yet at the top epsilon).
      extent.value = 0.95;
      await tester.pump();
      expect(content().expanded, isFalse);
      expect(content().reveal, greaterThan(0));
      expect(content().topInset, greaterThan(0));

      // Full: flush, expanded, fully revealed.
      extent.value = HomeSheetExtent.max;
      await tester.pump();
      expect(content().expanded, isTrue);
      expect(content().reveal, 1);
      expect(content().topInset, greaterThan(0));
    },
  );

  testWidgets('scrolling freezes and unfreezes the weather backdrop', (
    tester,
  ) async {
    final extent = HomeSheetExtent();
    await tester.pumpWidget(_wrap(await _store(), extent));
    // Full-screen so the weather backdrop is live. `pump` (not
    // `pumpAndSettle`): the live sky's own ticker never settles.
    extent.value = HomeSheetExtent.max;
    await tester.pump();
    expect(_sky(tester).active, isTrue);

    // Scrolling the content list freezes the backdrop — the blur about to
    // cover it hides the hold, and the shader stops re-rendering every frame.
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(HomeContent),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    scrollable.position.jumpTo(120);
    await tester.pump();
    expect(_sky(tester).active, isFalse);

    // Returning to the top resumes the animation where it left off.
    scrollable.position.jumpTo(0);
    await tester.pump();
    expect(_sky(tester).active, isTrue);
  });
}

WeatherSkyBackground _sky(WidgetTester tester) =>
    tester.widget<WeatherSkyBackground>(find.byType(WeatherSkyBackground));
