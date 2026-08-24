/// The map control that picks which [MapLayer] is shown.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/core/settings/map_layer_visibility_controller.dart';
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
    final visibility = context.read<MapLayerVisibilityController>();
    // Owns restoring the sheet's own height when a remembered scroll offset
    // needs one — see `_RememberedOffsetList`'s doc for why.
    final sheetController = DraggableScrollableController();
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
          controller: sheetController,
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
                          _editOrder(sheetContext, orderController, visibility),
                    ),
                  ),
                  Expanded(
                    // Live-updates when the order editor above changes it, so
                    // the picker reflects a reorder — or a hide — the moment
                    // the editor closes back on top of it. A hidden layer is
                    // dropped from this list entirely; the eye toggle in the
                    // order editor is the only way back.
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        orderController,
                        visibility,
                      ]),
                      builder: (context, _) {
                        final ordered =
                            orderedLayers(layers, orderController.order)
                                .where(
                                  (layer) => !visibility.isHidden(layer.id),
                                )
                                .toList();
                        final visibleCategories = {
                          for (final layer in ordered) categoryOf(layer.id),
                        };
                        final categories = orderedCategories(
                          MapLayerCategory.values,
                          orderController.categoryOrder,
                        ).where(visibleCategories.contains);
                        return _RememberedOffsetList(
                          // Remembers scroll offset across separate openings
                          // of this sheet — picking a layer pops the sheet
                          // immediately (see onTap below), so without this the
                          // list snapped back to the top every time, forcing a
                          // re-scroll to reach a nearby, later option. Keyed
                          // by the layer set so different pickers (radar,
                          // satellite, …) each keep their own position.
                          storageKey:
                              'map-layer-switcher:${layers.map((l) => l.id).join(',')}',
                          scrollController: scrollController,
                          sheetController: sheetController,
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
    sheetController.dispose();
    if (selected == null) return;
    // Same-id picks are not skipped: the scaffold's own handler knows its
    // *current* layer (post-fallback) and ignores true no-ops itself.
    onSelected(selected);
  }

  /// Opens the layer-order editor over the picker. Reordering persists to
  /// [orderController] on every drop, and the eye toggles persist to
  /// [visibility] immediately, so closing the editor (or the picker)
  /// never discards a change.
  Future<void> _editOrder(
    BuildContext sheetContext,
    MapLayerOrderController orderController,
    MapLayerVisibilityController visibility,
  ) async {
    await showModalBottomSheet<void>(
      context: sheetContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LayerOrderSheet(
        layers: layers,
        controller: orderController,
        visibility: visibility,
      ),
    );
  }
}

/// Last scroll offset per [_RememberedOffsetList.storageKey], kept for the
/// app's lifetime.
///
/// Not [PageStorage]: every [showModalBottomSheet] call pushes a fresh
/// [ModalRoute], and `ModalRoute` gives its content its own private
/// [PageStorageBucket] (see `_ModalScopeState.build` in the framework's
/// `routes.dart`) — thrown away the moment the route pops. A `PageStorageKey`
/// on the list, as an earlier version of this used, only ever wrote to that
/// bucket-of-the-moment and had nothing to read back from on the next open.
/// This map outlives the route instead.
final Map<String, double> _rememberedListOffset = {};

/// A [ListView] that restores its scroll offset from
/// [_rememberedListOffset] on first layout and keeps that entry updated as
/// the user scrolls — see [_rememberedListOffset] for why [PageStorage]
/// cannot do this for a widget that lives inside a modal bottom sheet.
class _RememberedOffsetList extends StatefulWidget {
  const _RememberedOffsetList({
    required this.storageKey,
    required this.scrollController,
    required this.sheetController,
    required this.padding,
    required this.children,
  });

  final String storageKey;
  final ScrollController scrollController;

  /// Resizes the *sheet* itself, separately from [scrollController]'s own
  /// scroll offset — see [_RememberedOffsetListState.initState] for why
  /// restoring a remembered offset needs this too.
  final DraggableScrollableController sheetController;
  final EdgeInsets padding;
  final List<Widget> children;

