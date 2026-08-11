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
  });

  final SatelliteMapLayer layer;
  final Future<void> Function() onReloadActive;
  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([layer.style, showTownLabels]),
      builder: (context, _) {
        final style = layer.style.value;
        final showLabels = showTownLabels.value;
        final active = style != SatelliteStyle.gray || !showLabels;
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
