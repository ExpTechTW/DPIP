import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_active_events_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_content.dart';
import 'package:dpip/features/home/presentation/widgets/home_forecast_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_rain_trend_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet_header.dart';
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

/// Stub weather: home content resolves no towns from an empty directory, so
/// neither endpoint is invoked in the switch tests.
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

/// Stub next-hour rain trend.
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

/// Pumps [HomeContent] with everything it reads: a [RegionStore] to switch on
/// and localizations for the body.
Widget _wrap(RegionStore store, {bool expanded = false}) {
  const directory = TownDirectory(<String, Town>{});
  final events = _FakeEventRepository();
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
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
      child: Scaffold(
        body: HomeContent(
          scrollController: ScrollController(),
          expanded: expanded,
        ),
      ),
    ),
  );
}

/// A store with two saved regions → four areas (全國, 所在地, +2), so the
/// switch tests have room to move (select(2) / next twice).
Future<RegionStore> _store() async {
  SharedPreferences.setMockInitialValues({
    'home.savedRegionCodes': ['100', '200'],
  });
  return RegionStore(Prefs(await SharedPreferences.getInstance()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the active area panel', (tester) async {
    await tester.pumpWidget(_wrap(await _store()));
    expect(find.byType(HomeSheetHeader), findsOneWidget);
  });

  testWidgets('switching area forward slides without a layout error', (
    tester,
  ) async {
    final store = await _store()
      ..select(0);
    await tester.pumpWidget(_wrap(store));

    store.next(); // 0 → 1
    await tester.pump(); // kick off the transition
    // Both the outgoing and incoming panels are mounted while it slides.
    expect(find.byType(HomeSheetHeader), findsNWidgets(2));
    await tester.pump(
      const Duration(milliseconds: 100),
    ); // still mid-slide (220ms)
    expect(find.byType(HomeSheetHeader), findsNWidgets(2));
    await tester.pumpAndSettle();

    // Settled: the outgoing panel is dropped, one panel remains.
    expect(find.byType(HomeSheetHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching area backward settles cleanly', (tester) async {
    final store = await _store()
      ..select(2);
    await tester.pumpWidget(_wrap(store));

    store.previous(); // 2 → 1
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(HomeSheetHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid switches settle to one panel', (tester) async {
    final store = await _store()
      ..select(0);
    await tester.pumpWidget(_wrap(store));

    store.next(); // 0 → 1
    await tester.pump(const Duration(milliseconds: 40));
    store.next(); // 1 → 2, interrupting the first slide
    await tester.pumpAndSettle();

    expect(find.byType(HomeSheetHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no GPS fix → the header says the location is unavailable', (
    tester,
  ) async {
    final store = await _store();
    // 所在地 is index 1; leaving currentCode null is exactly the no-fix state.
    store.select(1);
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.regionCurrentUnavailable), findsOneWidget);
    expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
  });

  testWidgets('no GPS fix → no weather readout stands in for the location', (
    tester,
  ) async {
    final store = await _store();
    store.select(1);
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    // Without a location there is no location's weather. A dashed-out reading
    // row would read as "we are here, the weather is unknown"; worse, the
    // precipitation slot used to fabricate "0.0 mm" for missing data, which is
    // indistinguishable from a real "no rain" reading.
    expect(find.textContaining('mm'), findsNothing);
    expect(find.byIcon(Icons.cloud_outlined), findsNothing);
  });

  testWidgets('a located area shows the reading row, not the notice', (
    tester,
  ) async {
    final store = await _store();
    store
      ..select(1)
      ..setCurrentCode('100');
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.regionCurrentUnavailable), findsNothing);
    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
  });

  testWidgets('no GPS fix → the sheet carries no cards at all', (tester) async {
    final store = await _store();
    store.select(1);
    // Full-screen is where every card is in play — rain trend, forecast and
    // active events. None of them has a place to report on without a fix.
    await tester.pumpWidget(_wrap(store, expanded: true));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byType(HomeRainTrendSection), findsNothing);
    expect(find.byType(HomeForecastSection), findsNothing);
    expect(find.byType(HomeActiveEventsSection), findsNothing);
    // The header's notice is the whole of the sheet's answer.
    expect(find.text(l10n.regionCurrentUnavailable), findsOneWidget);
  });

  testWidgets('a located area full-screen shows the cards', (tester) async {
    final store = await _store();
    store
      ..select(1)
      ..setCurrentCode('100');
    await tester.pumpWidget(_wrap(store, expanded: true));
    await tester.pumpAndSettle();

    expect(find.byType(HomeRainTrendSection), findsOneWidget);
    expect(find.byType(HomeForecastSection), findsOneWidget);
    expect(find.byType(HomeActiveEventsSection), findsOneWidget);
  });

  testWidgets('全國 keeps its events card (it is not a missing location)', (
    tester,
  ) async {
    final store = await _store()
      ..select(0);
    await tester.pumpWidget(_wrap(store, expanded: true));
    await tester.pumpAndSettle();

    // 全國 has no point weather, but its events feed is real.
    expect(find.byType(HomeRainTrendSection), findsNothing);
    expect(find.byType(HomeForecastSection), findsNothing);
    expect(find.byType(HomeActiveEventsSection), findsOneWidget);
  });
}
