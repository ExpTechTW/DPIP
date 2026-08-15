/// The draggable detail sheet for the Meshtastic node layer.
///
/// Same mechanics as the station sheet (and the typhoon panel before it):
/// bottom-aligned, `expand: false` so the map above stays tappable, and a key
/// remount to pop or collapse it. Sharing that skeleton is the point — a map
/// sheet the user has already learned to drag should not behave differently
/// just because this layer is newer.
///
/// It is always mounted, resting at its handle when nothing is selected, so
/// there is a permanent affordance saying "there is something to drag here".
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/sheet_extent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MeshNodeSheet extends StatefulWidget {
  const MeshNodeSheet({
    super.key,
    required this.store,
    required this.selected,
    required this.selectionRevision,
    required this.onClose,
  });

  final MeshNodeStore store;

  /// The tapped node's number, or null.
  final ValueListenable<int?> selected;

  /// Bumped on every selecting tap, so re-tapping the same node re-pops a
  /// sheet the user collapsed.
  final ValueListenable<int> selectionRevision;

  final VoidCallback onClose;

  /// Collapsed peek height — also what the layer reports as its bottom chrome.
  ///
  /// Matches the station sheet's, and deliberately not smaller: at 0.12 the
  /// tray read as a hairline the user had to discover, rather than a handle
  /// that is obviously there to be pulled.
  static const double peekExtent = 0.14;
  static const double _rest = 0.38;
  static const double _expanded = 1;

  @override
  State<MeshNodeSheet> createState() => _MeshNodeSheetState();
}

class _MeshNodeSheetState extends State<MeshNodeSheet> {
  /// Live sheet fraction — drives the chrome (grip, flush top) only.
  final ValueNotifier<double> _extent = ValueNotifier(MeshNodeSheet.peekExtent);

  int? _seededRevision;
  int? _seededNode;

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.selectionRevision,
      builder: (context, revision, _) => ValueListenableBuilder<int?>(
        valueListenable: widget.selected,
        builder: (context, nodeNum, _) {
          final initial = nodeNum == null
              ? MeshNodeSheet.peekExtent
              : MeshNodeSheet._rest;
          // The key remount is what sets `initialChildSize`; seed the chrome to
          // match, because the sheet only notifies its extent after a drag.
          if (revision != _seededRevision || nodeNum != _seededNode) {
            _seededRevision = revision;
            _seededNode = nodeNum;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _extent.value = initial;
            });
          }
          return ExtentSheetChrome(
            extent: _extent,
            keyValue: nodeNum == null ? 'peek' : 'sel-$revision',
            initial: initial,
            min: MeshNodeSheet.peekExtent,
            max: MeshNodeSheet._expanded,
            snapSizes: const [MeshNodeSheet._rest],
            content: (context, scrollController) => _Body(
              store: widget.store,
              nodeNum: nodeNum,
              scrollController: scrollController,
              extent: _extent,
              onClose: widget.onClose,
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.store,
    required this.nodeNum,
    required this.scrollController,
    required this.extent,
    required this.onClose,
  });

  final MeshNodeStore store;
  final int? nodeNum;
  final ScrollController scrollController;
  final ValueNotifier<double> extent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Rebuilt on the store too, so charge and last-heard keep moving while the
    // sheet is open — a panel frozen at the moment of the tap is wrong within
    // a minute.
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final node = nodeNum == null ? null : store.byNum(nodeNum!);
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            SheetGrip(extent: extent),
            if (node == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: EmptyView(
                  icon: Icons.hub_outlined,
                  message: l10n.meshtasticTapNode,
                ),
              )
            else
              _NodeDetail(
                node: node,
                store: store,
                online: store.isOnline(node),
                onClose: onClose,
              ),
          ],
        );
      },
    );
  }
}

class _NodeDetail extends StatelessWidget {
  const _NodeDetail({
    required this.node,
    required this.store,
    required this.online,
    required this.onClose,
  });

