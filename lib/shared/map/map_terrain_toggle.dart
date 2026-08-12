/// The base map's terrain-relief (hillshade) toggle, shared by every layer's
/// settings menu.
///
/// [MapTerrainRow] slots into an existing overlay menu alongside
/// [MapTownLabelsRow] so the map-level toggle never needs its own chip; the
/// standalone dropdown for layers that ship no other chrome lives in
/// [MapTownLabelsMenu] (the state lives in [MapScaffold], this just renders it).
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// One checkbox row for the terrain-relief setting — drops into any overlay
/// menu's children.
class MapTerrainRow extends StatelessWidget {
  const MapTerrainRow({
    super.key,
    required this.showTerrain,
    required this.onShowTerrainChanged,
  });

  /// Whether the base map's hillshade relief is on (see
  /// [terrainHillshadeLayerId]).
  final ValueListenable<bool> showTerrain;

  final ValueChanged<bool> onShowTerrainChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: showTerrain,
      builder: (context, _) => MapMenuToggleRow(
        selected: showTerrain.value,
        icon: Icons.terrain_outlined,
        title: l10n.mapTerrainRelief,
        subtitle: l10n.mapTerrainReliefHint,
        tooltip: l10n.mapTerrainReliefHint,
        onTap: () => onShowTerrainChanged(!showTerrain.value),
      ),
    );
  }
}
