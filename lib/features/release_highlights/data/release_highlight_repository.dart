/// Loads the current cycle's highlight cards from the content package.
///
/// Highlights are written once per *cycle*, not per train: every 26 release
/// reads the same `26.x` deck, and 27 opens a new one. They live as Dart source
/// in `package:dpip_release_highlights` (`lib/<cycle>/{normal,advanced}.dart`)
/// — the current cycle's files are imported below. Closed cycles stay in the
/// package as the archive and are never compiled into a build. When a cycle
/// opens, replace these two imports with its own; nothing else changes.
///
/// Content is authored as JSON at
/// `release_highlights/assets/<cycle>/…/cards.json` and compiled to Dart by
/// `tool/gen/release_highlights.py`.
library;

import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:dpip_release_highlights/26.x/advanced.dart' as current_advanced;
import 'package:dpip_release_highlights/26.x/normal.dart' as current_normal;

/// Stateless loader that assembles [HighlightDeck]s from the current version's
/// Dart content.
class ReleaseHighlightRepositoryImpl implements ReleaseHighlightRepository {
  const ReleaseHighlightRepositoryImpl();

  @override
  HighlightDeck load(HighlightKind kind) => switch (kind) {
    HighlightKind.normal => HighlightDeck(
      kind: kind,
      title: current_normal.title,
      subtitle: current_normal.subtitle,
      cards: [
        for (final c in current_normal.cards) ReleaseHighlightCard.fromJson(c),
      ],
    ),
    HighlightKind.advanced => HighlightDeck(
      kind: kind,
      title: current_advanced.title,
      subtitle: current_advanced.subtitle,
      cards: [
        for (final c in current_advanced.cards)
          ReleaseHighlightCard.fromJson(c),
      ],
    ),
  };
}
