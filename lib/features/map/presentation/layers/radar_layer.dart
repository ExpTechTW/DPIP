import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';

/// The radar echo (雷達回波) raster overlay.
///
/// Everything about scrubbing — the preload ring, tile warming, scoped cancels —
/// lives in [RasterTimelineLayer]; this supplies only radar's identity, its
/// opacity, and the dBZ colour key.
class RadarMapLayer extends RasterTimelineLayer {
  RadarMapLayer(RadarRepository super.repository);

  @override
  String get id => 'radar';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerRadar;

  @override
  IconData get icon => Icons.radar_outlined;

  /// Slightly translucent so terrain and boundaries read through the echo.
  @override
  double get opacity => 0.85;

  @override
  Widget buildLegend(BuildContext context) => const MapLegendCard(
    child: ColorScaleLegend(
      unit: 'dBZ',
      stops: [
        (0, '#00FFFF'),
        (5, '#00A3FF'),
        (10, '#005BFF'),
        (15, '#0000FF'),
        (20, '#00D300'),
        (25, '#00A000'),
        (30, '#CCEA00'),
        (35, '#FFD300'),
        (40, '#FF8800'),
        (45, '#FF1800'),
        (50, '#D30000'),
        (55, '#A00000'),
        (60, '#EA00CC'),
        (65, '#9600FF'),
      ],
    ),
  );
}