  final MeshNode node;
  final MeshNodeStore store;
  final bool online;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.sm,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Identity — the name at title weight, its id beneath at label
          //    weight. One thing to read first, not five things at once.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.displayName.isEmpty
                          // l10n-ignore: node id fallback
                          ? '0x${node.num.toRadixString(16)}'
                          : node.displayName,
                      style: theme.textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      // l10n-ignore: node id in the hex form the mesh uses
                      '!${node.num.toRadixString(16)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                tooltip: l10n.commonClose,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. State — chips, because these are categories, not measurements.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatusChip(
                icon: online ? Icons.circle : Icons.circle_outlined,
                label: online ? l10n.meshtasticOnline : l10n.meshtasticSilent,
                tone: online ? colors.primary : colors.outline,
              ),
              if (node.viaMqtt)
                _StatusChip(
                  icon: Icons.cloud_outlined,
                  label: l10n.meshtasticViaMqtt,
                  tone: const Color(0xFF7E57C2).vision,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Readings — the numbers, given room to be read as numbers.
          Row(
            children: [
              if (node.batteryLevel != null)
                _Metric(
                  icon: node.batteryLevel! > 100
                      ? Icons.power_outlined
                      : Icons.battery_std_outlined,
                  label: l10n.meshtasticBattery,
                  value: node.batteryLevel! > 100
                      ? l10n.meshtasticExternalPower
                      // l10n-ignore: percentage readout
                      : '${node.batteryLevel}%',
                ),
              if (node.snr != 0)
                _Metric(
                  icon: Icons.network_check_outlined,
                  // l10n-ignore: signal-to-noise label
                  label: 'SNR',
                  // l10n-ignore: decibel readout
                  value: '${node.snr.toStringAsFixed(1)} dB',
                ),
              if (node.lastHeard != null)
                _Metric(
                  icon: Icons.schedule_outlined,
                  label: l10n.meshtasticLastHeard,
                  value: _relative(node.lastHeard!),
                ),
            ],
          ),

          // 4. Position last — the least-read line, so it does not compete.
          if (node.latitude != null && node.longitude != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  // l10n-ignore: coordinates
                  '${node.latitude!.toStringAsFixed(4)}, '
                  '${node.longitude!.toStringAsFixed(4)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (store.distanceToMyRadioKm(node) != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.near_me_outlined,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${l10n.meshtasticDistance} '
                    // l10n-ignore: metric distance readout
                    '${_formatKm(store.distanceToMyRadioKm(node)!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ],

          // 5. Trends — the last hour of this node's own telemetry, so SNR
          //    and battery read as a story rather than a single number.
          ..._trends(context),
        ],
      ),
    );
  }

  List<Widget> _trends(BuildContext context) {
    // A day of persisted samples with the live ring on top — the in-memory
    // ring alone covers minutes on a busy mesh. The ring renders immediately
    // while the day loads.
    return [
      FutureBuilder<List<MeshNodeSample>>(
        future: store.dayHistoryOf(node.num),
        initialData: store.historyOf(node.num),
        builder: (context, snapshot) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _trendBlocks(context, snapshot.data ?? const []),
        ),
      ),
    ];
  }

  List<Widget> _trendBlocks(
    BuildContext context,
    List<MeshNodeSample> samples,
  ) {
    if (samples.length < 2) return const [];

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final snr = [
      for (final s in samples)
        if (s.snr != 0) s.snr,
    ];
    final battery = [
      for (final s in samples)
        if (s.battery != null && s.battery! <= 100) s.battery!.toDouble(),
    ];
    if (snr.length < 2 && battery.length < 2) return const [];

    return [
      const SizedBox(height: AppSpacing.lg),
      if (snr.length >= 2) ...[
        _TrendBlock(
          icon: Icons.network_check_outlined,
          label: l10n.meshtasticSnrTrend,
          // l10n-ignore: decibel unit
          unit: ' dB',
          values: snr,
          tone: online ? colors.primary : colors.outline,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (battery.length >= 2)
        _TrendBlock(
          icon: Icons.battery_std_outlined,
          label: l10n.meshtasticBatteryTrend,
          // l10n-ignore: percent unit
          unit: '%',
          values: battery,
          tone: colors.tertiary,
        ),
    ];
  }

  // l10n-ignore: compact distance readout
  String _formatKm(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 100) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  // l10n-ignore: compact age readout
  String _relative(DateTime at) {
    // Same calibrated clock the store stamped the sample with — a wall clock
    // here and AppTime there would disagree by whatever the device clock has
    // drifted (or been set to), which is exactly the discrepancy that makes an
    // age readout lie.
    final age = AppTime.utc.toLocal().difference(at);
    if (age.inMinutes < 1) return 'now';
    if (age.inMinutes < 60) return '${age.inMinutes}m';
    if (age.inHours < 24) return '${age.inHours}h';
    return '${age.inDays}d';
  }
}

/// A category, not a number — so it wears a chip rather than a value slot.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.small,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tone),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// One reading: the value large, its name small underneath — the number is
/// what the user came for, the label only says which number it is.
class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A labelled sparkline: the trend's name and current value on top, the line
/// itself below. Deliberately not a fl_chart — a 2-line plot needs no axes,
/// no tooltips, and no dependency draw, just a painter.
class _TrendBlock extends StatelessWidget {
  const _TrendBlock({
    required this.icon,
    required this.label,
    required this.unit,
    required this.values,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String unit;
  final List<double> values;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: theme.textTheme.labelMedium),
            const Spacer(),
            Text(
              // l10n-ignore: current-value readout
              '${values.last.toStringAsFixed(values.last.abs() < 100 ? 1 : 0)}'
              '$unit',
              style: theme.textTheme.labelMedium?.copyWith(
                color: tone,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(values: values, tone: tone),
          ),
        ),
      ],
    );
  }
}

/// Draws a thin line through [values] with a soft fill beneath it, scaled so
/// the extremes sit on the block's top and bottom edges — a flat line should
/// still fill the block, or the eye reads it as "nothing happened".
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.tone});

  final List<double> values;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = values.first, hi = values.first;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    if (hi - lo < 1e-9) {
      // A perfectly flat series needs a band to breathe in, or the line is
      // invisible against the fill.
      lo -= 1;
      hi += 1;
    }
    final span = hi - lo;

    Offset point(int i) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - size.height * (values[i] - lo) / span;
      return Offset(x, y);
    }

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tone.withValues(alpha: 0.22), tone.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = tone;
    canvas.drawPath(path, stroke);

    final last = point(values.length - 1);
    canvas.drawCircle(last, 3, Paint()..color = tone);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.tone != tone;
}
