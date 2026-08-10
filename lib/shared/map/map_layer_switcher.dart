/// The map control that picks which [MapLayer] is shown.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_layer_category.dart';
import 'package:dpip/shared/map/map_layer_order.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:dpip/shared/widgets/section_header.dart';
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
                        final categories = orderedCategories(
                          MapLayerCategory.values,
                          orderController.categoryOrder,
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
                            for (final category in categories) ...[
                              SectionHeader(categoryLabel(category, l10n)),
                              for (final layer in ordered)
                                if (categoryOf(layer.id) == category)
                                  _LayerTile(
                                    layer: layer,
                                    selected: layer.id == active.id,
                                    colors: colors,
                                    onTap: () =>
                                        Navigator.of(sheetContext).pop(layer),
                                  ),
                            ],
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
/// Seeded from [MapLayerOrderController.order] / `.categoryOrder` resolved
/// against the surface's actual layers and the current category set
/// (`orderedLayers` / `orderedCategories`), so a layer or category added after
/// the order was saved shows up here — appended at the bottom, ready to be
/// dragged up. A category header drags its whole block (every layer under it);
/// a layer drag is clamped to its category. Every drop persists immediately;
/// the reset button clears both saved orders so the list falls back to the
/// declared order.
class _LayerOrderSheet extends StatefulWidget {
  const _LayerOrderSheet({required this.layers, required this.controller});

  final List<MapLayer> layers;
  final MapLayerOrderController controller;

  @override
  State<_LayerOrderSheet> createState() => _LayerOrderSheetState();
}

class _LayerOrderSheetState extends State<_LayerOrderSheet> {
  // Category blocks — header + its layer ids. Dragging a header reorders the
  // blocks; dragging a layer reorders within one block's ids.
  late List<_Block> _blocks = _buildBlocks(
    widget.layers,
    widget.controller.order,
    widget.controller.categoryOrder,
  );

  /// Layer ids in current block order (headers excluded) — what gets persisted.
  List<String> get _ids => [
    for (final block in _blocks)
      for (final id in block.ids) id,
  ];

  /// Category names in current block order — persisted alongside the ids.
  List<String> get _categoryIds => [
    for (final block in _blocks) block.category.name,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaults = _buildBlocks(widget.layers, const [], const []);
    final defaultIds = [
      for (final block in defaults)
        for (final id in block.ids) id,
    ];
    final defaultCategoryIds = [
      for (final block in defaults) block.category.name,
    ];
    final pristine =
        listEquals(_ids, defaultIds) &&
        listEquals(_categoryIds, defaultCategoryIds);
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
                  onPressed: pristine ? null : _reset,
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
                  itemCount: _flatten().length,
                  onReorderItem: _reorder,
                  itemBuilder: (context, index) {
                    final row = _flatten()[index];
                    final id = row.id;
                    if (id == null) {
                      return _ReorderHeader(
                        key: ValueKey('header-${row.category.name}'),
                        category: row.category,
                        index: index,
                      );
                    }
                    final layer = widget.layers.firstWhere(
                      (layer) => layer.id == id,
                    );
                    return _ReorderTile(
                      key: ValueKey(id),
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
      final rows = _flatten();
      final row = rows.removeAt(oldIndex);
      if (row.id == null) {
        // Category header — drags its whole block (header + every layer under
        // it). `onReorderItem` already adjusted newIndex for the removed slot.
        final block = <_Row>[row];
        while (rows.isNotEmpty && rows.first.category == row.category) {
          block.add(rows.removeAt(0));
        }
        // Snap the drop to a block boundary: a block must land before a
        // header (or at the very end), never inside a group.
        while (newIndex < rows.length && rows[newIndex].id != null) {
          newIndex++;
        }
        newIndex = newIndex.clamp(0, rows.length);
        rows.insertAll(newIndex, block);
      } else {
        // Layer — clamp to its category's band of the remaining rows. A
        // category that emptied out just goes back to its old slot.
        final (start, last) = _band(row.category, rows);
        newIndex = start == -1 ? oldIndex : newIndex.clamp(start, last + 1);
        rows.insert(newIndex, row);
      }
      _blocks = _condense(rows);
    });
    // Fire-and-forget: the next drop supersedes this write anyway, and the
    // picker below reads the controller's latest orders when it rebuilds.
    unawaited(widget.controller.setOrder(_ids));
    unawaited(widget.controller.setCategoryOrder(_categoryIds));
  }

  void _reset() {
    setState(() {
      _blocks = _buildBlocks(widget.layers, const [], const []);
    });
    unawaited(widget.controller.reset());
  }

  /// Rows in current block order — a header row before each block's layers.
  List<_Row> _flatten() => [
    for (final block in _blocks) ...[
      _Row(block.category, null),
      for (final id in block.ids) _Row(block.category, id),
    ],
  ];

  /// Collapses a flattened row list back into blocks. [rows] always begins a
  /// block with its header row, so a `_Block` is created there and filled by
  /// the layer rows that follow.
  List<_Block> _condense(List<_Row> rows) {
    final blocks = <_Block>[];
    _Block? current;
    for (final row in rows) {
      if (row.id == null) {
        blocks.add(current = _Block(row.category));
      } else {
        (current ??= _Block(row.category)).ids.add(row.id!);
      }
    }
    return blocks;
  }

  /// Index band (inclusive) of [category]'s **layer rows** in [rows] — headers
  /// are not part of the band, so a row can be dropped anywhere between its
  /// group's first and last layer. `(-1, -1)` when the group has no rows left.
  static (int, int) _band(MapLayerCategory category, List<_Row> rows) {
    var start = -1, last = -1;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.id != null && row.category == category) {
        if (start == -1) start = i;
        last = i;
      }
    }
    return (start, last);
  }
}

/// One category block in the order editor — the header plus its layer ids.
class _Block {
  _Block(this.category, [List<String>? ids]) : ids = ids ?? [];

  final MapLayerCategory category;
  final List<String> ids;
}

/// Groups [layers] (in [order]'s relative sequence) by category, in
/// [categoryOrder]'s relative sequence — a header block before each non-empty
/// group.
List<_Block> _buildBlocks(
  List<MapLayer> layers,
  List<String> order,
  List<String> categoryOrder,
) {
  final grouped = <MapLayerCategory, List<String>>{};
  for (final layer in orderedLayers(layers, order)) {
    grouped.putIfAbsent(categoryOf(layer.id), () => []).add(layer.id);
  }
  return [
    for (final category in orderedCategories(
      MapLayerCategory.values,
      categoryOrder,
    ))
      if (grouped[category] case final ids?) _Block(category, ids),
  ];
}

/// One reorder-list entry — a layer row or a category section header.
class _Row {
  const _Row(this.category, this.id);

  final MapLayerCategory category;

  /// The layer id; null marks a section header row.
  final String? id;
}

/// Category header inside the reorder list. Dragging it moves the whole block.
class _ReorderHeader extends StatelessWidget {
  const _ReorderHeader({
    super.key,
    required this.category,
    required this.index,
  });

  final MapLayerCategory category;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              categoryLabel(category, l10n),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
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
    );
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
