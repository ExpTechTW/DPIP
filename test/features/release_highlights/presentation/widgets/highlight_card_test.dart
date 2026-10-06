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
}
