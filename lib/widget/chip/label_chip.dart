import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';

class LabelChip extends StatelessWidget {
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? outlineColor;
  final String label;

  const LabelChip({super.key, required this.label, this.backgroundColor, this.foregroundColor, this.outlineColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: outlineColor ?? context.colors.outline),
      ),
      child: Text(
        label,
        style: context.theme.textTheme.labelMedium?.copyWith(
          color: foregroundColor ?? context.colors.onSurface,
          height: 1,
        ),
      ),
    );
  }
}
