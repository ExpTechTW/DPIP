/// The data hub's catalogue.
///
/// Written because a tile silently went missing: the astronomy grid was edited
/// by a text substitution that no longer matched, four entries never landed,
/// and nothing failed — not the analyzer, not a gate, not another test. Every
/// route the hub is supposed to offer is now asserted by name, so the next
/// entry that fails to land fails here instead of on a phone.
library;

import 'package:dpip/features/data/presentation/pages/data_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
      ],
    ),
  ],
);

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  // Tall enough to lay out and *hit-test* the whole hub: the seismic card, the
  // seven-tile weather grid and the seven-tile astronomy grid below it. On a
  // phone the page scrolls; here nothing may fall past the viewport, or a tap
  // silently misses.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pump();
}

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
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router([]),
      ),
    );
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
