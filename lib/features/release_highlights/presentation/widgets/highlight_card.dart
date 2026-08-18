/// Renders a single highlight card.
///
/// The visual system follows DESIGN.md: tonal `surfaceContainer` cards with
/// [AppRadius] rounding, Material icon in a tinted disc, a headline, a body in
/// `bodyMedium`, and — where present — a big stat number in `displaySmall`.
/// Technical cards additionally render key/value rows so a developer gets the
/// facts without scrolling the English out of view.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The tag of the active locale, e.g. `zh_Hant`, `en`.
String localeTagOf(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_');

/// Material icon for a card's [ReleaseHighlightCard.icon] name.
///
/// Missing names degrade to a question mark instead of crashing the build —
/// an unknown icon is a content typo, not a reason to fail.
IconData highlightIcon(String name) => switch (name) {
  'bolt' => Icons.bolt,
  'data_saver' => Icons.data_saver_on,
  'battery_saver' => Icons.battery_saver,
  'rocket_launch' => Icons.rocket_launch,
  'map' => Icons.map_outlined,
  'my_location' => Icons.my_location,
  'access_time' => Icons.access_time,
  'shield' => Icons.shield_outlined,
  'verified' => Icons.verified_outlined,
  'route' => Icons.alt_route,
  'stream' => Icons.stream,
  'storage' => Icons.storage_outlined,
  'layers' => Icons.layers_outlined,
  'query_stats' => Icons.query_stats,
  'rule' => Icons.rule,
  'receipt_long' => Icons.receipt_long_outlined,
  'straighten' => Icons.straighten,
  'bug_report' => Icons.bug_report_outlined,
  _ => Icons.question_mark,
};

/// One card in the highlight deck.
class HighlightCard extends StatelessWidget {
  const HighlightCard({super.key, required this.card});

  final ReleaseHighlightCard card;

  @override
  Widget build(BuildContext context) {
    final tag = localeTagOf(context);
    final label = localized(card.title, tag);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: AppRadius.medium,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(card: card, label: label, tag: tag),
            if (card.headline != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                localized(card.headline!, tag),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
            if (card.body != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                localized(card.body!, tag),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ],
            if (card.stat != null || card.statLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              _BigStat(
                stat: card.stat == null ? null : localized(card.stat!, tag),
                label: card.statLabel == null
                    ? null
                    : localized(card.statLabel!, tag),
              ),
            ],
            if (card.highlights.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              for (final h in card.highlights)
                _HighlightRow(text: localized(h, tag)),
            ],
            if (card.details.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _DetailRows(details: card.details, tag: tag),
            ],
            if (card.stats.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _StatGrid(stats: card.stats, tag: tag),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.card, required this.label, required this.tag});

  final ReleaseHighlightCard card;
  final String label;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = highlightIcon(card.icon);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: AppRadius.small,
          ),
          child: Icon(icon, color: colors.onPrimaryContainer, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (card.isTechnical) ...[
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).highlightCardTechnical,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({this.stat, this.label});

  final String? stat;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppRadius.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stat != null)
            Text(
              stat!,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1.1,
              ),
            ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRows extends StatelessWidget {
  const _DetailRows({required this.details, required this.tag});

  final List<HighlightDetail> details;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (var i = 0; i < details.length; i++) {
      final d = details[i];
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  localized(d.key, tag),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  localized(d.value, tag),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurface, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      );
      if (i < details.length - 1) {
        rows.add(
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
        );
      }
    }
    return Column(children: rows);
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats, required this.tag});

  final List<HighlightStat> stats;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns when there is room; one otherwise. `/2` never divides
        // oddly because each tile is a full row on narrow screens.
        final twoColumns = constraints.maxWidth >= 320;
        final columnCount = twoColumns ? 2 : 1;
        final tiles = <Widget>[];
        for (final s in stats) {
          tiles.add(_StatTile(stat: s, tag: tag));
          if (twoColumns && tiles.length.isOdd) {
            tiles.add(const SizedBox(width: AppSpacing.sm));
          }
          if (tiles.length % columnCount == 0) {
            tiles.add(const SizedBox(height: AppSpacing.sm));
          }
        }
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: tiles,
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat, required this.tag});

  final HighlightStat stat;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppRadius.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localized(stat.value, tag),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            localized(stat.label, tag),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}
