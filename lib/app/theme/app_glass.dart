import 'package:flutter/material.dart';

/// Reveal-driven "glass" tinting for content layered over the weather backdrop.
///
/// As a `reveal` dial rises 0→1 (the home sheet exposing the weather behind it),
/// surfaces frost toward translucent light glass and foregrounds shift to white
/// so they stay legible. These two lerps recurred verbatim across the home sheet
/// and region bar; centralising them here (in the design-system layer, reachable
/// from `shared/` and `features/`) keeps every glass surface and lightened
/// foreground in lockstep instead of copying the same tints and magic alphas.

/// The translucent card/surface tint: an opaque
/// [ColorScheme.surfaceContainerHighest] fading to frosted white as [reveal]
/// rises.
Color glassSurface(ColorScheme colors, double reveal) => Color.lerp(
  colors.surfaceContainerHighest.withValues(alpha: 0.55),
  Colors.white.withValues(alpha: 0.16),
  reveal,
)!;

/// Shifts a foreground [base] colour toward white as [reveal] rises, so text and
/// icons stay legible once the backdrop takes over. [toAlpha] tunes the target
/// white's opacity (default fully opaque).
Color lightenOnReveal(Color base, double reveal, {double toAlpha = 1}) =>
    Color.lerp(base, Colors.white.withValues(alpha: toAlpha), reveal)!;
