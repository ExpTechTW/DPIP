import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/core/settings/eew_spoken_announcement_settings.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/speech/speech_service.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:dpip/features/map/presentation/widgets/rts_monitor_panel.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
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
    RealtimeChannel<Rts> rtsChannel,
    _FakeElapsed rtsElapsed,
    RealtimeChannel<List<Eew>> eewChannel,
    _FakeElapsed eewElapsed,
  })
>
_liveFeeds({List<Eew> alerts = const [], int rtsTime = 0}) async {
  final rtsElapsed = _FakeElapsed();
  final rtsChannel = RealtimeChannel<Rts>(
    source: _StaticSource<Rts>(Rts(time: rtsTime)),
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
    rtsChannel: rtsChannel,
    rtsElapsed: rtsElapsed,
    eewChannel: eewChannel,
    eewElapsed: eewElapsed,
  );
}

class _Speech implements SpeechService {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text, {required String languageTag}) async {
    spoken.add('$languageTag:$text');
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

Widget _wrap(
  RealtimeNotifier<Rts> rts,
  RealtimeNotifier<List<Eew>> eew,
  RegionStore store, {
  ValueNotifier<int>? eewIndex,
  SpeechService? speech,
  NotificationService? notifications,
  EewSpokenAnnouncementSettings? speechSettings,
  VisibleTab? visibleTab,
  Future<GpsFix?> Function()? lastKnown,
}) {
  final panel = RtsMonitorPanel(
    feed: rts,
    eew: eew,
    eewIndex: eewIndex ?? ValueNotifier(0),
  );
  final body = Scaffold(body: panel);
  return MaterialApp(
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
            lastKnown: lastKnown ?? () async => null,
            status: () async => LocationStatus.denied,
          ),
        ),
        if (speech != null) Provider<SpeechService?>.value(value: speech),
        if (notifications != null)
          Provider<NotificationService?>.value(value: notifications),
        if (speechSettings != null)
          ChangeNotifierProvider<EewSpokenAnnouncementSettings?>.value(
            value: speechSettings,
          ),
      ],
      child: visibleTab == null
          ? body
          : VisibleTabScope(visibleTab: visibleTab, child: body),
    ),
  );
}

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

  testWidgets(
    'the strip names a snapshot clock and ages into stale then offline',
    (tester) async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final fresh = await _liveFeeds(rtsTime: now - 100);
      final store = await _store();
      await tester.pumpWidget(_wrap(fresh.rts, fresh.eew, store));
      expect(find.textContaining('Delay'), findsOneWidget);
      expect(
        tester.widget<Text>(find.textContaining('Delay')).style?.color,
        Colors.green,
      );
      expect(find.textContaining(':'), findsWidgets);
      await tester.pumpWidget(const SizedBox());

      final lagged = await _liveFeeds(rtsTime: now - 1500);
      await tester.pumpWidget(_wrap(lagged.rts, lagged.eew, store));
      expect(
        tester.widget<Text>(find.textContaining('Delay')).style?.color,
        Colors.orange,
      );
      await tester.pumpWidget(const SizedBox());

      final late = await _liveFeeds(rtsTime: now + 5000);
      await tester.pumpWidget(_wrap(late.rts, late.eew, store));
      expect(find.text('Delay 0 ms'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());

      final behind = await _liveFeeds(rtsTime: now - 5000);
      await tester.pumpWidget(_wrap(behind.rts, behind.eew, store));
      expect(
        tester.widget<Text>(find.textContaining('Delay')).style?.color,
        Colors.red,
      );

      behind.rtsElapsed.advance(const Duration(seconds: 4));
      behind.rtsChannel.recomputeStatus();
      await tester.pump();
      expect(find.text('Data may be out of date'), findsOneWidget);

      behind.rtsElapsed.advance(const Duration(seconds: 20));
      behind.rtsChannel.recomputeStatus();
      // The channel publishes on a later microtask, so the strip rebuilds on
      // the frame after the one that delivers the event.
      await tester.pump();
      await tester.pump();
      expect(find.text('Connection lost'), findsOneWidget);

      final connecting = RealtimeChannel<Rts>(
        source: _StaticSource<Rts>(const Rts()),
        clock: _FakeClock(DateTime.utc(2026, 8, 12, 12)),
        elapsed: _FakeElapsed(),
        ticker: _FakeTicker(),
        config: RealtimeConfig.rts,
        label: 'test-rts-connecting',
      );
      final calm = await _liveFeeds();
      await tester.pumpWidget(
        _wrap(RealtimeNotifier<Rts>(connecting), calm.eew, store),
      );
      expect(find.text('Connecting…'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('speech follows the visible tab, the lifecycle, and a new feed', (
    tester,
  ) async {
    final settings = SettingsStore.inMemory({});
    await settings.setBool(SettingKeys.eewSpokenAnnouncement, true);
    final speechSettings = EewSpokenAnnouncementSettings(settings);
    final speech = _Speech();
    final visible = VisibleTab(MapPage.tabIndex);
    final feeds = await _liveFeeds(alerts: [_alert()]);
    final store = await _store();

    await tester.pumpWidget(
      _wrap(
        feeds.rts,
        feeds.eew,
        store,
        speech: speech,
        notifications: NotificationService(settings),
        speechSettings: speechSettings,
        visibleTab: visible,
        lastKnown: () async => (lat: 25.04, lng: 121.51),
      ),
    );
    await tester.pump();
    expect(speech.spoken, isNotEmpty);

    visible.value = 0;
    await tester.pump();
    visible.value = MapPage.tabIndex;
    await tester.pump();
    visible.shellOnTop = false;
    await tester.pump();
    visible.shellOnTop = true;
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    final replacement = await _liveFeeds(alerts: [_alert(id: 'b')]);
    await tester.pumpWidget(
      _wrap(
        replacement.rts,
        replacement.eew,
        store,
        speech: speech,
        notifications: NotificationService(settings),
        speechSettings: speechSettings,
        visibleTab: visible,
        lastKnown: () async => (lat: 25.04, lng: 121.51),
      ),
    );
    await tester.pump();

    await speechSettings.setEnabled(false);
    await tester.pump();

    visible.shellOnTop = false;
    await tester.pump();
    await tester.pumpWidget(
      _wrap(
        replacement.rts,
        replacement.eew,
        store,
        speech: speech,
        notifications: NotificationService(settings),
        speechSettings: speechSettings,
      ),
    );
    await tester.pump();

    // A fresh panel with no cached fix announces the warning's own maximum.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      _wrap(
        replacement.rts,
        replacement.eew,
        store,
        speech: speech,
        notifications: NotificationService(settings),
        speechSettings: speechSettings,
        visibleTab: visible..shellOnTop = true,
        lastKnown: () async => null,
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
  });
}
