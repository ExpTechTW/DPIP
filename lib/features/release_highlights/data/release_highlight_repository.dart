/// Loads the current version's highlight cards from the content package.
///
/// Each version's cards live as Dart source in `package:dpip_release_highlights`
/// (`lib/<version>/{normal,advanced}.dart`) — the *current* version's files
/// are imported below. Older versions stay in the package as the archive and
/// are never compiled into a build. When a new version ships, replace these two
/// imports with the new version's; nothing else changes.
///
/// Content is authored as JSON at `release_highlights/<version>/…/cards.json`
/// and compiled to Dart by `tool/gen/release_highlights.py`.
library;

import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:dpip_release_highlights/26.1/advanced.dart' as current_advanced;
import 'package:dpip_release_highlights/26.1/normal.dart' as current_normal;

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
