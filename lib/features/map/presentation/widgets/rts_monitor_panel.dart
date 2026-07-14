/// The 強震監視器 status panel: feed freshness, the snapshot time, and the
/// instrumental-intensity legend.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A compact bottom panel for the RTS layer — bottom-aligned so the map stays
/// visible. Rebuilds on each feed emission (the feed is a [ChangeNotifier]).
class RtsMonitorPanel extends StatelessWidget {
  const RtsMonitorPanel({super.key, required this.feed});

  final RealtimeNotifier<Rts> feed;

  /// Instrumental-intensity legend (levels 1–7), matching the map dot colours.
  static const List<(int, Color)> _legend = [
    (1, Color(0xFF49E9AD)),
    (2, Color(0xFF44FA34)),
    (3, Color(0xFFBEFF0C)),
    (4, Color(0xFFFFF000)),
    (5, Color(0xFFFF9300)),
    (6, Color(0xFFFC5235)),
    (7, Color(0xFFB720E9)),
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListenableBuilder(
            listenable: feed,
            builder: (context, _) => _Panel(state: feed.state),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.state});

  final RealtimeState<Rts> state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final time = state.data?.time;
    final subtitle = time == null || time == 0
        ? l10n.monitorWaiting
        : DateFormat('HH:mm:ss').format(
            DateTime.fromMillisecondsSinceEpoch(
              time * 1000,
              isUtc: true,
            ).add(const Duration(hours: 8)),
          );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(status: state.status),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.mapLayerMonitor,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final (level, color) in RtsMonitorPanel._legend)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 2),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '$level',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A freshness dot — green live, amber stale, red offline, grey connecting.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final RealtimeStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RealtimeStatus.live => Colors.green,
      RealtimeStatus.stale => Colors.amber,
      RealtimeStatus.offline => Colors.red,
      RealtimeStatus.connecting => Colors.grey,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
