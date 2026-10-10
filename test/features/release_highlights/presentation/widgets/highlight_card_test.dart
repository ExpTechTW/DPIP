/// A highlight tile is the only place a release card opens. An unknown icon
/// that throws, or a body that stays hidden after expand, would drop a
/// version note the user cannot read.
library;

import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:dpip/features/release_highlights/presentation/widgets/highlight_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknown icon names fall back to a question mark', () {
    expect(highlightIcon('bolt'), Icons.bolt_outlined);
    expect(highlightIcon('not-a-real-icon'), Icons.question_mark_outlined);
  });

  testWidgets('expanding a card reveals the body and bullets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: ReleaseHighlightGroup(
            cards: const [
              ReleaseHighlightCard(
                id: 'maps',
                icon: 'map',
                title: {'en': 'Maps'},
                headline: {'en': 'Faster tiles'},
                stat: {'en': '2×'},
                body: {'en': 'The map now caches tiles.'},
                statLabel: {'en': 'versus last build'},
                highlights: [
                  {'en': 'Fewer blank tiles'},
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Maps'), findsOneWidget);
    expect(find.text('Faster tiles'), findsOneWidget);
    expect(find.text('2×'), findsOneWidget);
    expect(find.text('The map now caches tiles.'), findsNothing);

    await tester.tap(find.text('Maps'));
    await tester.pumpAndSettle();
    expect(find.text('The map now caches tiles.'), findsOneWidget);
    expect(find.text('versus last build'), findsOneWidget);
    expect(find.text('Fewer blank tiles'), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
  });

  testWidgets('a technical card shows its details and its stat rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: Scaffold(
          body: TechnicalHighlightGroup(
            cards: [
              ReleaseHighlightCard(
                id: 'cache',
                icon: 'query_stats',
                title: {'en': 'Cache'},
                body: {'en': 'Tiles stay on disk.'},
                details: [
                  HighlightDetail(
                    key: {'en': 'Store'},
                    value: {'en': 'SQLite'},
                  ),
                  HighlightDetail(
                    key: {'en': 'Budget'},
                    value: {'en': '48 MB'},
                  ),
                ],
                stats: [
                  HighlightStat(value: {'en': '350'}, label: {'en': 'MiB'}),
                  HighlightStat(value: {'en': '12'}, label: {'en': 'frames'}),
                ],
              ),
              ReleaseHighlightCard(
                id: 'numbers',
                icon: 'query_stats',
                title: {'en': 'Numbers only'},
                stats: [
                  HighlightStat(value: {'en': '2'}, label: {'en': 'radios'}),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Collapsed tiles keep the rows out of the tree. Open both so the
    // spacer between a body and its stats, and a stats-only card, both build.
    await tester.tap(find.text('Cache'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Numbers only'));
    await tester.pumpAndSettle();

    expect(find.text('Tiles stay on disk.'), findsOneWidget);
    expect(find.text('SQLite'), findsOneWidget);
    expect(find.text('48 MB'), findsOneWidget);
    expect(find.text('350'), findsOneWidget);
    expect(find.text('MiB'), findsOneWidget);
    expect(find.text('frames'), findsOneWidget);
    expect(find.text('radios'), findsOneWidget);
    expect(find.byIcon(Icons.query_stats_outlined), findsWidgets);
  });
}
