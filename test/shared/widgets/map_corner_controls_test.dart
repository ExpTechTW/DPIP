/// The map's top-left control row, mounted the way both surfaces mount it —
/// the live monitor through `MapScaffold`, the replay page directly.
///
/// Guards what the layout promises: one panel open at a time, the open card
/// dropping into the row *below* the buttons so the row never moves under the
/// finger that opened it, and a feed that stops taking its whole panel off the
/// map rather than freezing a reading on screen.
library;

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_corner_controls.dart';
import 'package:dpip/shared/widgets/map_intensity_ranking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TownDirectory _directory() => TownDirectory.fromJson({
  '100': {
    'city': '臺北',
    'town': '中正',
    'lat': 25.03,
    'lng': 121.52,
    'cityLevel': '市',
    'townLevel': '區',
  },
  '970': {
    'city': '花蓮',
    'town': '花蓮',
    'lat': 23.99,
    'lng': 121.60,
    'cityLevel': '縣',
    'townLevel': '市',
  },
});

/// Stands in for the monitor: a stub legend, and the 震度排行榜 panel driven by
/// [areas] exactly as `RtsMapLayer.buildLegendPanel` drives it from the feed.
Future<void> _pump(
  WidgetTester tester,
  ValueNotifier<List<IntensityRankingEntry>?> areas,
) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home: Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: MapCornerControls(
              legend: const Text('圖例內容'),
              panel: MapCornerPanel(
                icon: Icons.leaderboard_outlined,
                tooltip: '震度排行',
                listenable: areas,
                build: (context) {
                  final value = areas.value;
                  if (value == null) return null;
                  return (
                    card: IntensityRankingCard(
                      areas: value,
                      directory: _directory(),
                    ),
                    badge: value.isEmpty
                        ? null
                        : IntensityRankingBadge(
                            intensity: value.first.intensity,
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('nothing to rank takes the whole button off the row', (
    tester,
  ) async {
    await _pump(tester, ValueNotifier(null));

    expect(find.byIcon(Icons.leaderboard_outlined), findsNothing);
    expect(
      find.byIcon(Icons.legend_toggle),
      findsOneWidget,
      reason: 'the legend is the layer\'s own and stays either way',
    );
  });

  testWidgets('a calm feed keeps the button and says so when opened', (
    tester,
  ) async {
    await _pump(tester, ValueNotifier(const []));

    expect(find.byIcon(Icons.leaderboard_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.leaderboard_outlined));
    await tester.pumpAndSettle();

    expect(find.text('目前無區域觸發'), findsOneWidget);
  });

  testWidgets('opening lists the townships by name, strongest first', (
    tester,
  ) async {
    await _pump(
      tester,
      ValueNotifier(const [
        (code: '970', intensity: 5),
        (code: '100', intensity: 2),
      ]),
    );

    // Closed, the button already carries the strongest reading.
    expect(find.text('5⁻'), findsOneWidget);
    expect(find.text('花蓮縣 花蓮市'), findsNothing);

    await tester.tap(find.byIcon(Icons.leaderboard_outlined));
    await tester.pumpAndSettle();

    expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
    expect(find.text('臺北市 中正區'), findsOneWidget);
    final hualien = tester.getTopLeft(find.text('花蓮縣 花蓮市')).dy;
    final taipei = tester.getTopLeft(find.text('臺北市 中正區')).dy;
    expect(hualien, lessThan(taipei));
  });

  testWidgets('a code the directory does not know still names its row', (
    tester,
  ) async {
    await _pump(tester, ValueNotifier(const [(code: '999', intensity: 3)]));
    await tester.tap(find.byIcon(Icons.leaderboard_outlined));
    await tester.pumpAndSettle();

    expect(find.text('999'), findsOneWidget);
  });

  testWidgets('the panel opens below the row, and its own button closes it', (
    tester,
  ) async {
    await _pump(tester, ValueNotifier(const [(code: '970', intensity: 5)]));

    // Closed, the button carries no name — the tooltip does.
    expect(find.text('震度排行'), findsNothing);
    final before = tester.getTopLeft(find.byIcon(Icons.leaderboard_outlined));

    await tester.tap(find.byIcon(Icons.leaderboard_outlined));
    await tester.pumpAndSettle();

    expect(find.text('震度排行'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byIcon(Icons.leaderboard_outlined)),
      before,
      reason: 'the card grows downwards; the row it opened from must not move',
    );
    expect(
      tester.getTopLeft(find.text('震度排行')).dy,
      greaterThan(before.dy),
      reason: 'the card belongs in the slot under the buttons, not beside them',
    );

    await tester.tap(find.byIcon(Icons.leaderboard_outlined));
    await tester.pumpAndSettle();
    expect(find.text('花蓮縣 花蓮市'), findsNothing);
  });

  testWidgets('the legend and the ranking take the same slot, so only one of '
      'them is ever open', (tester) async {
    await _pump(tester, ValueNotifier(const [(code: '970', intensity: 5)]));

    await tester.tap(find.byIcon(Icons.legend_toggle));
    await tester.pumpAndSettle();
    expect(find.text('圖例內容'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.leaderboard_outlined));
    await tester.pumpAndSettle();

    expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
    expect(
      find.text('圖例內容'),
      findsNothing,
      reason: 'the ranking took the slot; the legend cannot still hold it',
    );
  });

  testWidgets('the feed ticking does not close an opened panel', (
    tester,
  ) async {
    final areas = ValueNotifier<List<IntensityRankingEntry>?>(const [
      (code: '970', intensity: 5),
    ]);
    addTearDown(areas.dispose);
    await _pump(tester, areas);
    await tester.tap(find.byIcon(Icons.leaderboard_outlined));
    await tester.pumpAndSettle();

    // ~1 Hz, for as long as the user leaves it open.
    areas.value = const [
      (code: '970', intensity: 6),
      (code: '100', intensity: 2),
    ];
    await tester.pumpAndSettle();

    expect(find.text('臺北市 中正區'), findsOneWidget);
  });

  testWidgets('a feed that stops mid-shake takes the open card with it', (
    tester,
  ) async {
    final areas = ValueNotifier<List<IntensityRankingEntry>?>(const [
      (code: '970', intensity: 5),
    ]);
    addTearDown(areas.dispose);
    await _pump(tester, areas);
    await tester.tap(find.byIcon(Icons.leaderboard_outlined));
    await tester.pumpAndSettle();
    expect(find.text('花蓮縣 花蓮市'), findsOneWidget);

    // Stale or offline: the ranking may not outlive the freshness of the data
    // it was read from.
    areas.value = null;
    await tester.pumpAndSettle();

    expect(find.text('花蓮縣 花蓮市'), findsNothing);
    expect(find.byIcon(Icons.leaderboard_outlined), findsNothing);
  });
}
