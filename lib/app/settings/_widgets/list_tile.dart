import 'package:flutter/material.dart';

import 'package:dpip/utils/extensions/build_context.dart';

class LoadingIcon extends StatelessWidget {
  const LoadingIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class SettingsListTile extends StatelessWidget {
  final Widget? leading;
  final IconData? icon;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool enabled;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final TextStyle? titleStyle;

  const SettingsListTile({
    super.key,
    this.leading,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon, weight: 600, color: context.colors.secondary) : leading,
      title: Text(title, style: titleStyle ?? const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle,
      trailing: trailing,
      enabled: enabled,
      visualDensity: VisualDensity.comfortable,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
