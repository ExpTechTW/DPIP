/// The monitor card is the number someone reads while a wave is still
/// travelling. It has to drop the local estimate when there is no point to
/// estimate for, and it has to say the wave has arrived instead of counting
/// through zero.
library;

import 'dart:async';

import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/map/presentation/widgets/monitor_eew_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _table = SeismicTravelTimeTable({
  10: [(p: 5, r: 20, s: 10), (p: 40, r: 200, s: 80)],
});

TownDirectory _towns() => TownDirectory({
  '100': const Town(
    code: '100',
    city: '花蓮',
    town: '花蓮',
    lat: 23.98,
    lng: 121.6,
    cityLevel: '縣',
    townLevel: '市',
  ),
});

Eew _alert({required int time}) => Eew(
  agency: 'cwa',
  id: '1',
  serial: 1,
  status: 1,
  isFinal: false,
  info: EewInfo(
    time: time,
    longitude: 121.6,
    latitude: 24.8,
    depth: 10,
    magnitude: 6.2,
    location: 'Hualien',
    max: 5,
  ),
);

Widget _card({
  required Eew alert,
  required Future<SeismicTravelTimeTable> table,
  required LocationService location,
  required RegionStore regions,
  VisibleTab? tab,
  Widget? trailing,
  VoidCallback? onTap,
}) {
  final body = MonitorEewCard(alert: alert, trailing: trailing, onTap: onTap);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<RegionStore>.value(value: regions),
      Provider<TownDirectory>.value(value: _towns()),
      Provider<LocationService>.value(value: location),
      Provider<Future<SeismicTravelTimeTable>>.value(value: table),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: tab == null
            ? body
            : VisibleTabScope(visibleTab: tab, child: body),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LocationService location({
    Future<bool> Function()? isAvailable,
    Future<GpsFix?> Function()? fix,
  }) => LocationService(
    _towns(),
    isAvailable: isAvailable ?? (() async => false),
    fix: fix ?? (() async => null),
  );

  testWidgets('no observer drops the local tiles and keeps the summary', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      _card(
        alert: _alert(time: DateTime.now().millisecondsSinceEpoch),
        table: Future.value(_table),
        location: location(),
        regions: RegionStore(SettingsStore.inMemory()),
      ),
    );
    await tester.pump();
    expect(find.text('Hualien'), findsOneWidget);
    expect(find.text(l10n.eewSummary('6.2', '10')), findsOneWidget);
    expect(find.text(l10n.eewSWave), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a past origin at the selected town reads as arrived', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final regions = RegionStore(SettingsStore.inMemory())
      ..setCurrentCode('100');
    await tester.pumpWidget(
      _card(
        alert: _alert(
          time: DateTime.now()
              .subtract(const Duration(hours: 2))
              .millisecondsSinceEpoch,
        ),
        table: Future.value(_table),
        location: location(),
        regions: regions,
      ),
    );
    await tester.pump();
    expect(find.text(l10n.eewSWave), findsOneWidget);
    expect(find.text(l10n.eewArrived), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a future origin counts down, and the table settling rebuilds', (
    tester,
  ) async {
    final gate = Completer<SeismicTravelTimeTable>();
    final regions = RegionStore(SettingsStore.inMemory())
      ..setCurrentCode('100');
    await tester.pumpWidget(
      _card(
        alert: _alert(
          time: DateTime.now()
              .add(const Duration(minutes: 10))
              .millisecondsSinceEpoch,
        ),
        table: gate.future,
        location: location(),
        regions: regions,
      ),
    );
    await tester.pump();
    expect(find.textContaining(RegExp(r'\d+ s')), findsOneWidget);

    gate.complete(_table);
    await tester.pump();
    expect(find.textContaining(RegExp(r'\d+ s')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'a GPS fix is used, a denied fix falls back, and a throw is caught',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final regions = RegionStore(SettingsStore.inMemory())
        ..setCurrentCode('100');
      var taps = 0;

      await tester.pumpWidget(
        _card(
          alert: _alert(
            time: DateTime.now()
                .subtract(const Duration(hours: 2))
                .millisecondsSinceEpoch,
          ),
          table: Future.value(_table),
          location: location(
            isAvailable: () async => true,
            fix: () async => (lat: 22.0, lng: 120.5),
          ),
          regions: regions,
          trailing: const Text('2/3'),
          onTap: () => taps++,
        ),
      );
      await tester.pump();
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text(l10n.eewArrived), findsOneWidget);
      await tester.tap(find.text('Hualien'));
      expect(taps, 1);

      await tester.pumpWidget(
        _card(
          alert: _alert(time: DateTime.now().millisecondsSinceEpoch),
          table: Future.value(_table),
          location: location(
            isAvailable: () async => true,
            fix: () async => throw StateError('gps'),
          ),
          regions: regions,
          tab: VisibleTab(0),
        ),
      );
      await tester.pump();
      expect(find.text('Hualien'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
