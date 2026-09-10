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
/// radar and carrying one extra row the other rasters do not have: the
/// lightning overlay, which draws the strikes belonging to whichever echo frame
/// is on screen.
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
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: layer.showLightning,
    builder: (context, showLightning, _) {
      final l10n = AppLocalizations.of(context);
      return ScanRangeOverlayMenu(
        layer: layer,
        tooltip: l10n.radarOverlayMenuTooltip,
        showTownLabels: showTownLabels,
        onShowTownLabelsChanged: onShowTownLabelsChanged,
        showTerrain: showTerrain,
        onShowTerrainChanged: onShowTerrainChanged,
        // Off by default, so having it on is a departure worth the chip's dot.
        extraActive: showLightning,
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
        ],
      );
    },
  );
}
