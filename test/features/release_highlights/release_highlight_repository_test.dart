/// Release-highlight repository: the current version's Dart content decodes
/// into valid decks — the data the app actually ships.
library;

import 'package:dpip/features/release_highlights/data/release_highlight_repository.dart';
import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = ReleaseHighlightRepositoryImpl();

  for (final kind in HighlightKind.values) {
    final name = kind.name;
    group('$name deck', () {
      final deck = repo.load(kind);

      test('has a title and subtitle in every shipped locale', () {
        final tags = {'zh_Hant', 'en'};
        for (final t in tags) {
          expect(deck.title[t], isNotNull, reason: 'title[$t]');
          expect(deck.subtitle[t], isNotNull, reason: 'subtitle[$t]');
        }
      });

      test('every card has an id, icon, and localized title', () {
        expect(deck.cards, isNotEmpty);

        for (final card in deck.cards) {
          expect(card.id, isNotEmpty);
          expect(card.icon, isNotEmpty);
          expect(card.title['zh_Hant'], isNotEmpty);
        }
      });

      test('technical cards carry at least one detail row, others none', () {
        for (final card in deck.cards) {
          expect(
            card.isTechnical,
            card.details.isNotEmpty,
            reason: '${card.id} isTechnical vs details: ${card.details.length}',
          );
        }
      });
    });
  }
}
