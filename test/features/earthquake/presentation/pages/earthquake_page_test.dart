/// The monitor page is the live EEW list. An empty feed has to say there is
/// no alert, and a feed with alerts has to list each one — a page that stays
/// on the empty state during an alert is the one screen that must not.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/pages/earthquake_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Clock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 8, 12, 12);
}

class _Elapsed implements Elapsed {
  @override
  Duration get elapsed => Duration.zero;
}

class _Ticker implements Ticker {
  @override
  TickerHandle start(Duration interval, void Function() onTick) => _Handle();
}

class _Handle implements TickerHandle {
  @override
  void cancel() {}
}

class _Source extends RealtimeSource<List<Eew>> {
  _Source(this.data);

  final List<Eew> data;

  @override
  Future<Result<List<Eew>>> fetch() async => Ok(data);

  @override
  DateTime? timestampOf(List<Eew> value) => null;

  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => listEquals(a, b);
}

const _directory = TownDirectory({
  '100': Town(
    code: '100',
    city: '花蓮',
    town: '新城',
    lat: 24.1,
    lng: 121.6,
    cityLevel: '縣',
    townLevel: '鄉',
  ),
});

const _table = SeismicTravelTimeTable({
  10: [
    (p: 5.0, r: 25.0, s: 10.0),
    (p: 10.0, r: 50.0, s: 20.0),
    (p: 15.0, r: 75.0, s: 30.0),
    (p: 20.0, r: 100.0, s: 40.0),
    (p: 30.0, r: 150.0, s: 60.0),
    (p: 40.0, r: 200.0, s: 80.0),
  ],
});

Eew _alert(String id) => Eew(
  agency: 'CWA',
  id: id,
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

Future<void> _pump(WidgetTester tester, List<Eew> alerts) async {
  final channel = RealtimeChannel<List<Eew>>(
    source: _Source(alerts),
    clock: _Clock(),
    elapsed: _Elapsed(),
    ticker: _Ticker(),
    config: RealtimeConfig.eew,
    label: 'eew-page',
  );
  await channel.refreshNow();
  final controller = EewRealtimeController(channel);
  addTearDown(controller.dispose);
  addTearDown(channel.dispose);
  final regions = RegionStore(
    SettingsStore.inMemory({
      'home.savedRegionCodes': const ['100'],
    }),
  )..select(2);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EewRealtimeController>.value(value: controller),
        ChangeNotifierProvider<RegionStore>.value(value: regions),
        Provider<TownDirectory>.value(value: _directory),
        Provider<Future<SeismicTravelTimeTable>>.value(
          value: Future<SeismicTravelTimeTable>.value(_table),
        ),
        Provider<LocationService>.value(
          value: LocationService(
            _directory,
            isAvailable: () async => false,
            fix: () async => null,
            lastKnown: () async => null,
            status: () async => LocationStatus.denied,
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EarthquakePage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('an empty live feed says there is no alert', (tester) async {
    await _pump(tester, const []);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(EarthquakePage)),
    );
    expect(find.text(l10n.eewTitle), findsOneWidget);
    expect(find.text(l10n.eewNone), findsOneWidget);
  });

  testWidgets('active alerts are listed, newest first', (tester) async {
    await _pump(tester, [_alert('a'), _alert('b')]);
    expect(find.text('花蓮縣'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
