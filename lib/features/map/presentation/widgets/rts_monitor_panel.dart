/// The 強震監視器 overlay UI: the instrumental-intensity legend (top-left,
/// matching the station-dot colours) and a bottom freshness strip showing the
/// feed status, the snapshot time, and the live latency (s).
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/intensity_legend.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The RTS layer's overlay, laid over the full map (via the scaffold's
/// `buildSheet` slot): a fixed legend at top-left and a freshness strip at the
/// bottom. Both are small so the map stays visible and interactive between them.
class RtsMonitorPanel extends StatelessWidget {
  const RtsMonitorPanel({super.key, required this.feed});

  final RealtimeNotifier<Rts> feed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Instrumental-intensity legend — top-left, same scale as the dots.
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: const _LegendCard(),
            ),
          ),
        ),
        // Feed status + snapshot time + latency — bottom strip.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ListenableBuilder(
                listenable: feed,
                builder: (context, _) => _StatusBar(state: feed.state),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The legend in a frosted card so it reads over any map tile.
class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadius.small,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: const IntensityLegend(mode: IntensityLegendMode.rts),
    );
  }
}

/// A compact bottom card: status dot + title + the snapshot time, then the live
/// latency in seconds (or the feed status word when not live).
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state});

  final RealtimeState<Rts> state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final time = state.data?.time ?? 0;
    final hasData = time != 0;

    // Snapshot wall-clock (UTC+8) and the feed's latency behind the SNTP-
    // corrected clock — both on the server clock, so the lag is device-skew
    // immune. Latency floored at 0 against sub-sync jitter.
    final dataTime = hasData
        ? DateFormat('HH:mm:ss').format(
            DateTime.fromMillisecondsSinceEpoch(
              time,
              isUtc: true,
            ).add(const Duration(hours: 8)),
          )
        : null;
    final raw = AppTime.utc.millisecondsSinceEpoch - time;
    final int? delayMs = hasData ? (raw < 0 ? 0 : raw) : null;

    // Freshness is spoken as text (not colour alone, for colour-blind users).
    // Only a *live* feed shows a latency (green < 1 s, orange < 2 s, red beyond);
    // stale/offline/connecting show the status word instead.
    final (
      Color dot,
      String trailing,
      Color trailingColor,
    ) = switch (state.status) {
      RealtimeStatus.live => (
        Colors.green,
        delayMs == null
            ? l10n.monitorWaiting
            : l10n.monitorDelay((delayMs / 1000).toStringAsFixed(1)),
        _delayColor(delayMs),
      ),
      RealtimeStatus.stale => (Colors.amber, l10n.feedStale, colors.tertiary),
      RealtimeStatus.offline => (Colors.red, l10n.feedOffline, colors.error),
      RealtimeStatus.connecting => (
        Colors.grey,
        l10n.feedConnecting,
        colors.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: AppRadius.medium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          _StatusDot(color: dot),
          const SizedBox(width: AppSpacing.sm),
          // Yields to the trailing readouts so a long locale or large text scale
          // ellipsises the title instead of overflowing the row.
          Expanded(
            child: Text(
              l10n.mapLayerMonitor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (dataTime != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              dataTime,
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailing,
            maxLines: 1,
            style: theme.textTheme.labelMedium?.copyWith(
              color: trailingColor,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// The latency reading's colour by how far behind the feed is: green under
  /// 1 s, orange under 2 s, red beyond.
  Color _delayColor(int? ms) {
    if (ms == null) return Colors.grey;
    if (ms < 1000) return Colors.green;
    if (ms < 2000) return Colors.orange;
    return Colors.red;
  }
}

/// A freshness dot in the [color] chosen for the feed status.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
