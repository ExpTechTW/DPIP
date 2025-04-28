import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/list.dart';
import 'package:flutter/material.dart';

class SettingsListSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsListSection({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final separatedChildren = children.superJoin(
      Divider(height: 1, indent: 16, endIndent: 16, color: context.colors.outlineVariant.withValues(alpha: 0.6)),
    );

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
  final Color? contentColor;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  const SettingsListTextSection({
    super.key,
    required this.content,
    this.contentColor,
    this.icon,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          spacing: 16,
          children: [
            if (icon != null) Icon(icon, color: iconColor ?? context.theme.colorScheme.onSurfaceVariant),
            Expanded(
              child: Text(
                content,
                style: context.theme.textTheme.bodyMedium!.copyWith(
                  color: contentColor ?? context.theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
