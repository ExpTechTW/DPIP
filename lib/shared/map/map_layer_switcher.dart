/// The map control that picks which [MapLayer] is shown.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_layer_order.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Frosted chip (active layer name) that opens a layer-picker drag sheet.
///
/// Choosing a different layer reports it via [onSelected]. Single source of the
/// layer-switch affordance so every map surface gets the same control.
class MapLayerSwitcher extends StatelessWidget {
  const MapLayerSwitcher({
    super.key,
    required this.layers,
    required this.active,
    required this.onSelected,
  });

  final List<MapLayer> layers;
  final MapLayer active;
  final ValueChanged<MapLayer> onSelected;

  static const double _initial = 0.55;
  static const double _min = 0.4;
  static const double _max = 0.92;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final label = active.label(context);
    return Tooltip(
      message: AppLocalizations.of(context).mapLayers,
      child: FrostedSurface(
        borderRadius: AppRadius.small,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.small,
            onTap: () => _pick(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 168),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.expand_more,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final orderController = context.read<MapLayerOrderController>();
    final selected = await showModalBottomSheet<MapLayer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: _initial,
          minChildSize: _min,
          maxChildSize: _max,
          snap: true,
          snapSizes: const [_initial, _max],
          builder: (context, scrollController) {
            return FrostedSurface(
              borderRadius: AppRadius.topSheet,
              child: Column(
                children: [
                  const _Grip(),
                  _CenteredHeader(
                    title: l10n.mapLayers,
                    left: const SizedBox.shrink(),
                    right: IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: l10n.mapLayerOrderTitle,
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _editOrder(sheetContext, orderController),
                    ),
                  ),
                  Expanded(
                    // Live-updates when the order editor above changes it, so
                    // the picker reflects a reorder the moment the editor
                    // closes back on top of it.
                    child: ListenableBuilder(
                      listenable: orderController,
                      builder: (context, _) {
                        final ordered = orderedLayers(
                          layers,
                          orderController.order,
                        );
                        return ListView(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.md + bottomInset,
                          ),
                          children: [
                            for (final layer in ordered)
                              _LayerTile(
                                layer: layer,
                                selected: layer.id == active.id,
                                colors: colors,
                                onTap: () =>
                                    Navigator.of(sheetContext).pop(layer),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (selected != null && selected.id != active.id) onSelected(selected);
  }

  /// Opens the layer-order editor over the picker. Reordering persists to
  /// [orderController] on every drop, so closing the editor (or the picker)
  /// never discards a change.
  Future<void> _editOrder(
    BuildContext sheetContext,
    MapLayerOrderController orderController,
  ) async {
    await showModalBottomSheet<void>(
      context: sheetContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _LayerOrderSheet(layers: layers, controller: orderController),
    );
  }
}

/// Sheet grab handle — same visual as the typhoon / station 拖盤.
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

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    required this.layer,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final MapLayer layer;
  final bool selected;
  final ColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.55)
            : colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: AppRadius.small,
        child: InkWell(
          borderRadius: AppRadius.small,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  layer.icon,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    layer.label(context),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: colors.primary, size: 22)
                else
                  Icon(
                    Icons.circle_outlined,
                    color: colors.outlineVariant,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Order editor for the layer picker — a fixed-height sheet (not a draggable
/// 拖盤), since it opens over the picker and two stacked drag sheets are
/// confusing.
///
/// Seeded from [MapLayerOrderController.order] resolved against the surface's
/// actual layers ([orderedLayers]), so a layer added after the order was saved
/// shows up here — appended at the bottom, ready to be dragged up. Every drop
/// persists immediately; the reset button clears the saved order so the list
/// falls back to the surface's declared order.
class _LayerOrderSheet extends StatefulWidget {
  const _LayerOrderSheet({required this.layers, required this.controller});

  final List<MapLayer> layers;
  final MapLayerOrderController controller;

  @override
  State<_LayerOrderSheet> createState() => _LayerOrderSheetState();
}

class _LayerOrderSheetState extends State<_LayerOrderSheet> {
  late List<String> _ids = [
    for (final layer in orderedLayers(widget.layers, widget.controller.order))
      layer.id,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaultOrder = [for (final layer in widget.layers) layer.id];
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: FrostedSurface(
          borderRadius: AppRadius.topSheet,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CenteredHeader(
                title: l10n.mapLayerOrderTitle,
                left: TextButton(
                  onPressed: listEquals(_ids, defaultOrder) ? null : _reset,
                  child: Text(l10n.mapLayerOrderReset),
                ),
                right: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.commonClose,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Flexible(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  itemCount: _ids.length,
                  onReorderItem: _reorder,
                  itemBuilder: (context, index) {
                    final layer = widget.layers.firstWhere(
                      (layer) => layer.id == _ids[index],
                    );
                    return _ReorderTile(
                      key: ValueKey(layer.id),
                      layer: layer,
                      index: index,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      // `onReorderItem` already adjusted newIndex for the removed slot.
      final id = _ids.removeAt(oldIndex);
      _ids.insert(newIndex, id);
    });
    // Fire-and-forget: the next drop supersedes this write anyway, and the
    // picker below reads the controller's latest order when it rebuilds.
    unawaited(widget.controller.setOrder(_ids));
  }

  void _reset() {
    setState(() {
      _ids = [for (final layer in widget.layers) layer.id];
    });
    unawaited(widget.controller.reset());
  }
}

/// Sheet header whose title is absolutely centred over [left]/[right].
///
/// A `Row` with an `Expanded` title would let an asymmetric action (e.g. a wide
/// "Reset order" button on the left and a square close button on the right)
/// shove the title off-centre. Overlaying the actions and letting the title own
/// the full width keeps it truly centred.
class _CenteredHeader extends StatelessWidget {
  const _CenteredHeader({
    required this.title,
    required this.left,
    required this.right,
  });

  final String title;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          Align(alignment: Alignment.centerLeft, child: left),
          Align(alignment: Alignment.centerRight, child: right),
        ],
      ),
    );
  }
}

/// One row of the reorder editor: layer identity on the left, a drag handle on
/// the right.
class _ReorderTile extends StatelessWidget {
  const _ReorderTile({super.key, required this.layer, required this.index});

  final MapLayer layer;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: AppRadius.small,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(layer.icon, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  layer.label(context),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.drag_handle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
