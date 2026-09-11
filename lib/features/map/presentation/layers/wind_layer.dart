/// The wind layer — rotated arrows pointing where the wind blows toward,
/// coloured by wind speed (legacy look). The tap reading carries the exact
/// degrees and the sheet chart colours the curve by the same speed ramp.
///
/// Every arrow on the map is drawn by [WindArrowOverlay], which the radar
/// echo's wind option mounts too, so the two surfaces cannot drift into two
/// different-looking keys; this layer supplies only the station source the
/// arrows sit on, the tap reading and the trend sheet.
library;

import 'package:dpip/core/geo/geo_math.dart';
import 'package:dpip/features/map/presentation/layers/weather_station_layer.dart';
import 'package:dpip/features/map/presentation/layers/wind_arrow_overlay.dart';
import 'package:dpip/features/map/presentation/wind_speed.dart';
import 'package:dpip/features/map/presentation/widgets/station_sheet.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class WindMapLayer
    extends
        WeatherStationLayer<WeatherSnapshot, WeatherObservation, WeatherTrend> {
  WindMapLayer(super.repository);

  /// The arrow layer this layer adds on its station source. The glyphs
  /// themselves — the per-bucket images, the `step` that picks one, the zoom ×
  /// speed size ramp — come from [WindArrowOverlay], shared with the radar
  /// echo's wind option.
  String get _arrowLayerId => 'wx-$id-arrow';

  @override
  String get id => 'wind';

  @override
  IconData get icon => Icons.air;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerWind;

  @override
  String get unit => 'm/s';

  @override
  double? get chartMinY => 0;

  @override
  int get decimals => 1;

  @override
  double? valueOf(WeatherObservation observation) => observation.windSpeed;

  @override
  List<double?> trendOf(WeatherTrend trend) => trend.windSpeed;

  /// Speed curve + parallel direction series so the sheet chart can draw
  /// wind-barbs on the line (plain speed-only charts hide the whole point).
  @override
  TrendSeries seriesOf(WeatherTrend trend) => TrendSeries(
    times: trend.times,
    values: trend.windSpeed,
    directions: trend.windDirection,
  );

  // Arrows replace the dots (legacy) — the direction is the whole point.
  @override
  bool get drawCircle => false;

  @override
  List<String> get extraLayerIds => [_arrowLayerId];

  /// A `blow_to` bearing for stations that report a direction (meteorological
  /// "from" + 180° = where the wind blows toward); direction-less stations get
  /// no key and so are filtered out of the arrow layer.
  @override
  Map<String, Object?> extraProperties(WeatherObservation observation) {
    final from = observation.windDirection;
    if (from == null) return const {};
    return {'blow_to': (from + 180) % 360};
  }

  @override
  Future<void> decorate(
    MapLibreMapController controller,
    String sourceId,
  ) async {
    await WindArrowOverlay.registerImages(controller);
    await controller.addSymbolLayer(
      sourceId,
      _arrowLayerId,
      SymbolLayerProperties(
        // Pick the pre-coloured glyph by speed; rotation is still applied at
        // runtime. (A single SDF tinted via iconColor was tried first, but
        // MapLibre's icon halo — the only outline SDF supports — renders ~0 on
        // a plain bitmap marked `sdf`, so the arrows had no readable edge.)
        iconImage: WindArrowOverlay.iconExpression(),
        iconRotate: <Object>['get', 'blow_to'],
        iconSize: WindArrowOverlay.sizeExpression(),
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        // Rotate with the map so a bearing stays geographically correct.
        iconRotationAlignment: 'map',
      ),
      filter: <Object>['has', 'blow_to'],
      // Non-interactive so taps route to map#onMapClick → onMapTap (the base
      // does its own nearest-station selection), not the unhandled feature#onTap.
      enableInteraction: false,
    );
  }

  /// Speed reading plus the direction it blows from (degrees). The arrow is
  /// drawn as a rotated glyph by [readingIcon], not as a text arrow.
  @override
  String? reading(String id) {
    final observation = observationOf(id);
    final speed = observation?.windSpeed;
    if (speed == null) return null;
    final text = '${speed.toStringAsFixed(decimals)} $unit';
    final direction = observation!.windDirection;
    if (direction == null) return text;
    return '$text  $direction°';
  }

  /// A navigation glyph rotated to where the wind blows *towards*, tinted by
  /// the same speed ramp as the map arrows (with a baked-on black outline so a
  /// calm white arrow stays visible on the sheet).
  @override
  Widget? readingIcon(String id) {
    final observation = observationOf(id);
    final speed = observation?.windSpeed;
    final from = observation?.windDirection;
    if (speed == null || from == null) return null;
    return Transform.rotate(
      angle: degToRad(from + 180),
      child: WindArrowIcon(
        size: 26,
        outline: 1.5,
        color: windSpeedColor(speed),
      ),
    );
  }

  /// The hero dot beside the name uses the discrete ramp colour — the same the
  /// arrow, the curve, and the X-axis glyphs carry, so the sheet reads one
  /// consistent speed colour rather than an interpolation between buckets.
  @override
  Color? valueColor(String id) {
    final speed = observationOf(id)?.windSpeed;
    return speed == null ? null : windSpeedColor(speed);
  }

  // The shared discrete ramp (white → pink), declared here so the base
  // contract's dot/legend machinery reads the same colours the arrows use.
  // The bucket colours are corrected at their definition ([windBuckets]), so
  // they arrive here already transformed — `toHexRgb` stays a pure converter.
  @override
  List<(double, String)> get colorStops => [
    for (final (at, color) in windBuckets) (at, color.toHexRgb()),
  ];

  /// Discrete speed buckets (strongest first) — same thresholds / colours as
  /// the arrow `step`, with a navigation glyph so the legend matches the map.
  @override
  Widget buildLegend(BuildContext context) => MapLegendCard(
    // The unit rides under the list here (this card has room for it), so the
    // rows themselves are asked for without it.
    child: SymbolLegend(
      unit: unit,
      items: WindArrowOverlay.legendItems(context),
    ),
  );
}
