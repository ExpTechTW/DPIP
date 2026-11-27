/// The data hub's catalogue.
///
/// Written because a tile silently went missing: the astronomy grid was edited
/// by a text substitution that no longer matched, four entries never landed,
/// and nothing failed — not the analyzer, not a gate, not another test. Every
/// route the hub is supposed to offer is now asserted by name, so the next
/// entry that fails to land fails here instead of on a phone.
library;

import 'dart:async';

import 'package:dpip/core/platform/device_sensors.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/data/presentation/pages/data_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Every destination the astronomy section must offer, with the English label
/// the tile carries.
const _astronomyTiles = <(String, String)>[
  (AppRoutes.moon, 'Moon'),
  (AppRoutes.sun, 'Sun'),
  (AppRoutes.planets, 'Planets'),
  (AppRoutes.tonight, 'Tonight'),
  (AppRoutes.skyChart, 'Sky chart'),
  (AppRoutes.almanac, 'Almanac'),
  (AppRoutes.tide, 'Tide'),
];

/// A router that records where a tap tried to go, without building the target
/// page — the point here is the catalogue, not its destinations.
GoRouter _router(List<String> visited) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const DataPage(),
      routes: [
        for (final (name, _) in _astronomyTiles)
          GoRoute(
            path: name,
            name: name,
            builder: (_, _) {
              visited.add(name);
              return const SizedBox.shrink();
            },
          ),
        GoRoute(
          path: 'weather-ranking',
          name: AppRoutes.weatherRanking,
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: 'earthquake',
          name: AppRoutes.earthquake,
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: AppRoutes.seismometerPath,
          name: AppRoutes.seismometer,
          builder: (_, _) {
            visited.add(AppRoutes.seismometer);
            return const SizedBox.shrink();
          },
        ),
      ],
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  ExperimentalSettings? settings,
  DeviceSensors? sensors,
}) async {
  // Tall enough to lay out and *hit-test* the whole hub: the seismic cards, the
  // seven-tile weather grid and the seven-tile astronomy grid below it. On a
  // phone the page scrolls; here nothing may fall past the viewport, or a tap
  // silently misses.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(router, settings ?? _settings(), sensors: sensors),
  );
  await tester.pump();
}

ExperimentalSettings _settings() =>
    ExperimentalSettings(SettingsStore.inMemory());

/// The hub under [router], with the experimental settings it reads, on a
/// device with [sensors] — one with an accelerometer unless a test says
/// otherwise.
Widget _app(
  GoRouter router,
  ExperimentalSettings settings, {
  DeviceSensors? sensors,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: settings),
    ChangeNotifierProvider.value(
      value: sensors ?? DeviceSensors.known(const {DeviceSensor.accelerometer}),
    ),
  ],
  child: MaterialApp.router(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ),
);

