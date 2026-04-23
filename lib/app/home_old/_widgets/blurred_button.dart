/// Blurred glass-effect button widgets for the home screen overlay.
library;

import 'dart:ui';

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

/// A full-width text button with a frosted-glass backdrop blur effect.
class BlurredTextButton extends StatelessWidget {
  /// The label displayed inside the button.
  final String text;

  /// Called when the button is tapped, or `null` to disable the button.
  final void Function()? onPressed;

  /// Background colour override; defaults to
  /// [ColorScheme.surfaceContainerHighest] at 60% opacity.
  final Color? backgroundColor;

  /// Horizontal blur sigma applied to the backdrop.
  final double sigmaX;

  /// Vertical blur sigma applied to the backdrop.
  final double sigmaY;

  /// Optional text style applied to the label.
  final TextStyle? textStyle;

  /// Material elevation for the drop shadow.
  final double elevation;

  /// Creates a [BlurredTextButton].
  const BlurredTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textStyle,
    this.sigmaX = 8,
    this.sigmaY = 8,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shadowColor: context.colors.shadow.withValues(alpha: 0.4),
      elevation: elevation,
      borderRadius: .circular(24),
      child: ClipRRect(
        borderRadius: .circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: .circular(24),
              border: Border.all(
                color: context.colors.outlineVariant.withValues(alpha: 0.4),
              ),
              color:
                  backgroundColor ?? context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                shape: const StadiumBorder(),
                foregroundColor: context.theme.brightness == .dark
                    ? const Color.fromARGB(199, 250, 250, 250)
                    : const Color.fromARGB(255, 50, 50, 50),
                textStyle: textStyle,
                padding: const .symmetric(horizontal: 16),
              ),
              onPressed: onPressed,
              child: Text(text),
            ),
          ),
        ),
      ),
    );
  }
}

/// A circular icon button with a frosted-glass backdrop blur effect.
class BlurredIconButton extends StatelessWidget {
  /// The icon widget rendered inside the button.
  final Widget icon;

  /// Called when the button is tapped, or `null` to disable the button.
  final void Function()? onPressed;

  /// Background colour override; defaults to
  /// [ColorScheme.surfaceContainerHighest] at 60% opacity.
  final Color? backgroundColor;

  /// Material elevation for the drop shadow.
  final double elevation;

  /// Horizontal blur sigma applied to the backdrop.
  final double sigmaX;

  /// Vertical blur sigma applied to the backdrop.
  final double sigmaY;

  /// Optional tooltip string shown on long-press.
  final String? tooltip;

  /// Creates a [BlurredIconButton].
  const BlurredIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.elevation = 0,
    this.sigmaX = 8,
    this.sigmaY = 8,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(
            color: context.colors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        elevation: elevation,
        shadowColor: context.colors.shadow.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor:
                  backgroundColor ?? context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
              foregroundColor: context.colors.outline,
            ),
            onPressed: onPressed,
            icon: icon,
            tooltip: tooltip,
          ),
        ),
      ),
    );
  }
}
