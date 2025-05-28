import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/utils/extensions/build_context.dart';

class LayerToggle extends StatelessWidget {
  final bool checked;
  final String label;
  final void Function(bool) onChanged;

  const LayerToggle({super.key, required this.checked, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checked ? context.colors.primaryContainer : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => onChanged(!checked),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
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
                    color: context.colors.secondaryContainer,
                    child: const Icon(Symbols.layers_rounded),
                  ),
                ),
              ),
              Text(
                label,
                style: context.theme.textTheme.labelLarge!.copyWith(
                  color: checked ? context.colors.primary : context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
