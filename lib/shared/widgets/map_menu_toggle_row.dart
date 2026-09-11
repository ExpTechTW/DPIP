/// Checkbox row for a map layer's overlay-menu dropdown.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/material.dart';

/// One on/off overlay inside a [MapChipButton] dropdown: icon, title, optional
/// hint, and a trailing checkbox.
///
/// Shared so every layer's options menu reads identically — a toggle in the
/// radar menu must not look like a different kind of control from the same
/// toggle in the typhoon menu.
///
/// **The menu stays open when a row is tapped.** These dropdowns are settings
/// panels, not command menus: the choices interact (two overlays that exclude
/// each other, borders judged against the layer under them), and the map
/// behind the menu updates live, so a reader is normally changing several rows
/// while watching the result. Closing after each tap would make them reopen
/// the menu for every one. The chip itself and a tap outside are what close
/// it — a row that leaves for somewhere else (a sheet, a page) is the one
/// exception, and is not built from this widget.
class MapMenuToggleRow extends StatelessWidget {
  const MapMenuToggleRow({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    required this.tooltip,
    required this.onTap,
    this.subtitle,
  });

  /// Whether the overlay is currently on.
  final bool selected;

  /// Leading glyph — outlined, per the app's icon convention.
  final IconData icon;

  final String title;

  /// Optional second line explaining what the overlay adds.
  final String? subtitle;

  final String tooltip;
  final VoidCallback onTap;

  /// Row width — fixed so a dropdown's rows line up regardless of label length.
  static const double width = 228;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Tooltip(
      message: tooltip,
      child: MenuItemButton(
        onPressed: onTap,
        closeOnActivate: false,
        style: MapChipButton.rowStyle(
          selected
              ? colors.primaryContainer.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
        child: SizedBox(
          width: width,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
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
