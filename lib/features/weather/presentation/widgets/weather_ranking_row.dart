/// Shared ranked-observation list row (medal / bar / value).
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/weather/domain/weather_ranking.dart';
import 'package:flutter/material.dart';

/// One row in a weather ranking list — top-3 medals, relative fill bar, value.
class WeatherRankingRow extends StatelessWidget {
  const WeatherRankingRow({
    super.key,
    required this.rank,
    required this.item,
    required this.merge,
    required this.valueLabel,
    required this.fraction,
    this.leadingExtra,
    this.eventTimeLabel,
    this.onTap,
  });

  /// 1-based position.
  final int rank;

  final RankedObservation item;
  final RankingMerge merge;

  /// Already-formatted value (e.g. `12.3 mm`).
  final String valueLabel;

  /// Fill fraction in `[0, 1]` relative to the list's range.
  final double fraction;

  /// Optional glyph before the value (e.g. wind arrow).
  final Widget? leadingExtra;

  /// Occurrence clock under the value (e.g. `14:32`).
  final String? eventTimeLabel;

  /// Opens the map focused on this station when set.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isTop = rank <= 3;
    final isTop10 = rank <= 10;

    final background = switch (rank) {
      1 => colors.primaryContainer,
      2 => colors.secondaryContainer,
      3 => colors.tertiaryContainer,
      _ when isTop10 => colors.surfaceContainerHigh,
      _ => colors.surfaceContainer,
    };
    final foreground = switch (rank) {
      1 => colors.onPrimaryContainer,
      2 => colors.onSecondaryContainer,
      3 => colors.onTertiaryContainer,
      _ when isTop10 => colors.onSurface,
      _ => colors.onSurfaceVariant,
    };
    final medalColor = switch (rank) {
      1 => colors.primary,
      2 => colors.secondary,
      3 => colors.tertiary,
      _ => foreground,
    };

    final titleStyle = (isTop ? textTheme.titleMedium : textTheme.bodyLarge)
        ?.copyWith(
          color: foreground,
          fontWeight: isTop
              ? FontWeight.w700
              : isTop10
              ? FontWeight.w500
              : FontWeight.w400,
        );
    final subStyle = textTheme.bodySmall?.copyWith(
      color: foreground.withValues(alpha: 0.8),
    );
    final valueStyle = titleStyle;

    final title = item.title(merge);
    final subtitle = item.subtitle(merge);
    final fill = fraction.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.small,
          child: Row(
            children: [
              SizedBox(
                width: AppSpacing.xxl + AppSpacing.sm,
                child: Center(
                  child: isTop
                      ? _RankMedal(
                          rank: rank,
                          color: medalColor,
                          onColor: switch (rank) {
                            1 => colors.onPrimary,
                            2 => colors.onSecondary,
                            _ => colors.onTertiary,
                          },
                        )
                      : Text(
                          '$rank',
                          style: textTheme.titleMedium?.copyWith(
                            color: foreground,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.small,
                    color: background,
                    gradient: LinearGradient(
                      colors: [
                        background,
                        background,
                        background.withValues(alpha: 0.45),
                        background.withValues(alpha: 0.45),
                      ],
                      stops: [0, fill, fill, 1],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: isTop
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    title,
                                    style: titleStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      subtitle,
                                      style: subStyle,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              )
                            : Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      style: titleStyle,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Flexible(
                                      child: Text(
                                        subtitle,
                                        style: subStyle,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (leadingExtra != null) ...[
                                leadingExtra!,
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              Text(valueLabel, style: valueStyle),
                            ],
                          ),
                          if (eventTimeLabel != null)
                            Text(eventTimeLabel!, style: subStyle),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numbered medal for ranks 1–3 — digit first, colour second.
class _RankMedal extends StatelessWidget {
  const _RankMedal({
    required this.rank,
    required this.color,
    required this.onColor,
  });

  final int rank;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final size = rank == 1 ? AppSpacing.xxl : AppSpacing.xl + AppSpacing.xs;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Text(
        '$rank',
        style:
            (rank == 1
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleSmall)
                ?.copyWith(
                  color: onColor,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
      ),
    );
  }
}
