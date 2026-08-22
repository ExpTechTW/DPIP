/// Frosted dropdown beside the layer switcher — disaster-prevention sub-layer
/// toggles (AED / restroom / shelter).
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/map/presentation/layers/disaster_map_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Compact icon chip that opens the DPM overlay menu (same chrome as typhoon).
class DisasterMapOverlayMenu extends StatelessWidget {
  const DisasterMapOverlayMenu({
    super.key,
    required this.layer,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
    required this.showTerrain,
    required this.onShowTerrainChanged,
  });

  final DisasterMapLayer layer;
  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;

  final ValueListenable<bool> showTerrain;
  final ValueChanged<bool> onShowTerrainChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        for (final s in layer.subLayers) s.visible,
        showTownLabels,
        showTerrain,
      ]),
      builder: (context, _) {
        // Highlight the chip when the default set is altered (a layer off).
        final active =
            layer.subLayers.any((s) => !s.visible.value) ||
            !showTownLabels.value ||
            !showTerrain.value;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MapChipButton.menuStyle(context),
          builder: (context, controller, _) {
            return MapChipButton(
              icon: Icons.tune,
              tooltip: l10n.disasterMapOverlayMenuTooltip,
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
                SectionHeader(l10n.disasterMapOverlaySectionLayers),
                for (final sub in layer.subLayers)
                  _ToggleRow(
                    selected: sub.visible.value,
                    icon: sub.icon,
                    color: colorFromHexRgb(sub.color),
                    title: DisasterMapLayer.layerLabel(l10n, sub.id),
                    tooltip: DisasterMapLayer.layerTooltip(l10n, sub.id),
                    onTap: () =>
                        layer.setSubLayerVisible(sub, !sub.visible.value),
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.selected,
    required this.icon,
    required this.color,
    required this.title,
    required this.tooltip,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;

  /// Sub-layer marker colour — the row's icon carries it while enabled.
  final Color? color;

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
          width: 228,
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
                  color: selected
                      ? color ?? colors.primary
                      : colors.onSurfaceVariant,
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
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
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
