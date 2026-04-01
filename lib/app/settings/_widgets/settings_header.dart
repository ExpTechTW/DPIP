/// Reusable header widget for settings pages.
library;

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/cupertino.dart';

/// A header widget for settings pages, displaying an icon alongside a title
/// and subtitle.
///
/// Use at the top of a settings page to give it a consistent visual identity:
///
/// ```dart
/// SettingsHeader(
///   icon: Symbols.straighten_rounded,
///   iconColor: Colors.amberAccent,
///   title: Text('Unit'),
///   subtitle: Text('Customize display units'),
/// )
/// ```
///
/// When [iconColor] is omitted, the icon uses the theme's
/// [ColorScheme.onPrimaryContainer] color on a [ColorScheme.primaryContainer]
/// background.
class SettingsHeader extends StatelessWidget {
  /// The icon displayed inside the [ContainedIcon].
  final IconData icon;

  /// The color of the icon. Defaults to the theme's [ColorScheme.onPrimaryContainer]
  /// with [ColorScheme.primaryContainer] as the background.
  final Color? iconColor;

  /// The primary label for this settings section.
  final Widget title;

  /// A short description shown below [title].
  final Widget subtitle;

  /// Creates a [SettingsHeader].
  const SettingsHeader({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .symmetric(horizontal: 16, vertical: 8),
      child: Row(
        spacing: 12,
        children: [
          ContainedIcon(
            icon,
            color: iconColor ?? context.colors.onPrimaryContainer,
            backgroundColor: iconColor == null
                ? context.colors.primaryContainer
                : null,
            size: 28,
          ),
          Column(
            crossAxisAlignment: .start,
            children: [
              DefaultTextStyle(
                style: context.texts.titleLarge!.copyWith(fontWeight: .bold),
                child: title,
              ),
              DefaultTextStyle(
                style: context.texts.bodyLarge!,
                child: subtitle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