void main() {
  testWidgets('offers every astronomy page', (tester) async {
    await _pump(tester, _router([]));
    for (final (route, label) in _astronomyTiles) {
      expect(find.text(label), findsOneWidget, reason: '$route tile missing');
    }
  });

  testWidgets('astronomy sits below weather', (tester) async {
    await _pump(tester, _router([]));
    final weather = tester.getTopLeft(find.text('Weather')).dy;
    final astronomy = tester.getTopLeft(find.text('Astronomy')).dy;
    expect(astronomy, greaterThan(weather));
  });

  testWidgets('a tablet gets more columns, not taller tiles', (tester) async {
    // An iPad in landscape. The grid used to be two fixed columns whose height
    // came from a `childAspectRatio`, so the wider the screen the taller the
    // tile: 668 pt columns gave 278 pt cells, each holding one line of label
    // in the middle of an otherwise empty card.
    tester.view.physicalSize = const Size(2752, 2064);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(_router([]), _settings()));
    await tester.pump();

    final tile = tester.getRect(
      find
          .ancestor(of: find.text('Moon'), matching: find.byType(InkWell))
          .first,
    );
    expect(
      tile.height,
      lessThan(120),
      reason: 'tile height, not a screen slice',
    );
    // Four columns of ~330, not two of ~670.
    expect(tile.width, lessThan(400));
  });

  // The 375 pt SE, the 390 pt iPhone 12, and the 320 pt phone below both. The
  // SE used to fall on the far side of the grid's width test and draw the hub
  // as a column of full-width bars while the phone next to it drew a grid.
  for (final (name, logical) in const <(String, Size)>[
    ('iPhone SE', Size(375, 667)),
    ('iPhone 12', Size(390, 844)),
    ('a 320 pt phone', Size(320, 568)),
  ]) {
    testWidgets('$name lays the hub out in two columns', (tester) async {
      tester.view.physicalSize = logical * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(_router([]), _settings()));
      await tester.pump();

      Rect tileOf(String label) => tester.getRect(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      final rain = tileOf('Rainfall');
      final temperature = tileOf('Temperature');

      expect(
        temperature.top,
        rain.top,
        reason: 'the first two metrics share a row, they do not stack',
      );
      expect(
        rain.width,
        lessThan(logical.width / 2),
        reason: 'a tile is a grid cell, not a full-width bar',
      );
    });
  }

  testWidgets('the seismometer is not listed until its option is on', (
    tester,
  ) async {
    final settings = _settings();
    await _pump(tester, _router([]), settings: settings);
    expect(settings.seismometerEnabled, isFalse);
    expect(find.text('Seismometer'), findsNothing);
    // The rest of the seismic section is untouched.
    expect(find.text('Earthquake reports'), findsOneWidget);
  });

  testWidgets('the seismometer card follows its option live', (tester) async {
    final settings = _settings();
    await _pump(tester, _router([]), settings: settings);
    expect(find.text('Seismometer'), findsNothing);

    await settings.setSeismometerEnabled(true);
    await tester.pump();
    expect(find.text('Seismometer'), findsOneWidget);
    // It sits with the seismic entries, above the weather section.
    expect(
      tester.getTopLeft(find.text('Seismometer')).dy,
      lessThan(tester.getTopLeft(find.text('Weather')).dy),
    );

    await settings.setSeismometerEnabled(false);
    await tester.pump();
    expect(find.text('Seismometer'), findsNothing);
  });

  testWidgets('no accelerometer, no seismometer card, even switched on', (
    tester,
  ) async {
    // A switch restored from a backup taken on another phone can be on here,
    // where the Experimental features page does not even offer it.
    final settings = _settings();
    await settings.setSeismometerEnabled(true);
    await _pump(
      tester,
      _router([]),
      settings: settings,
      sensors: DeviceSensors.known(const {}),
    );
    expect(find.text('Seismometer'), findsNothing);
    expect(find.text('Earthquake reports'), findsOneWidget);
  });

  testWidgets('the seismometer card waits for the accelerometer answer', (
    tester,
  ) async {
    final answer = Completer<bool>();
    final sensors = DeviceSensors(
      probes: {DeviceSensor.accelerometer: () => answer.future},
    );
    unawaited(sensors.resolve());
    final settings = _settings();
    await settings.setSeismometerEnabled(true);
    await _pump(tester, _router([]), settings: settings, sensors: sensors);
    // Unknown is treated as absent: the card may arrive late, but it never
    // shows and then disappears.
    expect(find.text('Seismometer'), findsNothing);

    answer.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Seismometer'), findsOneWidget);
  });

  testWidgets('the seismometer card opens the seismometer route', (
    tester,
  ) async {
    final visited = <String>[];
    final settings = _settings();
    await settings.setSeismometerEnabled(true);
    await _pump(tester, _router(visited), settings: settings);
    expect(find.text('Seismometer'), findsOneWidget);
    await tester.tap(find.text('Seismometer'));
    await tester.pumpAndSettle();
    expect(visited, [AppRoutes.seismometer]);
  });

  for (final (route, label) in _astronomyTiles) {
    testWidgets('the $label tile navigates to $route', (tester) async {
      // A fresh router per tile: a tile wired to the wrong route would
      // otherwise be masked by an earlier tap having already visited it.
      final visited = <String>[];
      await _pump(tester, _router(visited));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(visited, [route]);
    });
  }
}
