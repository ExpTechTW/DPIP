import 'package:flutter/material.dart';

class SettingsListTile extends StatelessWidget {
  final IconData? leading;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final void Function()? onTap;
  final void Function()? onLongPress;

  const SettingsListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(leading, weight: 600),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle,
      trailing: trailing,
      visualDensity: VisualDensity.comfortable,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
