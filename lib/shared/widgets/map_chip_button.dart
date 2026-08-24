/// Frosted icon chip that toggles an overlay-menu dropdown on the map, plus
/// the shared dropdown chrome (border, shadow, inset rows) used by every
/// layer's settings menu.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';

/// Round frosted chip for opening an overlay menu — the same chrome the layer
/// switcher uses — with a marker dot when the layer's options deviate from
/// their defaults.
class MapChipButton extends StatelessWidget {
  const MapChipButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
    this.label,
  });

  /// Whether the menu's settings differ from the defaults: tints the icon
  /// primary and draws the marker dot.
  final bool active;

  /// Glyph shown on the chip (outlined variant by convention).
  final IconData icon;

  /// Optional current-value text beside the glyph.
  ///
  /// For a menu whose selection changes what the whole map means (the rainfall
  /// accumulation window), where reading the current value is far more frequent
  /// than changing it. The chip grows sideways only — its height is what the
  /// compass parks under, so it must not move.
  ///
  /// A labelled chip drops the [active] marker dot: the label already says what
  /// the dot was hinting at, and the dot would sit on top of the text.
  final String? label;

  final String tooltip;
  final VoidCallback onTap;

  /// Shared dropdown chrome for overlay menus: rounded card on
  /// [ColorScheme.surfaceContainerHigh], hairline border, soft shadow, and
  /// inset rows ([AppSpacing.sm] gutters) so hover highlights stay rounded.
  static MenuStyle menuStyle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerHigh),
      elevation: const WidgetStatePropertyAll(6),
      shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.24)),
      side: WidgetStatePropertyAll(
        BorderSide(color: colors.outlineVariant.withValues(alpha: 0.35)),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(AppSpacing.sm)),
    );
  }

  /// Rounded row chrome for [MenuItemButton]s inside [menuStyle] — lets the
  /// hover / selected highlight follow the inset row instead of the card.
  static ButtonStyle rowStyle(Color selectedColor) => ButtonStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.small),
    ),
    backgroundColor: WidgetStatePropertyAll(selectedColor),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: FrostedSurface(
        borderRadius: AppRadius.small,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.small,
            onTap: onTap,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 22,
                        color: active
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                      if (label case final text?) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          text,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                height: 1,
                                color: active
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (active && label == null)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrollable container for an overlay menu's rows — a long menu (typhoon's
/// storm/weather/extra groups) must not fall off the bottom of the screen. The
/// menu anchors beside the top-right chip, so capping at half the surface
/// height keeps the far end reachable while the short menus just shrink-wrap.
class MapMenuScrollView extends StatelessWidget {
  const MapMenuScrollView({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: SingleChildScrollView(
        primary: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// Hairline divider between an overlay menu's sections — thin and tinted
/// [ColorScheme.outlineVariant] so it separates groups without shouting.
class MapMenuDivider extends StatelessWidget {
  const MapMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: 0.5),
      ),
    );
  }
}
