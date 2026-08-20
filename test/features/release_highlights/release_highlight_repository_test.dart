/// Release-highlight repository: the current version's Dart content decodes
/// into valid decks — the data the app actually ships.
library;

import 'package:dpip/features/release_highlights/data/release_highlight_repository.dart';
import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = ReleaseHighlightRepositoryImpl();

  const shippedLocaleTags = {
    'zh_Hant',
    'zh_Hans',
    'en',
    'ja',
    'ko',
    'th',
    'vi',
    'id',
    'fil',
  };

  for (final kind in HighlightKind.values) {
    final name = kind.name;
    group('$name deck', () {
      final deck = repo.load(kind);

      test('has a title and subtitle in every shipped locale', () {
        for (final t in shippedLocaleTags) {
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

  test('ships only implementation-backed user highlights', () {
    final deck = repo.load(HighlightKind.normal);

    expect(
      deck.cards.map((card) => card.id),
      orderedEquals(['speed', 'data', 'map', 'time', 'privacy']),
    );
  });

  test('ships only implementation-backed technical highlights', () {
    final deck = repo.load(HighlightKind.advanced);

    expect(
      deck.cards.map((card) => card.id),
      orderedEquals([
        'etag_core',
        'region_failover',
        'sse_stream',
        'dual_db',
        'map_engine',
        'app_time',
        'logging',
      ]),
    );

    final appTime = deck.cards.singleWhere((card) => card.id == 'app_time');
    expect(appTime.body!['en'], contains('core/realtime/ntp_time_source.dart'));
  });
}
