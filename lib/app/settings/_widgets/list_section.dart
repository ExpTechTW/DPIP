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

    final finalChildren = [
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
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: finalChildren.length,
        itemBuilder: (context, index) {
          return finalChildren[index];
        },
      ),
    );
  }
}

class SettingsListTextSection extends StatelessWidget {
  final String content;
  final IconData? icon;

  const SettingsListTextSection({super.key, required this.content, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 16),
              child: Icon(icon, color: context.theme.colorScheme.onSurfaceVariant),
            ),
          Expanded(
            child: Text(
              content,
              style: context.theme.textTheme.bodyMedium!.copyWith(color: context.theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
