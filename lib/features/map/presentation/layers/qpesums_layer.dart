import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';

/// The QPESUMS next-1-hour precipitation forecast (未來一小時降水預報) raster
/// overlay.
///
/// Everything about scrubbing lives in [RasterTimelineLayer]; this supplies
/// only the layer's identity, its opacity, and the QPESUMS hourly-rate colour
/// key. Frame ids are Unix milliseconds, which [parseFrameTime] already reads.
///
/// The forecast is anchored under the base style's county borders (the default
/// [rasterBelowLayerId]) — unlike radar there is no coverage outline here, so
/// the ordinary border-through-raster layering is exactly right.
class QpesumsMapLayer extends RasterTimelineLayer {
  QpesumsMapLayer(QpesumsRepository super.repository);

  @override
  String get id => 'qpesums';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerQpesums;

  @override
  IconData get icon => Icons.cloud_outlined;

  /// Slightly translucent so terrain and boundaries read through the forecast.
  @override
  double get opacity => 0.85;

  /// The frame times are forecast valid times, not observations — the timeline
  /// caption must say so instead of the shared "observed" default.
  @override
  String timelineCaption(BuildContext context) =>
      AppLocalizations.of(context).mapTimelineForecast;

  @override
  Widget buildLegend(BuildContext context) => MapLegendCard(
    child: const ColorScaleLegend(
      unit: 'mm/h',
      stops: [
        (1, '#9CFCFF'),
        (2, '#03C8FF'),
        (6, '#059BFF'),
        (10, '#0165FF'),
        (15, '#329400'),
        (20, '#38FF00'),
        (30, '#FFFB00'),
        (40, '#FFC800'),
        (50, '#FF9600'),
        (70, '#FF0000'),
        (90, '#CC0000'),
        (110, '#A00000'),
        (130, '#96009B'),
        (150, '#C900CC'),
        (200, '#FF00F0'),
        (300, '#FFC8FF'),
      ],
    ),
  );
}
