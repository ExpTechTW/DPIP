/// The version-highlights page — this version's release stories and technical
/// notes.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:dpip/features/release_highlights/presentation/widgets/highlight_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The page behind the version card's chevron.
class ReleaseHighlightsPage extends StatelessWidget {
  const ReleaseHighlightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.releaseHighlightsTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.article_outlined),
              tooltip: l10n.releaseHighlightsSeeNotes,
              onPressed: () => context.pushNamed(AppRoutes.versionNotes),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.releaseHighlightsTabNormal),
              Tab(text: l10n.releaseHighlightsTabAdvanced),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DeckList(kind: HighlightKind.normal),
            _DeckList(kind: HighlightKind.advanced),
          ],
        ),
      ),
    );
  }
}

class _DeckList extends StatelessWidget {
  const _DeckList({required this.kind});

  final HighlightKind kind;

  @override
  Widget build(BuildContext context) {
    final deck = context.read<ReleaseHighlightRepository>().load(kind);
    final tag = localeTagOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ListView(
      key: PageStorageKey(kind),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl + bottomInset,
      ),
      children: [
        _DeckIntroduction(deck: deck, tag: tag),
        if (deck.cards.isEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          _EmptyDeck(
            message: AppLocalizations.of(context).releaseHighlightsEmpty,
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          if (kind == HighlightKind.normal)
            ReleaseHighlightGroup(cards: deck.cards)
          else
            TechnicalHighlightGroup(cards: deck.cards),
        ],
      ],
    );
  }
}

class _DeckIntroduction extends StatelessWidget {
  const _DeckIntroduction({required this.deck, required this.tag});

  final HighlightDeck deck;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localized(deck.title, tag),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            localized(deck.subtitle, tag),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