  @override
  State<_RememberedOffsetList> createState() => _RememberedOffsetListState();
}

class _RememberedOffsetListState extends State<_RememberedOffsetList> {
  @override
  void initState() {
    super.initState();
    final offset = _rememberedListOffset[widget.storageKey];
    if (offset == null || offset <= 0) return;
    // The controller isn't attached to a position until the sheet's first
    // frame lays out the list beneath it — jumping any earlier throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A nonzero list offset can only have been recorded while the sheet
      // was already at its max height — `DraggableScrollableSheet` routes a
      // drag into resizing the sheet, not scrolling the list, for as long as
      // the list's own `pixels` is 0 (see the framework's
      // `_DraggableScrollableSheetScrollPosition.listShouldScroll`).
      // Restoring the list's `pixels` without first restoring that height
      // left the sheet's own size at its small initial value while `pixels`
      // read nonzero — which flips `listShouldScroll` permanently true, so
      // every drag afterwards scrolled the list instead of resizing the
      // sheet, and the sheet could never reach full height again.
      widget.sheetController.jumpTo(MapLayerSwitcher._max);
      // `jumpTo` resizes the sheet by notifying a listener the surrounding
      // `ValueListenableBuilder` rebuilds from — that rebuild, and the
      // relayout of this list to the taller viewport it produces, only lands
      // on the *next* frame, so the scroll offset restore needs one frame of
      // its own after this to read a `maxScrollExtent` that already accounts
      // for the full-height list.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.scrollController.hasClients) return;
        final max = widget.scrollController.position.maxScrollExtent;
        widget.scrollController.jumpTo(offset.clamp(0.0, max));
      });
    });
  }

  bool _onScroll(ScrollNotification notification) {
    _rememberedListOffset[widget.storageKey] = notification.metrics.pixels;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ListView(
        controller: widget.scrollController,
        padding: widget.padding,
        children: widget.children,
      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layer.label(context),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (layer.subtitle(context) case final subtitle?) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
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
  const _LayerOrderSheet({
    required this.layers,
    required this.controller,
    required this.visibility,
  });

  final List<MapLayer> layers;
  final MapLayerOrderController controller;
  final MapLayerVisibilityController visibility;

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

  /// Navigation direction of the last level switch — drill-in slides the new
  /// list in from the right, going back mirrors it from the left.
  bool _drillingIn = true;

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
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: () => setState(() {
                      _drillingIn = false;
                      _editing = null;
                    }),
                  ),
                  right: closeButton,
                ),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    // The page matching the current editing state is the one
                    // entering; it slides in from the right on a drill-in and
                    // from the left on the way back. The outgoing page runs
                    // the same tween reversed, so it exits toward the side
                    // the user came from.
                    final currentKey = ValueKey(
                      _editing == null
                          ? 'categories'
                          : 'layers-${_editing!.name}',
                    );
                    final incoming = child.key == currentKey;
                    final sign = _drillingIn ? 1.0 : -1.0;
                    return ClipRect(
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(incoming ? sign : -sign, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: editing == null
                      ? _categoryList(context)
                      : _layerList(context, editingBlock!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryList(BuildContext context) {
    return ReorderableListView.builder(
      key: const ValueKey('categories'),
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
        // Every category opens: the eye toggles live on level 2, so a
        // single-layer category (radar, typhoon, rts) must be drill-in-able
        // even though its reorder list holds exactly one row.
        return _CategoryOrderTile(
          key: ValueKey('category-${block.category.name}'),
          category: block.category,
          index: index,
          onTap: () => setState(() {
            _drillingIn = true;
            _editing = block.category;
          }),
        );
      },
    );
  }

  Widget _layerList(BuildContext context, _Block block) {
    final l10n = AppLocalizations.of(context);
    final hideIds = _idsToHideAllIn(block);
    final showAllDisabled = block.ids.every(
      (id) => !widget.visibility.isHidden(id),
    );
    final hideAllDisabled = hideIds.every(widget.visibility.isHidden);
    return Column(
      key: ValueKey('layers-${block.category.name}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: showAllDisabled
                      ? null
                      : () => _showAllInCategory(block),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: Text(l10n.mapLayerShowAll),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hideAllDisabled
                      ? null
                      : () => _hideAllInCategory(block),
                  icon: const Icon(Icons.visibility_off, size: 18),
                  label: Text(l10n.mapLayerHideAll),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: ReorderableListView.builder(
            key: ValueKey('layers-list-${block.category.name}'),
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
              return _ReorderTile(
                key: ValueKey(id),
                layer: layer,
                index: index,
                hidden: widget.visibility.isHidden(id),
                // Hiding must never leave the surface with nothing to show,
                // so the last visible layer's eye is disabled until another
                // one is shown again.
                canHide:
                    widget.visibility.isHidden(id) ||
                    widget.layers
                            .where((l) => !widget.visibility.isHidden(l.id))
                            .length >
                        1,
                onToggleVisibility: () => _toggleVisibility(layer),
              );
            },
          ),
        ),
      ],
    );
  }

  /// The ids in [block] that "hide all" would actually hide — every id in it,
  /// unless nothing outside this category is visible, in which case the
  /// first id stays exempt so the surface always has something to show.
  List<String> _idsToHideAllIn(_Block block) {
    final elsewhereVisible = widget.layers.any(
      (layer) =>
          categoryOf(layer.id) != block.category &&
          !widget.visibility.isHidden(layer.id),
    );
    return elsewhereVisible ? block.ids : block.ids.skip(1).toList();
  }

  /// Shows every layer in [block] as one write — never blocked, since
  /// showing more layers can't violate the "always something visible"
  /// invariant.
  void _showAllInCategory(_Block block) {
    setState(() {});
    unawaited(widget.visibility.setManyHidden(block.ids, hidden: false));
  }

  void _hideAllInCategory(_Block block) {
    setState(() {});
    unawaited(
      widget.visibility.setManyHidden(_idsToHideAllIn(block), hidden: true),
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

  /// Flips a layer's hidden state. The sheet rebuilds from its own [setState]
  /// — it does not listen to the controller — while the write itself is
  /// fire-and-forget: every drop/tap supersedes the previous one and the
  /// picker underneath reads the controller when it rebuilds.
  void _toggleVisibility(MapLayer layer) {
    setState(() {});
    unawaited(
      widget.visibility.setHidden(
        layer.id,
        hidden: !widget.visibility.isHidden(layer.id),
      ),
    );
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
/// tapping opens the level-2 layer list (order + visibility).
class _CategoryOrderTile extends StatelessWidget {
  const _CategoryOrderTile({
    super.key,
    required this.category,
    required this.index,
    required this.onTap,
  });

  final MapLayerCategory category;
  final int index;
  final VoidCallback onTap;

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

/// One row of the reorder editor: layer identity on the left, an eye toggle
/// (shown/hidden) and a drag handle on the right.
class _ReorderTile extends StatelessWidget {
  const _ReorderTile({
    super.key,
    required this.layer,
    required this.index,
    required this.hidden,
    required this.canHide,
    required this.onToggleVisibility,
  });

  final MapLayer layer;
  final int index;

  /// Whether this layer is currently hidden from the picker.
  final bool hidden;

  /// Whether hiding is allowed right now — false for the last visible layer.
  final bool canHide;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
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
          // The row looks identical whether the layer is hidden or not — no
          // dimming, no cross-fade — so pressing the eye never makes anything
          // appear to vanish. The eye itself is the only state indicator.
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
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: hidden ? l10n.mapLayerShow : l10n.mapLayerHide,
                // Same color in both states — `outlineVariant` (meant for
                // faint dividers) made the icon nearly invisible against the
                // tile the moment `hidden` flipped true, so tapping it looked
                // like the icon itself vanished. The row already says the
                // glyph swap alone should carry the state.
                color: colors.onSurfaceVariant,
                // No press overlay: this button's only feedback is the icon
                // itself swapping between the two glyphs, so a translucent
                // state layer on top would just look like a second, competing
                // signal for the same tap.
                style: IconButton.styleFrom(overlayColor: Colors.transparent),
                onPressed: canHide ? onToggleVisibility : null,
                icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
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
