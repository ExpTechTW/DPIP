import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:dpip/utils/extensions/build_context.dart';

class BlurredContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? shadowColor;
  final double elevation;
  final double sigma;

  const BlurredContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
    this.shadowColor,
    this.elevation = 0,
    this.sigma = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainer.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.colors.outline.withValues(alpha: 0.2)),
      ),
      elevation: elevation,
      shadowColor: shadowColor ?? context.colors.shadow.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
