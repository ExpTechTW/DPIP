import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:dpip/utils/extensions/build_context.dart';

class BlurredTextButton extends StatelessWidget {
  final String text;
  final void Function()? onPressed;
  final Color? backgroundColor;
  final double sigmaX;
  final double sigmaY;
  final TextStyle? textStyle;

  const BlurredTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textStyle,
    this.sigmaX = 8,
    this.sigmaY = 8,
  });

  @override
  Widget build(BuildContext context) {
    // blur issue https://github.com/flutter/flutter/issues/115926
    return Container(
      height: 48,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(double.maxFinite)),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: backgroundColor ?? context.colors.surfaceContainerHigh.withValues(alpha: 0.6),
            foregroundColor: context.colors.outline,
            textStyle: textStyle,
          ),
          onPressed: onPressed,
          child: Text(text),
        ),
      ),
    );
  }
}

class BlurredIconButton extends StatelessWidget {
  final Widget icon;
  final void Function()? onPressed;
  final Color? backgroundColor;
  final double sigmaX;
  final double sigmaY;

  const BlurredIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.sigmaX = 8,
    this.sigmaY = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: IconButton(
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor ?? context.colors.surfaceContainerHigh.withValues(alpha: 0.6),
            foregroundColor: context.colors.outline,
          ),
          onPressed: onPressed,
          icon: icon,
        ),
      ),
    );
  }
}
