/// A toggleable layer-selection tile used inside the layer picker sheet.
library;

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// A tappable tile representing a single map layer that can be toggled on or
/// off.
///
/// Long-pressing triggers [onLongPress] when provided, which is used for
/// overlay-mode activation.
class LayerToggle extends StatelessWidget {
  /// Whether this layer is currently active.
  final bool checked;

  /// The human-readable name shown below the layer icon.
  final String label;

  /// Called when the user taps the tile. Pass `null` to disable interaction.
  final void Function(bool)? onChanged;

  /// Called when the user long-presses the tile for overlay mode.
  final void Function(bool)? onLongPress;

  /// Creates a [LayerToggle] for the given [label].
  const LayerToggle({
    super.key,
    required this.checked,
    required this.label,
    required this.onChanged,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onChanged == null;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: InkWell(
          onTap: onChanged != null ? () => onChanged!(!checked) : null,
          onLongPress: onLongPress != null ? () => onLongPress!(!checked) : null,
          borderRadius: .circular(12),
          child: Padding(
            padding: const .all(6),
            child: Column(
              mainAxisSize: .min,
              spacing: 4,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: checked ? context.colors.primary : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: .circular(12),
                  ),
                  padding: const .all(2),
                  child: ClipRRect(
                    borderRadius: .circular(8),
                    child: Container(
                      height: 64,
                      width: 64,
                      color: checked
                          ? context.colors.primaryContainer
                          : context.colors.surfaceContainerHighest,
                      child: Icon(
                        Symbols.layers_rounded,
                        color: checked
                            ? context.colors.onPrimaryContainer
                            : context.colors.onSurface,
                      ),
                    ),
                  ),
                ),
                Text(
                  label,
                  style: context.texts.labelMedium!.copyWith(
                    color: checked ? context.colors.primary : context.colors.onSurfaceVariant,
                    fontWeight: checked ? .bold : null,
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
