import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/presentation/widgets/eew_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/eew_estimate_tile.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// An alert whose origin sits ~30s in the future, so the S-wave countdown is
/// always positive while the card is pumped (the estimate adds travel seconds on
/// top, keeping it from flipping to "Arrived" mid-test).
Eew _alert() {
  final origin = DateTime.now().toUtc().add(const Duration(seconds: 30));
  return Eew(
    agency: 'CWA',
    id: 'test',
    serial: 3,
    status: 0,
    isFinal: false,
    info: EewInfo(
      time: origin.millisecondsSinceEpoch,
      longitude: 121.5,
      latitude: 23.5,
      depth: 10,
      magnitude: 6.0,
      location: '花蓮縣',
      max: 4,
    ),
  );
}

/// An alert whose origin is already 120s in the past — real now is always past
/// its S-wave arrival, the exact trap the replay page's card must escape by
/// counting down against its own clock instead.
Eew _pastAlert() {
  final origin = DateTime.now().toUtc().subtract(const Duration(seconds: 120));
  return Eew(
    agency: 'CWA',
    id: 'test',
    serial: 3,
    status: 0,
    isFinal: false,
    info: EewInfo(
      time: origin.millisecondsSinceEpoch,
      longitude: 121.5,
      latitude: 23.5,
      depth: 10,
      magnitude: 6.0,
      location: '花蓮縣',
      max: 4,
    ),
  );
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

/// A CWA-style travel-time table for depth 10 km spanning Taiwan's extent, so
/// the countdown resolves against the table (not the analytic fallback).
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

/// Pumps the card with a [RegionStore] whose selection is fixed by [select].
Future<RegionStore> _store({int select = 2}) async {
  final store = RegionStore(
    SettingsStore.inMemory({
      'home.savedRegionCodes': ['100'],
    }),
  );
  store.select(select);
  return store;
}

Widget _wrap(RegionStore store, {Eew? eew, DateTime Function()? clock}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<RegionStore>.value(value: store),
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
        child: Scaffold(
          body: EewCard(eew: eew ?? _alert(), clock: clock),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows serial, max-intensity badge, and summary', (tester) async {
    final store = await _store();
    await tester.pumpWidget(_wrap(store));
    final l10n = AppLocalizations.of(tester.element(find.byType(EewCard)));

    expect(find.text('Report 3'), findsOneWidget);
    expect(find.byType(IntensityBadge), findsOneWidget);
    expect(find.text('花蓮縣'), findsOneWidget);
    expect(find.text(l10n.eewSummary('6.0', '10')), findsOneWidget);
    // Tear down so the countdown timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'shows local estimate + S-wave tiles when a township is selected',
    (tester) async {
      final store = await _store();
      await tester.pumpWidget(_wrap(store));
      final l10n = AppLocalizations.of(tester.element(find.byType(EewCard)));

      expect(find.text(l10n.eewLocalIntensity), findsOneWidget);
      expect(find.text(l10n.eewSWave), findsOneWidget);
      // The countdown value is positive seconds, not "Arrived".
      expect(find.text(l10n.eewArrived), findsNothing);

      // The local-estimate tile's colour must agree with the level it
      // actually displays — not a fixed colour no matter how big the
      // estimated shaking is (the S-wave tile stays fixed alert red; only
      // the local-intensity one is level-scaled).
      final tile = tester.widget<EewEstimateTile>(
        find.widgetWithText(EewEstimateTile, l10n.eewLocalIntensity),
      );
      final level = [
        for (var i = 0; i <= 9; i++)
          if (Intensity.label(i) == tile.value) i,
      ].single;
      expect(tile.background, IntensityColors.discrete(level));
      expect(tile.foreground, IntensityColors.onDiscrete(level));

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('drops the local tiles for 全國 (no observer point)', (
    tester,
  ) async {
    final store = await _store(select: 0); // NationwideArea
    await tester.pumpWidget(_wrap(store));
    final l10n = AppLocalizations.of(tester.element(find.byType(EewCard)));

    expect(find.text(l10n.eewLocalIntensity), findsNothing);
    expect(find.text(l10n.eewSWave), findsNothing);
    // The summary still renders — only the observer-dependent tiles drop.
    expect(find.text('Report 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'a caller clock before arrival keeps a past alert counting down',
    (tester) async {
      final store = await _store();
      final alert = _pastAlert();
      final origin = DateTime.fromMillisecondsSinceEpoch(alert.info.time);
      // The alert happened 2 minutes ago on the wall clock, but the caller's
      // timeline (the replay clock) has only advanced 10s since the origin —
      // the S-wave must still be inbound, not "Arrived".
      await tester.pumpWidget(
        _wrap(
          store,
          eew: alert,
          clock: () => origin.add(const Duration(seconds: 10)),
        ),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(EewCard)));

      expect(find.text(l10n.eewSWave), findsOneWidget);
      expect(find.text(l10n.eewArrived), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a caller clock past arrival shows arrived', (tester) async {
    final store = await _store();
    final alert = _pastAlert();
    final origin = DateTime.fromMillisecondsSinceEpoch(alert.info.time);
    await tester.pumpWidget(
      _wrap(
        store,
        eew: alert,
        clock: () => origin.add(const Duration(seconds: 500)),
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(EewCard)));

    expect(find.text(l10n.eewArrived), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
