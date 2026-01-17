import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class LabeledDivider extends StatelessWidget {
  final String label;

  const LabeledDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        spacing: 8,
        children: [
          const SizedBox(width: 16, child: Divider()),
          Text(
            label,
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.outline,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
