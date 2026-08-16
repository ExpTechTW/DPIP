/// The wind-speed colour ramp and arrow glyph, shared by the map arrows and
/// the station sheet charts — one threshold table so the legend, the map, and
/// the trend plot agree by construction.
library;

import 'package:flutter/material.dart';
import 'package:dpip/core/a11y/color_vision.dart';

/// The five speed buckets, weakest first — the same thresholds / colours as the
/// legacy wind layer.
final windBuckets = <(double threshold, Color color)>[
  (0, Color(0xFFFFFFFF).vision), // 白 — calm
  (3.4, Color(0xFF00FFF0).vision), // 青
  (8.0, Color(0xFF0085FF).vision), // 藍
  (13.9, Color(0xFF8000FF).vision), // 紫
  (32.7, Color(0xFFFF006B).vision), // 粉 — strongest
];

/// Bucket index for [value] (0 = calm … 4 = strongest).
int windSpeedBucket(double value) {
  for (var i = windBuckets.length - 1; i >= 0; i--) {
    if (value >= windBuckets[i].$1) return i;
  }
  return 0;
}

/// The discrete ramp colour for [value].
Color windSpeedColor(double value) => windBuckets[windSpeedBucket(value)].$2;

/// The 8 offset directions (cardinal + diagonal) that bake a black outline
/// around the arrow glyph — used by the pre-rendered map PNGs
/// ([WindMapLayer._renderArrow]) and the Flutter [WindArrowIcon], so both
/// silhouettes share the same edge.
const windOutlineDirs = <(double, double)>[
  (1, 0),
  (-1, 0),
  (0, 1),
  (0, -1),
  (0.7071, 0.7071),
  (0.7071, -0.7071),
  (-0.7071, 0.7071),
  (-0.7071, -0.7071),
];

/// A [Icons.navigation] glyph with a black offset-outline baked on, tinted
/// [color] — the same silhouette as the map arrows, so a calm white arrow
/// stays readable on pale cards.
class WindArrowIcon extends StatelessWidget {
  const WindArrowIcon({
    super.key,
    required this.color,
    this.size = 12,
    this.outline = 1,
  });

  final Color color;

  /// Glyph size in logical pixels (the box grows by the outline so it isn't
  /// clipped by the rotation).
  final double size;

  /// Outline offset distance, in logical pixels.
  final double outline;

  @override
  Widget build(BuildContext context) {
    final pad = outline + 1;
    return SizedBox(
      width: size + pad * 2,
      height: size + pad * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (dx, dy) in windOutlineDirs)
            Transform.translate(
              offset: Offset(dx * outline, dy * outline),
              child: Icon(Icons.navigation, size: size, color: Colors.black),
            ),
          Icon(Icons.navigation, size: size, color: color),
        ],
      ),
    );
  }
}
