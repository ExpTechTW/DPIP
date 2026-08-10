/// Frosted dropdown beside the layer switcher — a raster's reference-chrome
/// toggles (scan range, county borders, township borders) plus the shared
/// township-name setting.
library;

import 'package:dpip/features/map/presentation/layers/scan_range_overlay_chrome.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Compact icon chip that opens [layer]'s overlay options — the same chrome and
/// position as the radar/typhoon menus, so "layer options" is one affordance
/// across the map rather than one per layer. The township-name toggle rides
/// along because it is a base-map property, not a layer one: [MapScaffold]
/// owns its state and injects it here so every settings menu offers the same
/// switch without a second chip.
class ScanRangeOverlayMenu extends StatelessWidget {
  const ScanRangeOverlayMenu({
    super.key,
    required this.layer,
    required this.tooltip,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
  });

  final ScanRangeOverlayChrome layer;

  /// Tooltip for the options chip (layer-specific, so each raster says what it
  /// is configuring).
  final String tooltip;

  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([layer.chromeListenable, showTownLabels]),
      builder: (context, _) {
        final showRange = layer.showScanRange.value;
        final showCounty = layer.showCountyOutline.value;
        final showTown = layer.showTownOutline.value;
        final showLabels = showTownLabels.value;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MapChipButton.menuStyle(context),
          builder: (context, controller, _) => MapChipButton(
            icon: Icons.tune,
            tooltip: tooltip,
            // The dot marks "not the defaults". All four ship on, so it
            // lights up when one has been switched *off*.
            active: !showRange || !showCounty || !showTown || !showLabels,
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            MapMenuScrollView(
              children: [
                SectionHeader(l10n.mapOverlaySectionReference),
                MapMenuToggleRow(
                  selected: showRange,
                  icon: Icons.crop_free_outlined,
                  title: l10n.radarScanRange,
                  subtitle: l10n.radarScanRangeHint,
                  tooltip: l10n.radarScanRangeSubtitle,
                  onTap: () => layer.setShowScanRange(!showRange),
                ),
                MapMenuToggleRow(
                  selected: showCounty,
                  icon: Icons.map_outlined,
                  title: l10n.radarCountyOutline,
                  subtitle: l10n.radarCountyOutlineHint,
                  tooltip: l10n.radarCountyOutlineSubtitle,
                  onTap: () => layer.setShowCountyOutline(!showCounty),
                ),
                MapMenuToggleRow(
                  selected: showTown,
                  icon: Icons.grid_on_outlined,
                  title: l10n.radarTownOutline,
                  subtitle: l10n.radarTownOutlineHint,
                  tooltip: l10n.radarTownOutlineSubtitle,
                  onTap: () => layer.setShowTownOutline(!showTown),
                ),
                const MapMenuDivider(),
                SectionHeader(l10n.mapOverlaySectionMap),
                MapTownLabelsRow(
                  showTownLabels: showTownLabels,
                  onShowTownLabelsChanged: onShowTownLabelsChanged,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
