/// The 強震監視器 overlay UI: the instrumental-intensity legend (top-left,
/// matching the station-dot colours) and a bottom freshness strip showing the
/// feed status and the snapshot time.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
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
        // Feed freshness + snapshot time — bottom strip.
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

/// A compact bottom card: status dot + title + monospaced snapshot time.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state});

  final RealtimeState<Rts> state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Freshness is spoken as text (not colour alone, for colour-blind users) and
    // an aged snapshot is never shown as if current — only a *live* feed shows
    // the snapshot time; stale/offline show the status word instead.
    final (
      Color dot,
      String trailing,
      Color trailingColor,
    ) = switch (state.status) {
      RealtimeStatus.live => (
        Colors.green,
        _snapshotTime(state.data?.time, l10n),
        colors.onSurfaceVariant,
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
          // Yields to the trailing status/time so a long locale or large text
          // scale ellipsises the title instead of overflowing the row.
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
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailing,
            maxLines: 1,
            style: theme.textTheme.labelMedium?.copyWith(
              color: trailingColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// The snapshot wall-clock (UTC+8) from the millisecond [time], or the waiting
  /// placeholder before the first snapshot.
  String _snapshotTime(int? time, AppLocalizations l10n) {
    if (time == null || time == 0) return l10n.monitorWaiting;
    return DateFormat('HH:mm:ss').format(
      DateTime.fromMillisecondsSinceEpoch(
        time,
        isUtc: true,
      ).add(const Duration(hours: 8)),
    );
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
