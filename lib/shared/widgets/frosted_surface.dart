/// Frosted-glass chrome for map overlays (legend, timeline, layer switcher).
///
/// Same BackdropFilter recipe as the home sheet at rest, tuned hotter for
/// short / small panels where ClipRRect eats most of a sigma-24 kernel.
library;

import 'dart:ui' show ImageFilter;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// Default blur for compact map chrome (legend chip, layer button, timeline).
const double kMapFrostBlurSigma = 48;

/// Default surface tint alpha over the blurred map.
const double kMapFrostSurfaceAlpha = 0.72;

/// A clipped, blurred panel with a translucent [ColorScheme.surface] tint.
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.small,
    this.blurSigma = kMapFrostBlurSigma,
    this.surfaceAlpha = kMapFrostSurfaceAlpha,
    this.shadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blurSigma;
  final double surfaceAlpha;

  /// Soft lift shadow (timeline / legend cards); off for nested chrome.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: ColoredBox(
                  color: colors.surface.withValues(alpha: surfaceAlpha),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
