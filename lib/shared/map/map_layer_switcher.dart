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
/// Two levels, so a category's list is never mixed into the reorder list:
/// level 1 reorders the categories (persisted to `categoryOrder`), and tapping
/// a category opens level 2 to reorder just that category's layers (persisted
/// to `order`). Both are seeded from the controller resolved against the
/// surface's actual layers (`orderedLayers` / `orderedCategories`), so a layer
/// or category added after the order was saved shows up here — appended at the
/// bottom, ready to be dragged up. Every drop persists immediately; the reset
/// button clears both saved orders so the list falls back to the declared
/// order.
class _LayerOrderSheet extends StatefulWidget {
  const _LayerOrderSheet({required this.layers, required this.controller});

  final List<MapLayer> layers;
  final MapLayerOrderController controller;

  @override
  State<_LayerOrderSheet> createState() => _LayerOrderSheetState();
}

class _LayerOrderSheetState extends State<_LayerOrderSheet> {
  // Category blocks — the category order plus each category's layer ids.
  late List<_Block> _blocks = _buildBlocks(
    widget.layers,
    widget.controller.order,
    widget.controller.categoryOrder,
  );

  /// The category whose layers are being edited; null shows the category list.
  MapLayerCategory? _editing;

  /// Layer ids in current block order — what gets persisted.
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
    final editing = _editing;
    final editingBlock = editing == null ? null : _blockOf(editing);
    final closeButton = IconButton(
      icon: const Icon(Icons.close),
      tooltip: AppLocalizations.of(context).commonClose,
      onPressed: () => Navigator.of(context).pop(),
    );
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
              if (editing == null)
                _CenteredHeader(
                  title: AppLocalizations.of(context).mapLayerOrderTitle,
                  left: TextButton(
                    onPressed: _isPristine() ? null : _reset,
                    child: Text(
                      AppLocalizations.of(context).mapLayerOrderReset,
                    ),
                  ),
                  right: closeButton,
                )
              else
                _CenteredHeader(
                  title: categoryLabel(editing, AppLocalizations.of(context)),
                  left: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => setState(() => _editing = null),
                  ),
                  right: closeButton,
                ),
              Flexible(
                child: editing == null
                    ? _categoryList(context)
                    : _layerList(context, editingBlock!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryList(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      itemCount: _blocks.length,
      onReorderItem: _reorderCategory,
      itemBuilder: (context, index) {
        final block = _blocks[index];
        final canOpen = block.ids.length > 1;
        return _CategoryOrderTile(
          key: ValueKey('category-${block.category.name}'),
          category: block.category,
          index: index,
          canOpen: canOpen,
          onTap: canOpen
              ? () => setState(() => _editing = block.category)
              : null,
        );
      },
    );
  }

  Widget _layerList(BuildContext context, _Block block) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      itemCount: block.ids.length,
      onReorderItem: (oldIndex, newIndex) =>
          _reorderLayer(block, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final id = block.ids[index];
        final layer = widget.layers.firstWhere((layer) => layer.id == id);
        return _ReorderTile(key: ValueKey(id), layer: layer, index: index);
      },
    );
  }

  void _reorderCategory(int oldIndex, int newIndex) {
    setState(() {
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, block);
    });
    // Fire-and-forget: the next drop supersedes this write anyway, and the
    // picker below reads the controller's latest orders when it rebuilds.
    unawaited(widget.controller.setOrder(_ids));
    unawaited(widget.controller.setCategoryOrder(_categoryIds));
  }

  void _reorderLayer(_Block block, int oldIndex, int newIndex) {
    setState(() {
      final id = block.ids.removeAt(oldIndex);
      block.ids.insert(newIndex, id);
    });
    unawaited(widget.controller.setOrder(_ids));
  }

  void _reset() {
    setState(() {
      _blocks = _buildBlocks(widget.layers, const [], const []);
    });
    unawaited(widget.controller.reset());
  }

  bool _isPristine() {
    final defaults = _buildBlocks(widget.layers, const [], const []);
    final defaultIds = [
      for (final block in defaults)
        for (final id in block.ids) id,
    ];
    final defaultCategoryIds = [
      for (final block in defaults) block.category.name,
    ];
    return listEquals(_ids, defaultIds) &&
        listEquals(_categoryIds, defaultCategoryIds);
  }

  _Block? _blockOf(MapLayerCategory category) {
    for (final block in _blocks) {
      if (block.category == category) return block;
    }
    return null;
  }
}

/// One category block in the order editor — the header plus its layer ids.
class _Block {
  _Block(this.category, [List<String>? ids]) : ids = ids ?? [];

  final MapLayerCategory category;
  final List<String> ids;
}

/// Groups [layers] (in [order]'s relative sequence) by category, in
/// [categoryOrder]'s relative sequence — a block per non-empty group.
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

/// One row of the level-1 category list. Dragging reorders the categories;
/// tapping a category with more than one layer opens its level-2 layer list.
class _CategoryOrderTile extends StatelessWidget {
  const _CategoryOrderTile({
    super.key,
    required this.category,
    required this.index,
    required this.canOpen,
    required this.onTap,
  });

  final MapLayerCategory category;
  final int index;
  final bool canOpen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
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
                Expanded(
                  child: Text(
                    categoryLabel(category, AppLocalizations.of(context)),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (canOpen)
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
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
