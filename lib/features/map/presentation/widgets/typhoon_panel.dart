/// The typhoon layer's overlay: a storm-summary card (top-left), a satellite
/// time selector (bottom), and a tapped-waypoint card. A Stack with a
/// transparent middle so the map stays pannable/tappable between the cards.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TyphoonPanel extends StatelessWidget {
  const TyphoonPanel({super.key, required this.layer});

  final TyphoonMapLayer layer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Storm summary — top-left.
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ValueListenableBuilder<TyphoonCyclone?>(
                valueListenable: layer.summary,
                builder: (context, cyclone, _) =>
                    _SummaryCard(cyclone: cyclone),
              ),
            ),
          ),
        ),
        // Tapped waypoint + satellite time selector — bottom.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: layer.tapped,
                    builder: (context, label, _) => label == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _WaypointCard(
                              label: label,
                              onClose: () => layer.tapped.value = null,
                            ),
                          ),
                  ),
                  ValueListenableBuilder<List<int>>(
                    valueListenable: layer.imageFrames,
                    builder: (context, frames, _) => frames.isEmpty
                        ? const SizedBox.shrink()
                        : _TimeSelector(layer: layer, frames: frames),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Frosted card shared by the panel's pieces.
class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
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
      child: child,
    );
  }
}

/// The active storm's name + intensity, or a "no active typhoon" note.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.cyclone});

  final TyphoonCyclone? cyclone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final storm = cyclone;
    if (storm == null) {
      return _Card(
        child: Text(
          l10n.typhoonNoActive,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      );
    }
    final motion = [
      storm.direction,
      if (storm.speed != null) '${storm.speed!.toStringAsFixed(0)} km/h',
    ].whereType<String>().join(' ');
    return _Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            storm.cwaName ?? storm.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (storm.wind != null)
            _MetricRow(
              l10n.typhoonWind,
              '${storm.wind!.toStringAsFixed(0)} m/s',
            ),
          if (storm.gust != null)
            _MetricRow(
              l10n.typhoonGust,
              '${storm.gust!.toStringAsFixed(0)} m/s',
            ),
          if (storm.pressure != null)
            _MetricRow(
              l10n.typhoonPressure,
              '${storm.pressure!.toStringAsFixed(0)} hPa',
            ),
          if (motion.isNotEmpty) _MetricRow(l10n.typhoonMotion, motion),
        ],
      ),
    );
  }
}

/// A "label value" line in the summary.
class _MetricRow extends StatelessWidget {
  const _MetricRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The tapped forecast waypoint's label (a server string), with a close button.
class _WaypointCard extends StatelessWidget {
  const _WaypointCard({required this.label, required this.onClose});

  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.place_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(label, style: theme.textTheme.labelLarge)),
          const SizedBox(width: AppSpacing.sm),
          InkResponse(
            onTap: onClose,
            child: Icon(
              Icons.close,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal strip of satellite-frame times; tapping one shows that frame.
class _TimeSelector extends StatefulWidget {
  const _TimeSelector({required this.layer, required this.frames});

  final TyphoonMapLayer layer;
  final List<int> frames;

  @override
  State<_TimeSelector> createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<_TimeSelector> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Start at the newest frame (the right end), which is selected by default.
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
    return _Card(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SizedBox(
        height: 48,
        child: ValueListenableBuilder<int>(
          valueListenable: widget.layer.selectedFrame,
          builder: (context, selected, _) => ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: widget.frames.length,
            itemBuilder: (context, i) => _TimeChip(
              time: DateTime.fromMillisecondsSinceEpoch(
                widget.frames[i] * 1000,
                isUtc: true,
              ).add(const Duration(hours: 8)),
              selected: i == selected,
              onTap: () => widget.layer.showFrame(i),
            ),
          ),
        ),
      ),
    );
  }
}

/// One selectable satellite time (HH:mm over MM/dd).
class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final DateTime time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: AppRadius.small,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('HH:mm').format(time),
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? colors.onPrimary : colors.onSurface,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              DateFormat('MM/dd').format(time),
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
