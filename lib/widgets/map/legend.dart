import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class MapLegend extends StatelessWidget {
  final List<Widget> children;
  final String? label;

  const MapLegend({super.key, required this.children, this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label ?? context.i18n.map_legend, style: context.theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
