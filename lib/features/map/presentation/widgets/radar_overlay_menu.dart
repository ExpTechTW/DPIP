/// Frosted dropdown beside the layer switcher — radar overlay toggles.
library;

import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/features/map/presentation/widgets/scan_range_overlay_menu.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The radar layer's own options chip — the shared chrome menu, titled for
/// radar. Kept as a separate type so callers read "radar options", not "some
/// overlay menu".
class RadarOverlayMenu extends StatelessWidget {
  const RadarOverlayMenu({
    super.key,
    required this.layer,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
    required this.showTerrain,
    required this.onShowTerrainChanged,
  });

  final RadarMapLayer layer;
  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;

  final ValueListenable<bool> showTerrain;
  final ValueChanged<bool> onShowTerrainChanged;

  @override
  Widget build(BuildContext context) => ScanRangeOverlayMenu(
    layer: layer,
    tooltip: AppLocalizations.of(context).radarOverlayMenuTooltip,
    showTownLabels: showTownLabels,
    onShowTownLabelsChanged: onShowTownLabelsChanged,
    showTerrain: showTerrain,
    onShowTerrainChanged: onShowTerrainChanged,
  );
}
