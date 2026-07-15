/// The typhoon layer's detail sheet (拖盤): an always-present draggable bottom
/// sheet showing the active storm's summary and the scrubbable satellite
/// imagery. Bottom-anchored + `expand: false` (like the station sheet) so it
/// only overlays its own height and the map above stays pannable/tappable — a
/// full-screen overlay blocks the platform view's taps (Flutter #71608).
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TyphoonPanel extends StatefulWidget {
  const TyphoonPanel({super.key, required this.layer});

  final TyphoonMapLayer layer;

  @override
  State<TyphoonPanel> createState() => _TyphoonPanelState();
}

class _TyphoonPanelState extends State<TyphoonPanel> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  static const double _peek = 0.16;
  static const double _rest = 0.42;

  @override
  void initState() {
    super.initState();
    widget.layer.tapped.addListener(_onTapped);
  }

  @override
  void dispose() {
    widget.layer.tapped.removeListener(_onTapped);
    _controller.dispose();
    super.dispose();
  }

  /// Pop the sheet up to the rest height when a forecast waypoint is tapped.
  void _onTapped() {
    if (!_controller.isAttached || widget.layer.tapped.value == null) return;
    if ((_controller.size - _rest).abs() < 0.005) return;
    _controller.animateTo(
      _rest,
      duration: AppMotion.medium,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: DraggableScrollableSheet(
        expand: false,
        controller: _controller,
        initialChildSize: _peek,
        minChildSize: _peek,
        maxChildSize: 0.85,
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
              _Summary(layer: widget.layer),
              _TappedWaypoint(layer: widget.layer),
              _TimeSelector(layer: widget.layer),
            ],
          ),
        ),
      ),
    );
  }
}

/// The frosted, rounded sheet panel.
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

/// The sheet's grab handle.
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

/// The active storm's name + intensity, or a "no active typhoon" note.
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

/// A labelled metric (label over value).
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

/// The tapped forecast waypoint's label (a server string), dismissable.
class _TappedWaypoint extends StatelessWidget {
  const _TappedWaypoint({required this.layer});

  final TyphoonMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: layer.tapped,
      builder: (context, label, _) {
        if (label == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
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

/// The scrubbable satellite-imagery time strip; hidden when there is none.
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
    return ValueListenableBuilder<List<int>>(
      valueListenable: widget.layer.imageFrames,
      builder: (context, frames, _) {
        if (frames.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 56,
          child: ValueListenableBuilder<int>(
            valueListenable: widget.layer.selectedFrame,
            builder: (context, selected, _) => ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
        );
      },
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
