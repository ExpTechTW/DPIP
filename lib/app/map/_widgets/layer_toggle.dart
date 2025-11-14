import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class LayerToggle extends StatelessWidget {
  final bool checked;
  final String label;
  final void Function(bool)? onChanged;
  final void Function(bool)? onLongPress;

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: InkWell(
          onTap: onChanged != null ? () => onChanged!(!checked) : null,
          onLongPress: onLongPress != null ? () => onLongPress!(!checked) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: checked ? context.colors.primary : Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 64,
                      width: 64,
                      color: checked ? context.colors.primaryContainer : context.colors.surfaceContainerHighest,
                      child: Icon(
                        Symbols.layers_rounded,
                        color: checked ? context.colors.onPrimaryContainer : context.colors.onSurface,
                      ),
                    ),
                  ),
                ),
                Text(
                  label,
                  style: context.theme.textTheme.labelMedium!.copyWith(
                    color: checked ? context.colors.primary : context.colors.onSurfaceVariant,
                    fontWeight: checked ? FontWeight.bold : null,
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
