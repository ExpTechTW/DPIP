/// The typhoon layer's detail sheet (拖盤): storm summary, warning bulletin,
/// dataset history scrubber, satellite imagery, and tapped forecast detail.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TyphoonPanel extends StatelessWidget {
  const TyphoonPanel({super.key, required this.layer});

  final TyphoonMapLayer layer;

  static const double peekExtent = 0.18;
  static const double _rest = 0.55;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: layer.tapRevision,
      builder: (context, revision, _) => ValueListenableBuilder<String?>(
        valueListenable: layer.tapped,
        builder: (context, tapped, _) {
          final expanded = tapped != null;
          return Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              key: ValueKey(expanded ? 'wp-$revision' : 'peek'),
              expand: false,
              initialChildSize: expanded ? _rest : peekExtent,
              minChildSize: peekExtent,
              maxChildSize: 0.92,
              snap: true,
              snapSizes: const [_rest],
              builder: (context, scrollController) => _Surface(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    const _Grip(),
                    _Summary(layer: layer),
                    _WarningBlock(layer: layer),
                    _TappedWaypoint(layer: layer),
                    _HistorySelector(layer: layer),
                    _TimeSelector(layer: layer),
                    _TrackNowBlock(layer: layer),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.topSheet,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: AppRadius.topSheet, child: child),
    );
  }
}

