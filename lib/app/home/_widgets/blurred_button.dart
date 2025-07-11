import 'dart:ui';

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class BlurredTextButton extends StatelessWidget {
  final String text;
  final void Function()? onPressed;
  final Color? backgroundColor;
  final double sigmaX;
  final double sigmaY;
  final TextStyle? textStyle;
  final double elevation;

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
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.colors.outlineVariant.withValues(alpha: 0.4)),
              color: backgroundColor ?? context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                shape: const StadiumBorder(),
                foregroundColor: context.colors.outline,
                textStyle: textStyle,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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

class BlurredIconButton extends StatelessWidget {
  final Widget icon;
  final void Function()? onPressed;
  final Color? backgroundColor;
  final double elevation;
  final double sigmaX;
  final double sigmaY;

  const BlurredIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.elevation = 0,
    this.sigmaX = 8,
    this.sigmaY = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(side: BorderSide(color: context.colors.outlineVariant.withValues(alpha: 0.4))),
        elevation: elevation,
        shadowColor: context.colors.shadow.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: backgroundColor ?? context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
              foregroundColor: context.colors.outline,
            ),
            onPressed: onPressed,
            icon: icon,
          ),
        ),
      ),
    );
  }
}
