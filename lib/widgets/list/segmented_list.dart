/// Provides section-based list widgets that recreate the Android 16 design.
///
/// This library includes [SegmentedList] and [SliverSegmentedList] for creating labeled
/// groups of widgets, [SegmentedListTile] for individual list items with
/// the Android 16 styling, and [SectionText] for informational text blocks.
library;

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A section widget that groups children under an optional label.
///
/// This widget recreates the section layout from the Android 16,
/// displaying a list of child widgets within a section, optionally preceded by
/// a styled label. The label uses the primary color theme and appears with
/// padding above the children.
///
/// Example:
/// ```dart
/// Section(
///   label: Text('Settings'),
///   children: [
///     SectionListTile(title: Text('Option 1')),
///     SectionListTile(title: Text('Option 2')),
///   ],
/// )
/// ```
class SegmentedList extends StatelessWidget {
  /// The optional label displayed at the top of the section.
  final Widget? label;

  /// The list of widgets to display in the section.
  final List<Widget> children;

  /// Creates a section with an optional [label] and required [children].
  const SegmentedList({
    super.key,
    this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        if (label != null)
          Padding(
            padding: .fromLTRB(32, 32, 16, 8),
            child: DefaultTextStyle(
              style: context.texts.labelLarge!.copyWith(
                fontWeight: .w600,
                color: context.colors.primary,
              ),
              child: label!,
            ),
          ),
        ListView.builder(
          padding: .symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        ),
      ],
    );
  }
}

/// A sliver variant of [SegmentedList] for use in scrollable layouts.
///
/// This widget recreates the section layout from the Android 16
/// within a [CustomScrollView] or similar scrollable widget, grouping children
/// under an optional label. The label uses the primary color theme and appears
/// with padding above the children.
///
/// Use this instead of [SegmentedList] when building custom scrollable layouts
/// with slivers for better performance.
///
/// Example:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverSection(
///       label: Text('Settings'),
///       children: [
///         SectionListTile(title: Text('Option 1')),
///         SectionListTile(title: Text('Option 2')),
///       ],
///     ),
///   ],
/// )
/// ```
class SliverSegmentedList extends StatelessWidget {
  /// The optional label displayed at the top of the section.
  final Widget? label;

  /// The list of widgets to display in the section.
  final List<Widget> children;

  /// Creates a sliver section with an optional [label] and required [children].
  const SliverSegmentedList({
    super.key,
    this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final label = this.label;

    return SliverMainAxisGroup(
      slivers: [
        if (label != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: .fromLTRB(32, 32, 16, 8),
              child: DefaultTextStyle(
                style: context.texts.labelLarge!.copyWith(
                  fontWeight: .w600,
                  color: context.colors.primary,
                ),
                child: label,
              ),
            ),
          ),
        SliverPadding(
          padding: .symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          ),
        ),
      ],
    );
  }
}

/// A customizable list tile that recreates the Android 16 design.
///
/// This widget provides a flexible list item with support for leading and
/// trailing widgets, title, subtitle, and additional content. It features
/// rounded corners that adapt based on position (first/last in a list),
/// matching the visual style of the Android 16.
///
/// The tile has a Material design with ripple effects when tapped, and uses
/// the theme's surface container color by default.
///
/// Example:
/// ```dart
/// SectionListTile(
///   leading: Icon(Icons.settings),
///   title: Text('Settings'),
///   subtitle: Text('Configure app preferences'),
///   trailing: Icon(Icons.chevron_right),
///   onTap: () => Navigator.push(...),
/// )
/// ```
class SegmentedListTile extends StatelessWidget {
  /// An optional widget displayed at the start of the tile.
  ///
  /// Typically an icon, and is constrained to 28 pixels width.
  final Widget? leading;

  /// Additional label displayed above the title.
  final Widget? label;

  /// The primary content of the tile.
  final Widget? title;

  /// Additional description displayed below the title.
  final Widget? subtitle;

  /// Optional content displayed below the title/subtitle.
  ///
  /// This content is indented if a [leading] widget is present.
  final Widget? content;

  /// An optional widget displayed at the end of the tile.
  ///
  /// Typically used for actions or indicators like chevrons.
  final Widget? trailing;

  /// Whether this is the first tile in a section.
  ///
  /// When true, the top corners use a 20 pixel radius, otherwise, they use
  /// a 4 pixel radius. Has no effect if [borderRadius] is provided.
  final bool isFirst;

  /// Whether this is the last tile in a section.
  ///
  /// When true, the bottom corners use a 20 pixel radius, otherwise, they use
  /// a 4 pixel radius. Has no effect if [borderRadius] is provided.
  final bool isLast;

