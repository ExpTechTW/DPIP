import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class SettingsListSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsListSection({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final separatedChildren =
        children
            .expand(
              (element) => [
                element,
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: context.colors.outlineVariant.withValues(alpha: 0.6),
                ),
              ],
            )
            .toList()
          ..removeLast();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                title!,
                style: context.theme.textTheme.labelLarge!.copyWith(color: context.theme.colorScheme.outline),
              ),
            ),
          Material(
            color: context.theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: separatedChildren,
            ),
          ),
        ],
      ),
    );
  }
}
