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
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/map/presentation/widgets/rts_monitor_panel.dart';
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

class _StaticSource<T> extends RealtimeSource<T> {
  _StaticSource(this.data);
  final T data;

  @override
  Future<Result<T>> fetch() async => Ok(data);

  @override
  DateTime? timestampOf(T value) => null;

  @override
  bool sameData(T? a, T? b) {
    if (a is List && b is List) return listEquals(a, b);
    return a == b;
  }
}

Eew _alert({String id = 'a', String location = '花蓮縣'}) => Eew(
  agency: 'CWA',
  id: id,
  serial: 2,
  status: 0,
  isFinal: false,
  info: EewInfo(
    time: 1786362600000,
    longitude: 121.5,
    latitude: 23.5,
    depth: 10,
    magnitude: 6.0,
    location: location,
    max: 4,
  ),
);

Future<
  ({
    RealtimeNotifier<Rts> rts,
    RealtimeNotifier<List<Eew>> eew,
    RealtimeChannel<List<Eew>> eewChannel,
    _FakeElapsed eewElapsed,
  })
>
_liveFeeds({List<Eew> alerts = const []}) async {
  final rtsElapsed = _FakeElapsed();
  final rtsChannel = RealtimeChannel<Rts>(
    source: _StaticSource<Rts>(const Rts()),
    clock: _FakeClock(DateTime.utc(2026, 8, 12, 12)),
    elapsed: rtsElapsed,
    ticker: _FakeTicker(),
    config: RealtimeConfig.rts,
    label: 'test-rts',
  );
  await rtsChannel.refreshNow();

  final eewElapsed = _FakeElapsed();
  final eewChannel = RealtimeChannel<List<Eew>>(
    source: _StaticSource<List<Eew>>(alerts),
    clock: _FakeClock(DateTime.utc(2026, 8, 12, 12)),
    elapsed: eewElapsed,
    ticker: _FakeTicker(),
    config: RealtimeConfig.eew,
    label: 'test-eew',
  );
  await eewChannel.refreshNow();

  return (
    rts: RealtimeNotifier<Rts>(rtsChannel),
    eew: RealtimeNotifier<List<Eew>>(eewChannel),
    eewChannel: eewChannel,
    eewElapsed: eewElapsed,
  );
}

Widget _wrap(
  RealtimeNotifier<Rts> rts,
  RealtimeNotifier<List<Eew>> eew,
  RegionStore store, {
  ValueNotifier<int>? eewIndex,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: MultiProvider(
    providers: [
      ChangeNotifierProvider<RealtimeNotifier<Rts>>.value(value: rts),
      ChangeNotifierProvider<RealtimeNotifier<List<Eew>>>.value(value: eew),
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
    child: Scaffold(
      body: RtsMonitorPanel(
        feed: rts,
        eew: eew,
        eewIndex: eewIndex ?? ValueNotifier(0),
      ),
    ),
  ),
);

Future<RegionStore> _store() async {
  return RegionStore(SettingsStore.inMemory({}));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'shows one alert at a time and cycles to the rest on tap (multi-report)',
    (tester) async {
      final feeds = await _liveFeeds(
        alerts: [
          _alert(id: 'a', location: '花蓮縣'),
          _alert(id: 'b', location: '臺東縣'),
        ],
      );
      final store = await _store();
      await tester.pumpWidget(_wrap(feeds.rts, feeds.eew, store));

      // The status strip is still there underneath the alert card, and only
      // the first alert shows — the rest are a tap away, not a stacked list.
      expect(find.text('Seismic Monitor'), findsOneWidget);
      expect(find.text('花蓮縣'), findsOneWidget);
      expect(find.text('臺東縣'), findsNothing);
      expect(find.text('1/2'), findsOneWidget);

      await tester.tap(find.text('花蓮縣'));
      await tester.pump();

      expect(find.text('花蓮縣'), findsNothing);
      expect(find.text('臺東縣'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);

      // Tear down so each card's countdown timer is cancelled.
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('shows only the status strip while calm (no alerts)', (
    tester,
  ) async {
    final feeds = await _liveFeeds();
    final store = await _store();
    await tester.pumpWidget(_wrap(feeds.rts, feeds.eew, store));

    expect(find.text('Seismic Monitor'), findsOneWidget);
    expect(find.text('花蓮縣'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'the status strip turns red-on-errorContainer while an alert is active, '
    'and back to plain once calm',
    (tester) async {
      // Finds the status strip's own Container by its distinctive boxShadow —
      // both branches of its decoration set one, so this works whether the
      // strip is currently tinted for an active alert or not, without
      // guessing at ancestor ordering through the Scaffold/MaterialApp frame.
      Finder statusStripContainer() => find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).boxShadow != null,
      );

      final feeds = await _liveFeeds(alerts: [_alert()]);
      final store = await _store();
      await tester.pumpWidget(_wrap(feeds.rts, feeds.eew, store));

      final colors = Theme.of(tester.element(find.text('Seismic Monitor')))
          .colorScheme;

      final active =
          tester.widget<Container>(statusStripContainer()).decoration!
              as BoxDecoration;
      expect(
        active.color,
        colors.errorContainer.withValues(alpha: 0.94),
        reason:
            'an active alert must tint the whole strip, like the legacy '
            "monitor's sheet did",
      );
      expect(
        active.border,
        isNotNull,
        reason: 'an active alert must give the strip a red border too',
      );

      await tester.pumpWidget(const SizedBox());

      final calmFeeds = await _liveFeeds();
      await tester.pumpWidget(_wrap(calmFeeds.rts, calmFeeds.eew, store));
      final calm =
          tester.widget<Container>(statusStripContainer()).decoration!
              as BoxDecoration;
      expect(
        calm.color,
        colors.surface.withValues(alpha: 0.94),
        reason: 'the tint must not linger once there is nothing active',
      );
      expect(calm.border, isNull);

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('drops the alert cards once the EEW feed has aged past live', (
    tester,
  ) async {
    final feeds = await _liveFeeds(alerts: [_alert()]);
    final store = await _store();
    // Advance past the staleness threshold with no fresh contact, then
    // recompute: the feed keeps its data but is no longer live, and a stale
    // alert must not be presented as a current one.
    feeds.eewElapsed.advance(const Duration(seconds: 4)); // > staleAfter(3)
    feeds.eewChannel.recomputeStatus();
    await tester.pumpWidget(_wrap(feeds.rts, feeds.eew, store));

    expect(feeds.eew.state.status.name, 'stale');
    expect(find.text('Seismic Monitor'), findsOneWidget);
    expect(find.text('花蓮縣'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