  /// Whether the tile is enabled.
  final bool enabled;

  /// Custom shape for the tile.
  ///
  /// When provided, this overrides the default rounded rectangle shape and the
  /// [borderRadius] parameter. Use this when you need more control over the
  /// tile's appearance, such as beveled corners or custom borders.
  ///
  /// If null, the tile uses a [RoundedRectangleBorder] with the [borderRadius]
  /// value (or computed based on [isFirst] and [isLast]).
  final ShapeBorder? shape;

  /// Custom border radius for the tile.
  ///
  /// When null, the top corners will use a 20 pixel radius if [isFirst] is true
  /// (4 otherwise), and bottom corners use a 20 pixel radius if [isLast] is
  /// true (4 otherwise).
  final BorderRadius? borderRadius;

  /// Custom padding for the [content] area.
  ///
  /// If not specified, defaults to left padding of 32 when [leading] is present.
  final EdgeInsetsGeometry? contentPadding;

  /// The background color of the tile.
  final Color? tileColor;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Called when the tile is long pressed.
  final VoidCallback? onLongPress;

  /// Creates a section list tile.
  const SegmentedListTile({
    super.key,
    this.leading,
    this.label,
    this.title,
    this.subtitle,
    this.content,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
    this.enabled = true,
    this.shape,
    this.borderRadius,
    this.contentPadding,
    this.tileColor,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    final title = this.title;
    final subtitle = this.subtitle;
    final content = this.content;
    final leading = this.leading;
    final trailing = this.trailing;

    final borderRadius =
        this.borderRadius ??
        BorderRadius.vertical(
          top: isFirst ? .circular(20) : .circular(4),
          bottom: isLast ? .circular(20) : .circular(4),
        );

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Padding(
        padding: .symmetric(vertical: 1),
        child: Material(
          color: tileColor ?? context.colors.surfaceContainerHigh,
          shape: shape ?? RoundedRectangleBorder(borderRadius: borderRadius),
          clipBehavior: .antiAlias,
          child: InkWell(
            borderRadius: borderRadius,
            highlightColor: context.colors.surfaceTint.withValues(alpha: .16),
            onTap: enabled ? onTap : null,
            onLongPress: enabled ? onLongPress : null,
            child: Padding(
              padding: .all(16),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                spacing: 16,
                children: [
                  if (label != null || title != null || subtitle != null)
                    Row(
                      spacing: 8,
                      children: [
                        if (leading != null)
                          Padding(
                            padding: .only(right: 4),
                            child: ConstrainedBox(
                              constraints: const .new(minWidth: 28),
                              child: leading,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            mainAxisSize: .min,
                            crossAxisAlignment: .start,
                            spacing: 2,
                            children: [
                              if (label != null)
                                DefaultTextStyle(
                                  style: context.texts.labelLarge!.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                  child: label,
                                ),
                              if (title != null)
                                DefaultTextStyle(
                                  style: context.texts.titleMedium!.copyWith(
                                    fontWeight: .bold,
                                  ),
                                  child: title,
                                ),
                              if (subtitle != null)
                                DefaultTextStyle(
                                  style: context.texts.bodyMedium!.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                  child: subtitle,
                                ),
                            ],
                          ),
                        ),
                        if (trailing != null) trailing,
                      ],
                    ),
                  if (content != null)
                    Padding(
                      padding:
                          contentPadding ??
                          (leading != null ? .only(left: 32) : .zero),
                      child: DefaultTextStyle(
                        style: context.texts.bodyMedium!,
                        child: content,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A text widget for displaying informational content within a section.
///
/// This widget shows text with an optional leading icon (defaults to an info
/// icon if not provided). It uses the theme's outline color for subtle,
/// secondary text appearance.
///
/// Commonly used for help text, disclaimers, or informational notes within
/// a section layout.
///
/// Example:
/// ```dart
/// SectionText(
///   leading: Icon(Icons.warning),
///   child: Text('This action cannot be undone'),
/// )
/// ```
class SectionText extends StatelessWidget {
  /// An optional widget displayed above the text.
  ///
  /// Defaults to an info icon if not specified.
  final Widget? leading;

  /// The text content to display.
  final Widget child;

  /// Optional custom text style.
  ///
  /// This style is merged with the default body medium style.
  final TextStyle? textStyle;

  /// Creates a section text widget.
  const SectionText({
    super.key,
    this.leading,
    required this.child,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          leading ??
              Icon(
                Symbols.info_rounded,
                color: context.colors.outline,
              ),
          DefaultTextStyle(
            style: context.texts.bodyMedium!
                .copyWith(color: context.colors.outline)
                .merge(textStyle),
            child: child,
          ),
        ],
      ),
    );
  }
}
