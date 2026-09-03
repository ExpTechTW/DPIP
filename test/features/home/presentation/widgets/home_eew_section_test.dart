import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
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
import 'package:dpip/features/home/presentation/widgets/home_eew_section.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeClock implements Clock {
  _FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
}

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  void advance(Duration d) => value += d;
  @override
  Duration get elapsed => value;
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

class _StaticSource extends RealtimeSource<List<Eew>> {
  _StaticSource(this.data);
  final List<Eew> data;

  @override
  Future<Result<List<Eew>>> fetch() async => Ok(data);

  @override
  DateTime? timestampOf(List<Eew> value) => null;

  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => listEquals(a, b);
}

Eew _alert() => Eew(
  agency: 'CWA',
  id: 'test',
  serial: 2,
  status: 0,
  isFinal: false,
  info: const EewInfo(
    time: 1786362600000,
    longitude: 121.5,
    latitude: 23.5,
    depth: 10,
    magnitude: 6.0,
    location: '花蓮縣',
    max: 4,
  ),
);

Future<
  ({
    RealtimeNotifier<List<Eew>> notifier,
    RealtimeChannel<List<Eew>> channel,
    _FakeElapsed elapsed,
  })
>
_liveNotifier(List<Eew> data) async {
  final elapsed = _FakeElapsed();
  final channel = RealtimeChannel<List<Eew>>(
    source: _StaticSource(data),
    clock: _FakeClock(DateTime.utc(2026, 8, 12, 12)),
    elapsed: elapsed,
    ticker: _FakeTicker(),
    config: RealtimeConfig.eew,
    label: 'test-eew',
  );
  await channel.refreshNow();
  return (
    notifier: RealtimeNotifier<List<Eew>>(channel),
    channel: channel,
    elapsed: elapsed,
  );
}

Widget _wrap(RealtimeNotifier<List<Eew>> notifier, RegionStore store) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: ThemeData(brightness: Brightness.light),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<RealtimeNotifier<List<Eew>>>.value(
            value: notifier,
          ),
          ChangeNotifierProvider<RegionStore>.value(value: store),
          Provider<TownDirectory>.value(value: const TownDirectory({})),
          Provider<Future<SeismicTravelTimeTable>>.value(
            value: Future<SeismicTravelTimeTable>.value(
              const SeismicTravelTimeTable({}),
            ),
          ),
          Provider<LocationService>.value(
            value: LocationService(
              const TownDirectory({}),
              isAvailable: () async => false,
              fix: () async => null,
              lastKnown: () async => null,
              status: () async => LocationStatus.denied,
            ),
          ),
        ],
        child: const Scaffold(body: HomeEewSection()),
      ),
    );

Future<RegionStore> _store() async {
  return RegionStore(SettingsStore.inMemory({}));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the alert card while a live alert is active', (
    tester,
  ) async {
    final setup = await _liveNotifier([_alert()]);
    final store = await _store();
    await tester.pumpWidget(_wrap(setup.notifier, store));

    expect(setup.notifier.state.status.name, 'live');
    expect(find.text('花蓮縣'), findsOneWidget);
    // The serial in the section header (the card itself shows the badge, not
    // a second serial).
    expect(find.text('Report 2'), findsOneWidget);
    // Tear down so the card's countdown timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('title and serial sit inside the card, not on the backdrop', (
    tester,
  ) async {
    final setup = await _liveNotifier([_alert()]);
    final store = await _store();
    await tester.pumpWidget(_wrap(setup.notifier, store));

    // The gap between the home sheet's cards is the scroll-dimmed weather sky,
    // not a surface — theme on-surface ink is unreadable there in the light
    // theme. Both header texts must be on the card's opaque plate.
    for (final label in ['Earthquake early warning', 'Report 2']) {
      expect(
        find.ancestor(of: find.text(label), matching: find.byType(Card)),
        findsOneWidget,
        reason: '"$label" must render inside the alert card',
      );
    }

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders nothing when the feed is calm (no alerts)', (
    tester,
  ) async {
    final setup = await _liveNotifier(const []);
    final store = await _store();
    await tester.pumpWidget(_wrap(setup.notifier, store));

    expect(find.text('花蓮縣'), findsNothing);
    expect(find.text('Report 2'), findsNothing);
  });

  testWidgets('renders nothing when the feed has aged past live', (
    tester,
  ) async {
    final setup = await _liveNotifier([_alert()]);
    final store = await _store();
    // Advance past the staleness threshold with no fresh contact, then
    // recompute: the feed keeps its data but is no longer live, and a stale
    // safety feed must not be presented as a current alert.
    setup.elapsed.advance(const Duration(seconds: 4)); // > staleAfter(3)
    setup.channel.recomputeStatus();
    await tester.pumpWidget(_wrap(setup.notifier, store));

    expect(setup.notifier.state.status.name, 'stale');
    expect(find.text('花蓮縣'), findsNothing);
  });
}
