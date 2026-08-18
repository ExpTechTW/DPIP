/// The version-highlights page — this version's release cards.
///
/// Version card on More leads here (alongside the version notes). The page
/// holds two tabs: the general-audience deck (what changed, in plain words)
/// and the advanced deck (how the internals work, with file/line references).
library;

import 'package:dpip/app/theme/app_radius.dart';
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
        body: TabBarView(
          children: const [
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
    final repo = context.read<ReleaseHighlightRepository>();
    final deck = repo.load(kind);
    final tag = localeTagOf(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _DeckHeader(deck: deck, tag: tag),
        const SizedBox(height: AppSpacing.md),
        for (final card in deck.cards) ...[
          HighlightCard(card: card),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _DeckHeader extends StatelessWidget {
  const _DeckHeader({required this.deck, required this.tag});

  final HighlightDeck deck;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.secondaryContainer],
        ),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localized(deck.title, tag),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onPrimaryContainer,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            localized(deck.subtitle, tag),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onPrimaryContainer.withValues(alpha: 0.85),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
