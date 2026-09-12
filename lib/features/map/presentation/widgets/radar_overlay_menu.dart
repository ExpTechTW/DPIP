/// Frosted dropdown beside the layer switcher — radar overlay toggles.
library;

import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/features/map/presentation/widgets/scan_range_overlay_menu.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The radar layer's own options chip — the shared chrome menu, titled for
/// radar and carrying two extra rows the other rasters do not have: the
/// lightning and wind overlays, which draw the strikes / station readings
/// belonging to whichever echo frame is on screen.
///
/// They read as two checkboxes but behave as a three-way choice (neither /
/// lightning / wind): turning one on turns the other off, because two dense
/// mark sets over one island hide each other. Both rows stay tappable — a
/// greyed-out row would make the user turn one off before they could turn the
/// other on, to reach a state they can reach in one tap.
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([layer.showLightning, layer.showWind]),
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final showLightning = layer.showLightning.value;
      final showWind = layer.showWind.value;
      return ScanRangeOverlayMenu(
        layer: layer,
        tooltip: l10n.radarOverlayMenuTooltip,
        showTownLabels: showTownLabels,
        onShowTownLabelsChanged: onShowTownLabelsChanged,
        showTerrain: showTerrain,
        onShowTerrainChanged: onShowTerrainChanged,
        // Both off by default, so either one on is a departure worth the chip's
        // dot.
        extraActive: showLightning || showWind,
        extraSections: [
          const MapMenuDivider(),
          SectionHeader(l10n.mapOverlaySectionData),
          MapMenuToggleRow(
            selected: showLightning,
            icon: Icons.bolt_outlined,
            title: l10n.radarLightningOverlay,
            subtitle: l10n.radarLightningOverlayHint,
            tooltip: l10n.radarLightningOverlaySubtitle,
            onTap: () => layer.setShowLightning(!showLightning),
          ),
          MapMenuToggleRow(
            selected: showWind,
            icon: Icons.air,
            title: l10n.radarWindOverlay,
            subtitle: l10n.radarWindOverlayHint,
            tooltip: l10n.radarWindOverlaySubtitle,
            onTap: () => layer.setShowWind(!showWind),
          ),
        ],
      );
    },
  );
}
