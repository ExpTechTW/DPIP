/// The 強震監視器 overlay UI: the live EEW alert cards (every active report,
/// listed like the replay page lists its alerts) above a bottom freshness strip
/// showing the feed status, the snapshot time, and the live latency (s). The
/// intensity legend lives on the scaffold via [MapLayer.buildLegend].
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/map/presentation/widgets/monitor_eew_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The RTS layer's overlay, laid over the full map (via the scaffold's
/// `buildSheet` slot): the active EEW alert cards above a freshness strip at
/// the bottom. Small so the map stays visible and interactive above it.
class RtsMonitorPanel extends StatelessWidget {
  const RtsMonitorPanel({super.key, required this.feed, required this.eew});

  final RealtimeNotifier<Rts> feed;
  final RealtimeNotifier<List<Eew>> eew;

  /// Roughly how much of the map height the bottom status strip covers at rest.
  /// Declared (not measured) because the strip is a floating overlay, not a
  /// bounded child the scaffold can size; the map subtracts it when framing.
  static const double bottomStripFraction = 0.1;

  /// …and the whole stack (status strip + up to [maxEewListHeight] of alert
  /// cards) while an alert is active — deliberate framing subtracts this so an
  /// epicentre is never framed behind its own alert.
  static const double expandedBottomFraction = 0.45;

  /// Cap on the alert-card list so a burst of reports never pushes the status
  /// strip off screen (same ceiling the replay page uses).
  static const double maxEewListHeight = 240;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListenableBuilder(
            listenable: Listenable.merge([feed, eew]),
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EewAlerts(eew: eew),
                const SizedBox(height: AppSpacing.sm),
                _StatusBar(state: feed.state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Every active EEW alert as a card, capped in height so the status bar below
/// is never pushed off screen. Renders nothing when calm or when the feed has
/// aged past live — a stale alert must never be presented as a current one.
class _EewAlerts extends StatelessWidget {
  const _EewAlerts({required this.eew});

  final RealtimeNotifier<List<Eew>> eew;

  @override
  Widget build(BuildContext context) {
    final state = eew.state;
    final alerts = state.data;
    if (state.status != RealtimeStatus.live ||
        alerts == null ||
        alerts.isEmpty) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: RtsMonitorPanel.maxEewListHeight,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: alerts.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => MonitorEewCard(alert: alerts[index]),
      ),
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
            AppTime.taipei(
              DateTime.fromMillisecondsSinceEpoch(time, isUtc: true),
            ),
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
          LegendDot(color: dot),
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
