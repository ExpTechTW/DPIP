import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
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
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_active_events_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_content.dart';
import 'package:dpip/features/home/presentation/widgets/home_eew_section.dart';
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
  const _FakeWeatherRepository({this.forecastValue});

  final WeatherForecast? forecastValue;

  @override
  Future<Result<WeatherRealtime?>> realtime(double lat, double lng) async =>
      const Ok(null);

  @override
  Future<Result<WeatherForecast>> forecast(String code) async =>
      Ok(forecastValue ?? WeatherForecast(updateTime: 0, forecast: const []));

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

/// A refreshed EEW channel carrying one live alert, ready to hand to [_wrap].
Future<RealtimeNotifier<List<Eew>>> _liveEew() async {
  final channel = RealtimeChannel<List<Eew>>(
    source: _StaticEewSource([
      Eew(
        agency: 'CWA',
        id: 'test',
        serial: 34,
        status: 0,
        isFinal: false,
        info: const EewInfo(
          time: 1786362600000,
          longitude: 121.5,
          latitude: 23.5,
          depth: 10,
          magnitude: 7.5,
          location: '臺東縣',
          max: 6,
        ),
      ),
    ]),
    clock: _FakeClock(),
    elapsed: _FakeElapsed(),
    ticker: _FakeTicker(),
    config: RealtimeConfig.eew,
    label: 'test-eew',
  );
  await channel.refreshNow();
  return RealtimeNotifier<List<Eew>>(channel);
}

/// Pumps [HomeContent] with everything it reads: a [RegionStore] to switch on
/// and localizations for the body.
Widget _wrap(
  RegionStore store, {
  bool expanded = false,
  RealtimeNotifier<List<Eew>>? eew,
  double topInset = 0,
  double textScale = 1,
  ScrollController? controller,
  RainHourTrendRepository? hourTrend,
  WeatherForecast? forecast,
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
            _FakeWeatherRepository(forecastValue: forecast),
            hourTrend ?? _FakeHourTrendRepository(),
            store,
            directory,
          ),
        ),
        ChangeNotifierProvider<HomeActiveEventsController>(
          create: (_) => HomeActiveEventsController(events, store),
        ),
        // Read by the EEW alert card for its 所在地預估 countdown.
        Provider<Future<SeismicTravelTimeTable>>.value(
          value: Future<SeismicTravelTimeTable>.value(
            const SeismicTravelTimeTable({}),
          ),
        ),
        Provider<LocationService>.value(
          value: LocationService(
            directory,
            isAvailable: () async => false,
            fix: () async => null,
            lastKnown: () async => null,
            status: () async => LocationStatus.denied,
          ),
        ),
        if (eew != null)
          ChangeNotifierProvider<RealtimeNotifier<List<Eew>>>.value(value: eew)
        else
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
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: HomeContent(
              scrollController: controller ?? ScrollController(),
              expanded: expanded,
              topInset: topInset,
            ),
          ),
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

