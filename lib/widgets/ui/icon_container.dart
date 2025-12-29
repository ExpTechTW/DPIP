import 'package:flutter/material.dart';

import 'package:dpip/utils/extensions/build_context.dart';

/// An icon widget with a rounded background container.
///
/// This widget wraps an [Icon] in a container with padding and rounded corners,
/// providing a contained appearance commonly used for prominent icons in modern
/// UI designs. The background color defaults to a semi-transparent version of
/// the icon color (16% opacity), but can be customized with a solid color or
/// gradient.
///
/// The container has 8 pixels of padding and a 12 pixel border radius. All
/// standard [Icon] properties are supported and passed through to the inner icon.
///
/// Example:
/// ```dart
/// ContainedIcon(
///   Icons.notifications,
///   color: Colors.blue,
/// )
///
/// ContainedIcon(
///   Icons.star,
///   backgroundColor: Colors.amber,
///   color: Colors.white,
///   size: 32,
/// )
///
/// ContainedIcon(
///   Icons.favorite,
///   backgroundGradient: LinearGradient(
///     colors: [Colors.pink, Colors.red],
///   ),
///   color: Colors.white,
/// )
/// ```
class ContainedIcon extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The size of the icon in logical pixels.
  ///
  /// Defaults to 24.0.
  final double? size;

  /// The fill value for the icon.
  ///
  /// This is used with Material Symbols icons to control the fill amount.
  final double? fill;

  /// The stroke weight of the icon.
  ///
  /// Defaults to 600.
  final double? weight;

  /// The grade of the icon.
  ///
  /// This is used with Material Symbols icons to control the visual weight.
  final double? grade;

  /// The optical size of the icon.
  ///
  /// This is used with Material Symbols icons for optical corrections.
  final double? opticalSize;

  /// The color of the icon.
  ///
  /// Defaults to the theme's onSurface color if not specified.
  final Color? color;

  /// A list of shadows to apply to the icon.
  final List<Shadow>? shadows;

  /// The semantic label for the icon.
  ///
  /// Used for accessibility to describe the icon to screen readers.
  final String? semanticLabel;

  /// The text direction to use for rendering the icon.
  final TextDirection? textDirection;

  /// Whether to apply text scaling to the icon size.
  final bool? applyTextScaling;

  /// The blend mode to apply when drawing the icon.
  final BlendMode? blendMode;

  /// The font weight to use when rendering the icon.
  final FontWeight? fontWeight;

  /// The background color of the container.
  ///
  /// When null and [backgroundGradient] is also null, defaults to the icon
  /// color with 16% opacity. Ignored if [backgroundGradient] is provided.
  final Color? backgroundColor;

  /// The background gradient of the container.
  ///
  /// When provided, this takes precedence over [backgroundColor].
  final Gradient? backgroundGradient;

  /// Creates a contained icon with a rounded background.
  const ContainedIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.weight = 600,
    this.fill,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
    this.applyTextScaling,
    this.blendMode,
    this.fontWeight,
    this.backgroundColor,
    this.backgroundGradient,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.onSurface;

    return Container(
      padding: const .all(8),
      decoration: BoxDecoration(
        color: backgroundGradient == null
            ? backgroundColor ?? color.withValues(alpha: .16)
            : null,
        gradient: backgroundGradient,
        borderRadius: .circular(12),
      ),
      child: Icon(
        icon,
        size: size,
        fill: fill,
        weight: weight,
        grade: grade,
        opticalSize: opticalSize,
        color: color,
        shadows: shadows,
        semanticLabel: semanticLabel,
        textDirection: textDirection,
        applyTextScaling: applyTextScaling,
        blendMode: blendMode,
        fontWeight: fontWeight,
      ),
    );
  }
}
