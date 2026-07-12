import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/widgets/home_content.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky_background.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

/// The draggable home sheet: a frosted panel over the map that reveals an
/// animated weather backdrop as it expands to full.
///
/// Owns the sheet's detent metrics ([restExtent] / [minExtent] / [maxExtent])
/// and maps the live [extent] onto surface opacity, backdrop blur, and the
/// weather backdrop's visibility. The scrollable content lives in [HomeContent];
/// the drag mechanics live in the host `HomePage`.
class HomeSheet extends StatelessWidget {
  const HomeSheet({
    super.key,
    required this.scrollController,
    required this.extent,
    required this.weatherMode,
  });

  /// Resting detent — bottom 1/3 of the screen.
  static const double restExtent = 1 / 3;

  /// Lowest the sheet can be dragged before it springs back to [restExtent].
  static const double minExtent = 0.08;

  /// Fully expanded — covers the whole map.
  static const double maxExtent = 1.0;

  /// Surface opacity at rest — translucent so the map shows through.
  static const double _restAlpha = 0.85;

  /// Extent at which the weather backdrop starts to appear (and animate).
  static const double _weatherFrom = 0.85;

  /// Extent past which the sheet flattens against the region bar — its top
  /// corners square off and its shadow fades — so it meets the bar flush
  /// instead of butting a rounded, shadowed edge against it.
  static const double _flushFrom = 0.9;

  /// The draggable sheet's scroll controller.
  final ScrollController scrollController;

  /// The sheet's live extent, `0`–`1` of the screen height.
  final ValueListenable<double> extent;

  /// Which weather look the backdrop renders.
  final WeatherMode weatherMode;

  double _surfaceAlpha(double e) {
    if (e >= restExtent) {
      final t = ((e - restExtent) / (maxExtent - restExtent)).clamp(0.0, 1.0);
      return lerpDouble(_restAlpha, 1, t)!;
    }
    final t = ((e - minExtent) / (restExtent - minExtent)).clamp(0.0, 1.0);
    return lerpDouble(0, _restAlpha, t)!;
  }

  double _weatherOpacity(double e) =>
      ((e - _weatherFrom) / (maxExtent - _weatherFrom)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<double>(
      valueListenable: extent,
      builder: (context, e, _) {
        // 0 until [_flushFrom], then 1 at full — drives the flatten + inset.
        final flush = ((e - _flushFrom) / (maxExtent - _flushFrom)).clamp(
          0.0,
          1.0,
        );
        final surfaceAlpha = _surfaceAlpha(e);
        final weatherOpacity = _weatherOpacity(e);
        final blur =
            24.0 *
            (surfaceAlpha / _restAlpha).clamp(0.0, 1.0) *
            (1 - weatherOpacity);
        final borderRadius = BorderRadius.vertical(
          top: Radius.circular(lerpDouble(AppRadius.lg, 0, flush)!),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15 * (1 - flush)),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Frosted map-through backdrop, dominant while collapsed.
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: ColoredBox(
                    color: colors.surface.withValues(alpha: surfaceAlpha),
                  ),
                ),
                // Animated weather backdrop, revealed and played near full —
                // it fills behind the region-bar overlay so the bar blends in.
                IgnorePointer(
                  child: Opacity(
                    opacity: weatherOpacity,
                    child: WeatherSkyBackground(
                      mode: weatherMode,
                      active: e >= _weatherFrom,
                    ),
                  ),
                ),
                HomeContent(scrollController: scrollController),
              ],
            ),
          ),
        );
      },
    );
  }
}
