import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:flutter/material.dart';

/// The stacked-squares button that picks which [MapLayer] the map shows.
///
/// Opens a bottom sheet of the available layers with the active one checked;
/// choosing a different layer reports it via [onSelected]. Single source of the
/// layer-switch affordance, so every map surface gets the same control for free.
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

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'map-layer-switcher',
      onPressed: () => _pick(context),
      child: const Icon(Icons.layers_outlined),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = await showModalBottomSheet<MapLayer>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(l10n.mapLayers, style: theme.textTheme.titleMedium),
            ),
            for (final layer in layers)
              ListTile(
                leading: Icon(layer.icon),
                title: Text(layer.label(context)),
                selected: layer.id == active.id,
                trailing: layer.id == active.id
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(layer),
              ),
          ],
        ),
      ),
    );
    if (selected != null && selected.id != active.id) onSelected(selected);
  }
}
