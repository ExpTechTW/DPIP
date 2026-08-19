/// Renders a single highlight card.
///
/// The visual system follows DESIGN.md: tonal `surfaceContainer` cards with
/// [AppRadius] rounding, a Material icon in a tinted circle, a headline, a
/// body in `bodyMedium`, and — where present — a big stat number in
/// `headlineLarge`. Technical cards additionally render their facts as
/// key/pill rows so a developer gets the details without scrolling. Each card
/// enters with a brief fade-and-lift so the deck reads as one composed page
/// rather than a plain list.
library;

import 'package:dpip/app/theme/app_motion.dart';
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
    final colors = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: child,
        ),
      ),
      child: Material(
        color: colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(card: card, label: label),
              if (card.headline != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  localized(card.headline!, tag),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.35),
                ),
              ],
              if (card.body != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  localized(card.body!, tag),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant, height: 1.6),
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.card, required this.label});

  final ReleaseHighlightCard card;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = card.isTechnical ? colors.tertiary : colors.primary;
    final discColor = card.isTechnical
        ? colors.tertiaryContainer
        : colors.primaryContainer;
    final icon = highlightIcon(card.icon);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: discColor,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Icon(
            icon,
            color: card.isTechnical
                ? colors.onTertiaryContainer
                : colors.onPrimaryContainer,
            size: 22,
          ),
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
                  height: 1.25,
                ),
              ),
              if (card.isTechnical) ...[
                const SizedBox(height: AppSpacing.xs),
                _TechnicalBadge(colors: colors, accent: accent),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The small tinted tag under a technical card's title — a pill painted in the
/// card's own tertiary hue, so the eye can tell the two decks apart at a
/// glance even though both tabs use the same card.
class _TechnicalBadge extends StatelessWidget {
  const _TechnicalBadge({required this.colors, required this.accent});

  final ColorScheme colors;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: AppRadius.small,
      ),
      child: Text(
        AppLocalizations.of(context).highlightCardTechnical,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onTertiaryContainer,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
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
        color: colors.surfaceContainerHigh,
        borderRadius: AppRadius.small,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stat != null)
            Text(
              stat!,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1.05,
              ),
            ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.xs),
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

/// Technical rows as key/pill pairs inside one tonal well — a table's worth
/// of facts without the table's visual weight on the card.
class _DetailRows extends StatelessWidget {
  const _DetailRows({required this.details, required this.tag});

  final List<HighlightDetail> details;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < details.length; i++) {
      final d = details[i];
      if (i > 0) {
        rows.add(
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
        );
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: AppRadius.small,
                  ),
                  child: Text(
                    localized(d.key, tag),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 5,
                child: Text(
                  localized(d.value, tag),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: AppRadius.small,
      ),
      child: Column(children: rows),
    );
  }
}

/// The "verifiable numbers" grid — one labelled value per tile, two columns
/// when the card is wide enough for them to read, one otherwise.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats, required this.tag});

  final List<HighlightStat> stats;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 160).floor().clamp(1, 2);
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 76,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
          ),
          children: [for (final s in stats) _StatTile(stat: s, tag: tag)],
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: AppRadius.small,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            localized(stat.value, tag),
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            localized(stat.label, tag),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.3,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
