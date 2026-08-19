/// The version-highlights page — this version's release cards.
///
/// Version card on More leads here (alongside the version notes). The page
/// holds two tabs: the general-audience deck (what changed, in plain words)
/// and the advanced deck (how the internals work, with file/line references).
/// The deck header introduces each tab in the app's hero-card voice; the cards
/// themselves enter with a staggered fade-and-lift so the list reads as one
/// composed page.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/version/app_build.dart';
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
    final colors = Theme.of(context).colorScheme;
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
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            indicatorColor: colors.primary,
            indicatorWeight: 2.5,
            labelColor: colors.primary,
            dividerColor: colors.outlineVariant,
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
        for (var i = 0; i < deck.cards.length; i++) ...[
          HighlightCard(card: deck.cards[i]),
          if (i < deck.cards.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// The hero introduction for one tab: a primary-to-secondary gradient wash
/// with the version badge pinned in its corner.
class _DeckHeader extends StatelessWidget {
  const _DeckHeader({required this.deck, required this.tag});

  final HighlightDeck deck;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final onHeader = colors.onPrimaryContainer;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium,
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primaryContainer, colors.secondaryContainer],
          ),
          borderRadius: AppRadius.large,
          border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localized(deck.title, tag),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: onHeader,
                letterSpacing: -0.4,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              localized(deck.subtitle, tag),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: onHeader.withValues(alpha: 0.85),
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _VersionBadge(colors: colors),
          ],
        ),
      ),
    );
  }
}

/// The build this deck belongs to, as a small outlined pill — the same chip
/// language the More page's version card uses, so the two pages agree on what
/// a "version" is.
class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = AppBuild.label;
    final stable = RegExp(r'^\d+\.\d+$').hasMatch(label);
    final typeText = stable ? l10n.moreVersionStable : l10n.moreVersionSnapshot;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors.onPrimaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: colors.onPrimaryContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stable ? Icons.verified : Icons.science_outlined,
            size: 14,
            color: colors.onPrimaryContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$typeText · $label',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
