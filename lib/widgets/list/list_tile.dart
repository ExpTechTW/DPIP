import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class ListSectionTile extends StatelessWidget {
  final Widget? leading;
  final IconData? icon;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool enabled;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final TextStyle? titleStyle;

  const ListSectionTile({
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
