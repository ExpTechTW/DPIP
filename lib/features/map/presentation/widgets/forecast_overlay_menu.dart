/// Frosted dropdown beside the layer switcher — a numerical-forecast wind
/// layer's reference-chrome toggles (county borders, township borders) plus the
/// shared township-name setting.
library;

import 'package:dpip/features/map/presentation/layers/admin_outline_chrome.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_terrain_toggle.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Compact icon chip that opens [layer]'s overlay options — the same chrome and
/// position as the radar/QPESUMS menus, so "layer options" is one affordance
/// across the map rather than one per layer. The township-name toggle rides
/// along because it is a base-map property, not a layer one: [MapScaffold]
/// owns its state and injects it here so every settings menu offers the same
/// switch without a second chip.
///
/// Unlike the radar menu there is no scan-range row: a forecast model is not an
/// instrument with a coverage footprint, so the two admin-border toggles and
/// the map toggle are the whole menu.
class ForecastOverlayMenu extends StatelessWidget {
  const ForecastOverlayMenu({
    super.key,
    required this.layer,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
    required this.showTerrain,
    required this.onShowTerrainChanged,
  });

  final AdminOutlineChrome layer;

  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;

  final ValueListenable<bool> showTerrain;
  final ValueChanged<bool> onShowTerrainChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        layer.adminChromeListenable,
        showTownLabels,
        showTerrain,
      ]),
      builder: (context, _) {
        final showGlobal = layer.showGlobalOutline.value;
        final showCounty = layer.showCountyOutline.value;
        final showTown = layer.showTownOutline.value;
        final showLabels = showTownLabels.value;
        final showRelief = showTerrain.value;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MapChipButton.menuStyle(context),
          builder: (context, controller, _) => MapChipButton(
            icon: Icons.tune,
            tooltip: l10n.windForecastOverlayMenuTooltip,
            // The dot marks "not the defaults". County and town ship on, 國界
            // and labels off, so it lights up when one has moved.
            active:
                showGlobal ||
                !showCounty ||
                !showTown ||
                !showLabels ||
                !showRelief,
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            MapMenuScrollView(
              children: [
                SectionHeader(l10n.mapOverlaySectionReference),
                MapMenuToggleRow(
                  selected: showGlobal,
                  icon: Icons.public_outlined,
                  title: l10n.radarGlobalOutline,
                  subtitle: l10n.windForecastGlobalOutlineHint,
                  tooltip: l10n.windForecastGlobalOutlineHint,
                  onTap: () => layer.setShowGlobalOutline(!showGlobal),
                ),
                MapMenuToggleRow(
                  selected: showCounty,
                  icon: Icons.map_outlined,
                  title: l10n.radarCountyOutline,
                  subtitle: l10n.windForecastCountyOutlineHint,
                  tooltip: l10n.windForecastCountyOutlineHint,
                  onTap: () => layer.setShowCountyOutline(!showCounty),
                ),
                MapMenuToggleRow(
                  selected: showTown,
                  icon: Icons.grid_on_outlined,
                  title: l10n.radarTownOutline,
                  subtitle: l10n.windForecastTownOutlineHint,
                  tooltip: l10n.windForecastTownOutlineHint,
                  onTap: () => layer.setShowTownOutline(!showTown),
                ),
                const MapMenuDivider(),
                SectionHeader(l10n.mapOverlaySectionMap),
                MapTownLabelsRow(
                  showTownLabels: showTownLabels,
                  onShowTownLabelsChanged: onShowTownLabelsChanged,
                ),
                MapTerrainRow(
                  showTerrain: showTerrain,
                  onShowTerrainChanged: onShowTerrainChanged,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
