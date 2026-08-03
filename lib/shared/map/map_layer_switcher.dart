/// The map control that picks which [MapLayer] is shown.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';

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
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md + bottomInset,
                ),
                children: [
                  const _Grip(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      0,
                      AppSpacing.sm,
                      AppSpacing.md,
                    ),
                    child: Text(
                      l10n.mapLayers,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  for (final layer in layers)
                    _LayerTile(
                      layer: layer,
                      selected: layer.id == active.id,
                      colors: colors,
                      onTap: () => Navigator.of(sheetContext).pop(layer),
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
