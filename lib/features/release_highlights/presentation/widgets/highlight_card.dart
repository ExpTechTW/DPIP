/// Readable, low-decoration presentation for release-highlight content.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:flutter/material.dart';

/// The tag of the active locale, e.g. `zh_Hant`, `en`.
String localeTagOf(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_');

/// Material icon for a card's [ReleaseHighlightCard.icon] name.
IconData highlightIcon(String name) => switch (name) {
  'bolt' => Icons.bolt_outlined,
  'data_saver' => Icons.data_saver_on_outlined,
  'battery_saver' => Icons.battery_saver_outlined,
  'rocket_launch' => Icons.rocket_launch_outlined,
  'map' => Icons.map_outlined,
  'my_location' => Icons.my_location_outlined,
  'access_time' => Icons.access_time_outlined,
  'shield' => Icons.shield_outlined,
  'verified' => Icons.verified_outlined,
  'route' => Icons.alt_route_outlined,
  'stream' => Icons.stream_outlined,
  'storage' => Icons.storage_outlined,
  'layers' => Icons.layers_outlined,
  'query_stats' => Icons.query_stats_outlined,
  'rule' => Icons.rule_outlined,
  'receipt_long' => Icons.receipt_long_outlined,
  'straighten' => Icons.straighten_outlined,
  'bug_report' => Icons.bug_report_outlined,
  _ => Icons.question_mark_outlined,
};

/// User-facing highlights shown as a segmented disclosure list.
class ReleaseHighlightGroup extends StatelessWidget {
  const ReleaseHighlightGroup({super.key, required this.cards});

  final List<ReleaseHighlightCard> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < cards.length; index++)
          _SegmentedSurface(
            isFirst: index == 0,
            isLast: index == cards.length - 1,
            child: _ReleaseHighlightTile(card: cards[index]),
          ),
      ],
    );
  }
}

class _ReleaseHighlightTile extends StatelessWidget {
  const _ReleaseHighlightTile({required this.card});

  final ReleaseHighlightCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tag = localeTagOf(context);
    final headline = card.headline == null
        ? null
        : localized(card.headline!, tag);
    final stat = card.stat == null ? null : localized(card.stat!, tag);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('release-highlight-${card.id}'),
        maintainState: true,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        leading: Icon(
          highlightIcon(card.icon),
          color: colors.primary,
          size: 24,
        ),
        title: Text(
          localized(card.title, tag),
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        subtitle: headline == null && stat == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (headline != null)
                      Text(
                        headline,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    if (stat != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        stat,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (card.body != null)
            Text(
              localized(card.body!, tag),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          if (card.statLabel != null) ...[
            if (card.body != null) const SizedBox(height: AppSpacing.md),
            Text(
              localized(card.statLabel!, tag),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          if (card.highlights.isNotEmpty) ...[
            if (card.body != null || card.statLabel != null)
              const SizedBox(height: AppSpacing.lg),
            for (var index = 0; index < card.highlights.length; index++) ...[
              _Bullet(text: localized(card.highlights[index], tag)),
              if (index < card.highlights.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSpacing.xs,
          height: AppSpacing.xs,
          margin: const EdgeInsets.only(
            top: AppSpacing.sm,
            left: AppSpacing.xs,
            right: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Technical highlights shown as a compact segmented disclosure list.
class TechnicalHighlightGroup extends StatelessWidget {
  const TechnicalHighlightGroup({super.key, required this.cards});

  final List<ReleaseHighlightCard> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < cards.length; index++)
          _SegmentedSurface(
            isFirst: index == 0,
            isLast: index == cards.length - 1,
            child: _TechnicalHighlightTile(card: cards[index]),
          ),
      ],
    );
  }
}

class _TechnicalHighlightTile extends StatelessWidget {
  const _TechnicalHighlightTile({required this.card});

  final ReleaseHighlightCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tag = localeTagOf(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('technical-highlight-${card.id}'),
        maintainState: true,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        leading: Icon(
          highlightIcon(card.icon),
          color: colors.primary,
          size: 24,
        ),
        title: Text(
          localized(card.title, tag),
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (card.body != null)
            Text(
              localized(card.body!, tag),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.65,
              ),
            ),
          if (card.details.isNotEmpty) ...[
            if (card.body != null) const SizedBox(height: AppSpacing.lg),
            _TechnicalDetails(details: card.details, tag: tag),
          ],
          if (card.stats.isNotEmpty) ...[
            if (card.body != null || card.details.isNotEmpty)
              const SizedBox(height: AppSpacing.lg),
            _StatRows(stats: card.stats, tag: tag),
          ],
        ],
      ),
    );
  }
}

class _SegmentedSurface extends StatelessWidget {
  const _SegmentedSurface({
    required this.isFirst,
    required this.isLast,
    required this.child,
  });

  final bool isFirst;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(
      top: Radius.circular(isFirst ? AppRadius.lg : AppRadius.sm),
      bottom: Radius.circular(isLast ? AppRadius.lg : AppRadius.sm),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _TechnicalDetails extends StatelessWidget {
  const _TechnicalDetails({required this.details, required this.tag});

  final List<HighlightDetail> details;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < details.length; index++) ...[
          Text(
            localized(details[index].key, tag),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            localized(details[index].value, tag),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          if (index < details.length - 1) const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _StatRows extends StatelessWidget {
  const _StatRows({required this.stats, required this.tag});

  final List<HighlightStat> stats;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            Text(
              localized(stats[index].value, tag),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              localized(stats[index].label, tag),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (index < stats.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.outlineVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
