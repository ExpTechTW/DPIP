/// Shared ranked-observation list row (medal / bar / value / analysis).
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
    this.analysisLabel,
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

  /// When the ranked value was recorded (e.g. `14:32`).
  final String? eventTimeLabel;

  /// Extra analysis line (e.g. current / high@time / low@time / range).
  final String? analysisLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isTop = rank <= 3;
    final isTop10 = rank <= 10;
    final hasDetail = analysisLabel != null || eventTimeLabel != null;

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

    final leftColumn = <Widget>[
      Text(title, style: titleStyle, overflow: TextOverflow.ellipsis),
      if (subtitle != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: subStyle, overflow: TextOverflow.ellipsis),
      ],
      if (analysisLabel != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(analysisLabel!, style: subStyle, maxLines: 2),
      ],
      if (eventTimeLabel != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(eventTimeLabel!, style: subStyle),
      ],
    ];

    final valueColumn = <Widget>[
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
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: AppSpacing.xxl + AppSpacing.sm,
            child: Center(
              child: isTop
                  ? Icon(
                      rank == 1 ? Icons.emoji_events : Icons.workspace_premium,
                      color: medalColor,
                      size: rank == 1
                          ? AppSpacing.xxl
                          : AppSpacing.xl + AppSpacing.xs,
                    )
                  : Text(
                      '$rank',
                      style: textTheme.titleMedium?.copyWith(color: foreground),
                    ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: hasDetail ? AppSpacing.md : AppSpacing.sm,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: leftColumn,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: valueColumn,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