/// A located township on a dry hour: the hero block carries the one forecast
/// card, and everything below it is the (empty) events card — the shape whose
/// scroll range is shorter than the reveal ramp used to assume.
Future<Widget> _dryHeroApp({
  required double textScale,
  required ScrollController controller,
}) async {
  final store = await _store();
  store
    ..select(1)
    ..setCurrentCode('100');
  const point = WeatherForecastPoint(
    time: '14:00',
    temperature: 30,
    apparentTemp: 33,
    humidity: 70,
    weather: 'Clear',
    weatherCode: 100,
    pop: 0,
    wind: ForecastWind(direction: 'NE', speed: 2, beaufort: 2),
  );
  return _wrap(
    store,
    expanded: true,
    topInset: 88,
    textScale: textScale,
    controller: controller,
    hourTrend: _FakeHourTrendRepository(dry: true),
    forecast: const WeatherForecast(
      updateTime: 0,
      forecast: [point, point, point],
    ),
    directory: const TownDirectory({
      '100': Town(
        code: '100',
        city: 'Test',
        town: 'North',
        lat: 25.0,
        lng: 121.5,
        cityLevel: 'City',
        townLevel: 'District',
      ),
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

  testWidgets('the EEW card is full-screen only, never at rest', (
    tester,
  ) async {
    final store = await _store();
    store
      ..select(1)
      ..setCurrentCode('100');

    // At rest `HomeMonitorBanner` is still on screen with the same alert, so
    // the in-sheet card would be a second copy of one warning.
    await tester.pumpWidget(_wrap(store, eew: await _liveEew()));
    await tester.pumpAndSettle();
    expect(find.byType(HomeEewSection), findsNothing);
    expect(find.text('臺東縣'), findsNothing);

    // Full-screen the banner has slid away, so the card carries the alert.
    await tester.pumpWidget(
      _wrap(store, expanded: true, eew: await _liveEew()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeEewSection), findsOneWidget);
    expect(find.text('臺東縣'), findsOneWidget);

    // Tear down so the card's countdown timer is cancelled.
    await tester.pumpWidget(const SizedBox());
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

  testWidgets('a short phone can scroll to the full forecast detail band', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        cityLevel: 'City',
        townLevel: 'District',
      ),
    });
    const point = WeatherForecastPoint(
      time: '14:00',
      temperature: 30,
      apparentTemp: 33,
      humidity: 70,
      weather: 'Clear',
      weatherCode: 100,
      pop: 0,
      wind: ForecastWind(direction: 'NE', speed: 2, beaufort: 2),
    );
    await tester.pumpWidget(
      _wrap(
        store,
        expanded: true,
        topInset: 88,
        hourTrend: _FakeHourTrendRepository(dry: true),
        forecast: const WeatherForecast(
          updateTime: 0,
          forecast: [point, point, point],
        ),
        directory: directory,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'initial short layout');

    final details = find.text('Feels like 33°');
    await tester.scrollUntilVisible(
      details,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(details, findsOneWidget);
    expect(details.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // A tall phone is the case the fixed 200 px reveal ramp could not serve: its
  // hero block fills the viewport exactly, so the whole scroll range is the
  // handle, one gap and the empty events card — about 140 px. The card used to
  // top out near 0.7 at the very bottom of the list and sit there with its last
  // line of text cut in half. A short phone never showed it, because the 760 px
  // hero floor hands it scroll distance its own viewport does not have.
  testWidgets('a tall phone can open the forecast card all the way', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1284, 2778); // 428 × 926 at 3×
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      await _dryHeroApp(textScale: 1, controller: controller),
    );
    await tester.pumpAndSettle();

    final reach = controller.position.maxScrollExtent;
    expect(
      reach,
      lessThan(200),
      reason: 'the case under test: less scroll than the ramp asks for',
    );

    controller.jumpTo(reach);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<HomeForecastSection>(find.byType(HomeForecastSection))
          .expansion,
      1,
    );
    expect(find.text('Feels like 33°').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // The scroll rests wherever the finger leaves it, so every offset in between
  // is a state someone sits and reads. The detail band is text: a fraction of
  // a line of text is a line cut in half, which is why it snaps open rather
  // than tracking the scroll like the curve above it does.
  testWidgets('no resting scroll position leaves the detail band sliced', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1284, 2778);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      await _dryHeroApp(textScale: 1, controller: controller),
    );
    await tester.pumpAndSettle();

    final reach = controller.position.maxScrollExtent;
    for (final fraction in const [0.0, 0.2, 0.4, 0.55, 0.7, 0.9, 1.0]) {
      controller.jumpTo(reach * fraction);
      await tester.pumpAndSettle();

      final wind = find.text('NE · Force 2'); // the band's last line
      if (wind.evaluate().isEmpty) continue; // not open yet at this offset
      expect(
        tester.getRect(wind).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byType(HomeForecastSection)).bottom,
        ),
        reason: 'band drawn past the card edge at $fraction of the scroll',
      );
    }
    expect(tester.takeException(), isNull);
  });

  // Every line in an hour chip grows with the text-size setting while its icon
  // does not, so the strip's old fixed 108 px height ran 16 px short at 特大 and
  // cut the rain chance off the bottom of every chip.
  for (final scale in const [1.2, 1.45]) {
    testWidgets('the hour chips fit at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(1284, 2778);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        await _dryHeroApp(textScale: scale, controller: controller),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'summary card');

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'fully opened card');
      expect(
        find.text('0%'),
        findsWidgets,
      ); // the chip line that used to be cut
    });
  }

  // The narrow phone at the largest in-app text step: the card's title row laid
  // its high/low out unbounded, so the row overflowed 35 px to the right and
  // the reading was cut off at the card's edge. 320 pt is the smallest screen
  // the app ships to, and 1.45 is 特大 with the system size left alone.
  testWidgets('the forecast card fits a narrow phone at text scale 1.45', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      await _dryHeroApp(textScale: 1.45, controller: controller),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'summary card');

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'fully opened card');
    expect(find.text('H 30° · L 30°'), findsOneWidget);
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
