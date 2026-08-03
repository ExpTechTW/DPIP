/// Frosted dropdown beside the layer switcher — disaster-prevention sub-layer
/// toggles (AED today; more DPM layers later).
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/map/presentation/layers/disaster_map_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';

/// Compact icon chip that opens the DPM overlay menu (same chrome as typhoon).
class DisasterMapOverlayMenu extends StatelessWidget {
  const DisasterMapOverlayMenu({super.key, required this.layer});

  final DisasterMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: layer.showAed,
      builder: (context, _) {
        final showAed = layer.showAed.value;
        // Highlight the chip when the default set is altered (AED off).
        final active = !showAed;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(
              colors.surfaceContainerHigh,
            ),
            elevation: const WidgetStatePropertyAll(6),
            shadowColor: WidgetStatePropertyAll(
              Colors.black.withValues(alpha: 0.24),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: AppRadius.medium),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
          ),
          builder: (context, controller, _) {
            return Tooltip(
              message: l10n.disasterMapOverlayMenuTooltip,
              child: FrostedSurface(
                borderRadius: AppRadius.small,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: AppRadius.small,
                    onTap: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        Icons.tune,
                        size: 22,
                        color: active
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          menuChildren: [
            _SectionLabel(l10n.disasterMapOverlaySectionLayers),
            _ToggleRow(
              selected: showAed,
              icon: Icons.medical_services_outlined,
              title: l10n.mapLayerAed,
              tooltip: l10n.disasterMapOverlayAedTooltip,
              onTap: () => layer.setShowAed(!showAed),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
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
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(
            selected
                ? colors.primaryContainer.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: SizedBox(
          width: 228,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
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
