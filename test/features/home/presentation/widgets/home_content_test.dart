import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_active_events_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_content.dart';
import 'package:dpip/features/home/presentation/widgets/home_forecast_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_rain_trend_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet_header.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_card.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:dpip/core/weather/weather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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

/// Stub next-hour rain trend — dry (no rain) or a steady light rain.
class _FakeHourTrendRepository implements RainHourTrendRepository {
  _FakeHourTrendRepository({this.dry = false});

  final bool dry;

  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async => Ok(
    dry
        ? RainHourTrend.dry(startUtc: DateTime.utc(2026, 8, 11))
        : RainHourTrend(startSecond: 1786362600, mm: List.filled(60, 0.5)),
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

/// A never-started EEW channel: connecting status, no data — the calm state.
/// `HomeContent` renders nothing for it, so every existing switch/weather test
/// keeps passing unchanged.
class _FakeClock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 8, 12);
}

class _FakeElapsed implements Elapsed {
  @override
  Duration get elapsed => Duration.zero;
}

class _FakeTicker implements Ticker {
  @override
  TickerHandle start(Duration interval, void Function() onTick) =>
      _NoopHandle();
}

class _NoopHandle implements TickerHandle {
  @override
  void cancel() {}
}

class _StaticEewSource extends RealtimeSource<List<Eew>> {
  _StaticEewSource(this.data);
  final List<Eew> data;

  @override
  Future<Result<List<Eew>>> fetch() async => Ok(data);

  @override
  DateTime? timestampOf(List<Eew> value) => null;

  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => listEquals(a, b);
}

/// Pumps [HomeContent] with everything it reads: a [RegionStore] to switch on
/// and localizations for the body.
Widget _wrap(
  RegionStore store, {
  bool expanded = false,
  RainHourTrendRepository? hourTrend,
  TownDirectory directory = const TownDirectory(<String, Town>{}),
}) {
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
            hourTrend ?? _FakeHourTrendRepository(),
            store,
            directory,
          ),
        ),
        ChangeNotifierProvider<HomeActiveEventsController>(
          create: (_) => HomeActiveEventsController(events, store),
        ),
        ChangeNotifierProvider<RealtimeNotifier<List<Eew>>>(
          create: (_) => RealtimeNotifier<List<Eew>>(
            RealtimeChannel<List<Eew>>(
              source: _StaticEewSource(const []),
              clock: _FakeClock(),
              elapsed: _FakeElapsed(),
              ticker: _FakeTicker(),
              config: RealtimeConfig.eew,
              label: 'test-eew',
            ),
          ),
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
  return RegionStore(
    SettingsStore.inMemory({
      'home.savedRegionCodes': ['100', '200'],
    }),
  );
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
    expect(find.byIcon(cloudy), findsOneWidget);
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

  testWidgets('a dry hour hides the rain trend and raises a compact forecast', (
    tester,
  ) async {
    final store = await _store();
    store
      ..select(1)
      ..setCurrentCode('100');
    // A resolvable township, so the trend fetch actually runs and resolves dry.
    const directory = TownDirectory({
      '100': Town(
        code: '100',
        city: 'Test',
        town: 'North',
        lat: 25.0,
        lng: 121.5,
        cityLevel: '市',
        townLevel: '區',
      ),
    });
    await tester.pumpWidget(
      _wrap(
        store,
        expanded: true,
        hourTrend: _FakeHourTrendRepository(dry: true),
        directory: directory,
      ),
    );
    await tester.pumpAndSettle();

    // No rain forecast → the trend card is gone entirely.
    expect(find.byType(HomeRainTrendSection), findsNothing);
    // One forecast card only — the hero's summary, not a second full card
    // below the fold. It starts collapsed and grows with scroll.
    final sections = tester
        .widgetList<HomeForecastSection>(find.byType(HomeForecastSection))
        .toList();
    expect(sections, hasLength(1));
    expect(sections.single.expansion, 0);
    // The hero card gets the same rain-on-glass treatment as the trend card.
    expect(
      find.ancestor(
        of: find.byType(HomeForecastSection),
        matching: find.byType(RainOnCard),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'pulling the sheet up grows the hero forecast into the full card',
    (tester) async {
      final store = await _store();
      store
        ..select(1)
        ..setCurrentCode('100');
      const directory = TownDirectory({
        '100': Town(
          code: '100',
          city: 'Test',
          town: 'North',
          lat: 25.0,
          lng: 121.5,
          cityLevel: '市',
          townLevel: '區',
        ),
      });
      await tester.pumpWidget(
        _wrap(
          store,
          expanded: true,
          hourTrend: _FakeHourTrendRepository(dry: true),
          directory: directory,
        ),
      );
      await tester.pumpAndSettle();

      final section = tester.widget<HomeForecastSection>(
        find.byType(HomeForecastSection),
      );
      expect(section.expansion, 0);

      // Scroll the sheet's list upward — the one forecast card stretches toward
      // its full form instead of a second full card appearing.
      await tester.drag(find.byType(ListView).first, const Offset(0, -120));
      await tester.pump();
      final grown = tester.widget<HomeForecastSection>(
        find.byType(HomeForecastSection),
      );
      expect(grown.expansion, greaterThan(0));
      // Still exactly one forecast card — no duplicate full card joined in.
      expect(find.byType(HomeForecastSection), findsOneWidget);
    },
  );

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
