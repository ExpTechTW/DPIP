/// Frosted-glass chrome for map overlays (legend, timeline, layer switcher).
///
/// Same BackdropFilter recipe as the home sheet at rest, tuned hotter for
/// short / small panels where ClipRRect eats most of a sigma-24 kernel.
library;

import 'dart:ui' show ImageFilter;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Default blur for compact map chrome (legend chip, layer button, timeline).
const double kMapFrostBlurSigma = 48;

/// Default surface tint alpha over the blurred map.
const double kMapFrostSurfaceAlpha = 0.72;

/// Extra tint a flat (unblurred) panel carries so its text stays legible over
/// a busy radar echo — a blur softens what is under the text, a flat tint has
/// only its own opacity to do that with.
const double kMapFrostFlatAlphaBoost = 0.08;

/// Whether chrome drawn over the native map may blur what is beneath it.
///
/// On iOS the map is a `UiKitView` and Flutter composites a `BackdropFilter`
/// over it through `UIVisualEffectView`, so the frost genuinely shows the map
/// through it. On Android the map is a platform view in one of two modes, and
/// in neither is the blur worth what it costs on the phones that matter:
///
/// - **HCPP** (API 34 + Vulkan, `EnableHcpp` in the manifest): the map is its
///   own `SurfaceControl` layer *under* Flutter's surface. A backdrop filter
///   can only read Flutter's own pixels, which are the transparent hole the
///   map shows through — so the blur samples nothing, draws nothing, and still
///   pays a full offscreen pass per filter per Flutter frame.
/// - **Virtual display** (everything else — every low-end phone): the map is a
///   texture in Flutter's scene, so the blur *does* reach it, but every map
///   frame then re-rasterises the whole Flutter layer tree through every
///   backdrop filter on screen. Five sigma-48 frosts over a panning radar was
///   the single largest GPU cost on those devices.
///
/// So Android draws the frost as a flat tint. `defaultTargetPlatform`, not
/// `dart:io`, so a test can override it.
bool get mapChromeBlursBackdrop =>
    defaultTargetPlatform != TargetPlatform.android;

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

  /// One [ImageFilter] per sigma, shared by every panel.
  ///
  /// [ImageFilter] has no value equality, so a fresh `blur(...)` on each build
  /// marks the backdrop layer changed and recomposites it even when nothing
  /// under the panel moved — the same trap the home sheet's cached blur
  /// documents. Sigma is a constant at nearly every call site, so this map
  /// holds one or two entries for the life of the app.
  static final Map<double, ImageFilter> _filters = {};

  static ImageFilter _filterFor(double sigma) => _filters.putIfAbsent(
    sigma,
    () => ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final blur = mapChromeBlursBackdrop && blurSigma > 0;
    final alpha = blur
        ? surfaceAlpha
        : (surfaceAlpha + kMapFrostFlatAlphaBoost).clamp(0.0, 1.0);
    final tint = ColoredBox(color: colors.surface.withValues(alpha: alpha));
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
              child: blur
                  ? BackdropFilter(filter: _filterFor(blurSigma), child: tint)
                  : tint,
            ),
            child,
          ],
        ),
      ),
    );
  }
}
