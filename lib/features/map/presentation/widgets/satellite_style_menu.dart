/// Frosted dropdown beside the layer switcher — a raw band's colour style,
/// plus the shared township-label toggle.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/map/presentation/layers/satellite_layer.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Compact icon chip that opens the satellite band's colour-style menu.
///
/// Shown only for [SatelliteChannel.isBand] layers (named products carry their
/// own palette). Picking a style re-mounts the layer through [onReloadActive]
/// so the already-fetched tiles re-render in the new colours.
class SatelliteStyleMenu extends StatelessWidget {
  const SatelliteStyleMenu({
    super.key,
    required this.layer,
    required this.onReloadActive,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
    required this.showTerrain,
    required this.onShowTerrainChanged,
  });

  final SatelliteMapLayer layer;
  final Future<void> Function() onReloadActive;
  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;

  final ValueListenable<bool> showTerrain;
  final ValueChanged<bool> onShowTerrainChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        layer.style,
        layer.showGlobalOutline,
        showTownLabels,
        showTerrain,
      ]),
      builder: (context, _) {
        final style = layer.style.value;
        final showGlobal = layer.showGlobalOutline.value;
        final showLabels = showTownLabels.value;
        final showRelief = showTerrain.value;
        final active =
            style != SatelliteStyle.gray ||
            !showGlobal ||
            !showLabels ||
            !showRelief;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MapChipButton.menuStyle(context),
          builder: (context, controller, _) {
            return MapChipButton(
              icon: Icons.palette_outlined,
              tooltip: l10n.mapLayerStyleTooltip,
              active: active,
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
          menuChildren: [
            MapMenuScrollView(
              children: [
                SectionHeader(l10n.mapLayerStyleSection),
                _StyleRow(
                  selected: style == SatelliteStyle.gray,
                  icon: Icons.filter_b_and_w_outlined,
                  title: l10n.mapLayerStyleGray,
                  tooltip: l10n.mapLayerStyleGrayTooltip,
                  onTap: () => layer.setStyle(
                    SatelliteStyle.gray,
                    onReloadActive: onReloadActive,
                  ),
                ),
                _StyleRow(
                  selected: style == SatelliteStyle.jma,
                  icon: Icons.palette_outlined,
                  title: l10n.mapLayerStyleJma,
                  tooltip: l10n.mapLayerStyleJmaTooltip,
                  onTap: () => layer.setStyle(
                    SatelliteStyle.jma,
                    onReloadActive: onReloadActive,
                  ),
                ),
                _StyleRow(
                  selected: style == SatelliteStyle.bd,
                  icon: Icons.insert_chart_outlined,
                  title: l10n.mapLayerStyleBd,
                  tooltip: l10n.mapLayerStyleBdTooltip,
                  onTap: () => layer.setStyle(
                    SatelliteStyle.bd,
                    onReloadActive: onReloadActive,
                  ),
                ),
                const MapMenuDivider(),
                SectionHeader(l10n.mapOverlaySectionReference),
                MapMenuToggleRow(
                  selected: showGlobal,
                  icon: Icons.public_outlined,
                  title: l10n.radarGlobalOutline,
                  subtitle: l10n.radarGlobalOutlineHint,
                  tooltip: l10n.radarGlobalOutlineHint,
                  onTap: () => layer.setShowGlobalOutline(!showGlobal),
                ),
                const MapMenuDivider(),
                SectionHeader(l10n.mapOverlaySectionMap),
                MapBasemapControlRows(
                  showTownLabels: showTownLabels,
                  onShowTownLabelsChanged: onShowTownLabelsChanged,
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

/// The satellite layer's settings dropdown for channels with no colour style
/// (named products and the reflectance bands, whose only rendering is
/// grayscale): the 國界 toggle plus the shared township-name setting — the
/// same "overlay options" affordance as every other layer, so B01 needs no
/// special-casing in the scaffold.
class SatelliteReferenceMenu extends StatelessWidget {
  const SatelliteReferenceMenu({
    super.key,
    required this.layer,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
    required this.showTerrain,
    required this.onShowTerrainChanged,
  });

  final SatelliteMapLayer layer;
  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;

  final ValueListenable<bool> showTerrain;
  final ValueChanged<bool> onShowTerrainChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        layer.showGlobalOutline,
        showTownLabels,
        showTerrain,
      ]),
      builder: (context, _) {
        final showGlobal = layer.showGlobalOutline.value;
        final showLabels = showTownLabels.value;
        final showRelief = showTerrain.value;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MapChipButton.menuStyle(context),
          builder: (context, controller, _) => MapChipButton(
            icon: Icons.tune,
            tooltip: l10n.mapOverlaySectionReference,
            // The dot marks "not the defaults". 國界 and labels ship on, so it
            // lights up when either has moved.
            active: !showGlobal || !showLabels || !showRelief,
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
                  subtitle: l10n.radarGlobalOutlineHint,
                  tooltip: l10n.radarGlobalOutlineHint,
                  onTap: () => layer.setShowGlobalOutline(!showGlobal),
                ),
                const MapMenuDivider(),
                SectionHeader(l10n.mapOverlaySectionMap),
                MapBasemapControlRows(
                  showTownLabels: showTownLabels,
                  onShowTownLabelsChanged: onShowTownLabelsChanged,
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

/// Radio row for one colour style.
class _StyleRow extends StatelessWidget {
  const _StyleRow({
    required this.selected,
    required this.icon,
    required this.title,
    required this.tooltip,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: MenuItemButton(
        onPressed: onTap,
        style: MapChipButton.rowStyle(
          selected
              ? colors.primaryContainer.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
        child: SizedBox(
          width: MapMenuToggleRow.width,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: selected ? colors.primary : colors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