class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.layer});

  final TyphoonMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ValueListenableBuilder<TyphoonCyclone?>(
      valueListenable: layer.summary,
      builder: (context, storm, _) {
        if (storm == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Text(
              l10n.typhoonNoActive,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          );
        }
        final motion = [
          storm.direction,
          if (storm.speed != null) '${storm.speed!.toStringAsFixed(0)} km/h',
        ].whereType<String>().join(' ');
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storm.cwaName ?? storm.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (storm.cwaName != null)
                Text(
                  storm.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  if (storm.wind != null)
                    _Metric(
                      l10n.typhoonWind,
                      '${storm.wind!.toStringAsFixed(0)} m/s',
                    ),
                  if (storm.gust != null)
                    _Metric(
                      l10n.typhoonGust,
                      '${storm.gust!.toStringAsFixed(0)} m/s',
                    ),
                  if (storm.pressure != null)
                    _Metric(
                      l10n.typhoonPressure,
                      '${storm.pressure!.toStringAsFixed(0)} hPa',
                    ),
                  if (motion.isNotEmpty) _Metric(l10n.typhoonMotion, motion),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// CAP warning bulletin + affected counties.
class _WarningBlock extends StatelessWidget {
  const _WarningBlock({required this.layer});

  final TyphoonMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ValueListenableBuilder<TyphoonWarning?>(
      valueListenable: layer.warning,
      builder: (context, warn, _) {
        if (warn == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.errorContainer.withValues(alpha: 0.45),
              borderRadius: AppRadius.small,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.typhoonWarningTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    warn.headline,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${warn.msgType} · ${warn.severity}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onErrorContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  if (warn.sections.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    for (final s in warn.sections.take(3)) ...[
                      Text(
                        s.title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(s.text, style: theme.textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                  if (warn.areas.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.typhoonWarningAreas(
                        warn.areas.map((a) => a.name).join(', '),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Storm-circle radii from track `now` (c15 / c25).
class _TrackNowBlock extends StatelessWidget {
  const _TrackNowBlock({required this.layer});

  final TyphoonMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ValueListenableBuilder<TrackPayload?>(
      valueListenable: layer.track,
      builder: (context, payload, _) {
        final now = payload?.cyclones.isNotEmpty == true
            ? payload!.cyclones.first.now
            : null;
        if (now == null) return const SizedBox.shrink();
        final move = now.move;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.typhoonTrackDetail, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (move != null && move.isNotEmpty)
                Text(move.first, style: theme.textTheme.bodyMedium),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  if (now.c15 != null)
                    _Metric(
                      l10n.typhoonLegendCircle15,
                      '${now.c15!.avg.toStringAsFixed(0)} km',
                    ),
                  if (now.c25 != null)
                    _Metric(
                      l10n.typhoonLegendCircle25,
                      '${now.c25!.avg.toStringAsFixed(0)} km',
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TappedWaypoint extends StatelessWidget {
  const _TappedWaypoint({required this.layer});

  final TyphoonMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: layer.tapped,
      builder: (context, label, _) {
        if (label == null) return const SizedBox.shrink();
        final forecast = layer.forecastForLabel(label);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.place_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    if (forecast != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.md,
                        children: [
                          if (forecast.wind != null)
                            Text(
                              '${l10n.typhoonWind} ${forecast.wind!.toStringAsFixed(0)} m/s',
                              style: theme.textTheme.labelSmall,
                            ),
                          if (forecast.pressure != null)
                            Text(
                              '${l10n.typhoonPressure} ${forecast.pressure!.toStringAsFixed(0)} hPa',
                              style: theme.textTheme.labelSmall,
                            ),
                          if (forecast.r15 != null)
                            Text(
                              'R15 ${forecast.r15!.toStringAsFixed(0)} km',
                              style: theme.textTheme.labelSmall,
                            ),
                          if (forecast.r70 != null)
                            Text(
                              'R70 ${forecast.r70!.toStringAsFixed(0)} km',
                              style: theme.textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => layer.tapped.value = null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Scrubs potential/track/probability/warning snapshots.
class _HistorySelector extends StatelessWidget {
  const _HistorySelector({required this.layer});

  final TyphoonMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ValueListenableBuilder<List<int>>(
      valueListenable: layer.historyFrames,
      builder: (context, frames, _) {
        if (frames.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.typhoonHistoryTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
            SizedBox(
              height: 56,
              child: ValueListenableBuilder<int?>(
                valueListenable: layer.selectedHistory,
                builder: (context, selected, _) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: frames.length + 1,
                  itemBuilder: (context, i) {
                    if (i == frames.length) {
                      return _TimeChip(
                        label: l10n.typhoonHistoryLive,
                        selected: selected == null,
                        onTap: () => layer.selectHistory(null),
                      );
                    }
                    final sec = frames[i];
                    final time = DateTime.fromMillisecondsSinceEpoch(
                      sec * 1000,
                      isUtc: true,
                    ).add(const Duration(hours: 8));
                    return _TimeChip(
                      time: time,
                      selected: selected == sec,
                      onTap: () => layer.selectHistory(sec),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimeSelector extends StatefulWidget {
  const _TimeSelector({required this.layer});

  final TyphoonMapLayer layer;

  @override
  State<_TimeSelector> createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<_TimeSelector> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ValueListenableBuilder<List<int>>(
      valueListenable: widget.layer.imageFrames,
      builder: (context, frames, _) {
        if (frames.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.typhoonSatelliteTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
            SizedBox(
              height: 56,
              child: ValueListenableBuilder<int>(
                valueListenable: widget.layer.selectedFrame,
                builder: (context, selected, _) => ListView.builder(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: frames.length,
                  itemBuilder: (context, i) => _TimeChip(
                    time: DateTime.fromMillisecondsSinceEpoch(
                      frames[i] * 1000,
                      isUtc: true,
                    ).add(const Duration(hours: 8)),
                    selected: i == selected,
                    onTap: () => widget.layer.showFrame(i),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    this.time,
    this.label,
    required this.selected,
    required this.onTap,
  }) : assert(time != null || label != null);

  final DateTime? time;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: label != null ? 64 : 58,
        margin: const EdgeInsets.symmetric(
          horizontal: 3,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: AppRadius.small,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label != null)
              Text(
                label!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              )
            else ...[
              Text(
                DateFormat('HH:mm').format(time!),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                DateFormat('MM/dd').format(time!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
