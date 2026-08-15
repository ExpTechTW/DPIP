/// The wind layer — rotated arrows pointing where the wind blows toward,
/// coloured by wind speed (legacy look). The tap reading carries the exact
/// degrees and the sheet chart colours the curve by the same speed ramp.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/geo/geo_math.dart';
import 'package:dpip/features/map/presentation/layers/weather_station_layer.dart';
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

  /// Shared arrow image ids (registered once per render) and the arrow layer
  /// id. One pre-coloured PNG per speed bucket — the black outline is baked
  /// into each (see [_renderArrow]), because MapLibre's `icon-halo-*` only
  /// works on *true* SDF images and this glyph is a plain bitmap.
  static const String _arrowImageId = 'wind-arrow';
  String get _arrowLayerId => 'wx-$id-arrow';

  /// The rendered arrow PNGs, cached — the glyph never changes; each bucket's
  /// colour + black outline are baked in at render time.
  List<Uint8List>? _arrowBytes;

  String _arrowImageFor(int bucket) => '$_arrowImageId-$bucket';

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
    final bytes = _arrowBytes ??= await _renderArrow();
    // One coloured, outline-baked PNG per bucket (no SDF — see [_renderArrow]).
    for (var i = 0; i < windBuckets.length; i++) {
      await controller.addImage(_arrowImageFor(i), bytes[i], false);
    }
    await controller.addSymbolLayer(
      sourceId,
      _arrowLayerId,
      SymbolLayerProperties(
        // Pick the pre-coloured glyph by speed; rotation is still applied at
        // runtime. (A single SDF tinted via iconColor was tried first, but
        // MapLibre's icon halo — the only outline SDF supports — renders ~0 on
        // a plain bitmap marked `sdf`, so the arrows had no readable edge.)
        iconImage: _arrowIconExpression(),
        iconRotate: <Object>['get', 'blow_to'],
        // Size scales with wind speed (bigger = stronger) and with zoom. Zoom
        // must be the OUTERMOST interpolate input (MapLibre only allows [zoom]
        // at the top level), with the speed interpolate nested per zoom stop.
        // Tuned for the 96 px glyph: ~32–80 px on screen at Taiwan overview
        // zooms. The previous 48 px glyph + 0.18 floors made calm arrows ~9 px.
        iconSize: <Object>[
          'interpolate',
          <Object>['linear'],
          <Object>['zoom'],
          5,
          <Object>[
            'interpolate',
            <Object>['linear'],
            <Object>['get', 'value'],
            0.0,
            0.35,
            3.4,
            0.42,
            8.0,
            0.52,
            13.9,
            0.65,
            32.7,
            0.85,
          ],
          11,
          <Object>[
            'interpolate',
            <Object>['linear'],
            <Object>['get', 'value'],
            0.0,
            0.70,
            3.4,
            0.85,
            8.0,
            1.05,
            13.9,
            1.30,
            32.7,
            1.70,
          ],
        ],
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

  /// Speed → pre-coloured arrow image, a `step` over the same 3.4 / 8.0 /
  /// 13.9 / 32.7 m/s thresholds as the legend (weakest first).
  List<Object> _arrowIconExpression() => <Object>[
    'step',
    <Object>['get', 'value'],
    _arrowImageFor(0),
    for (var i = 1; i < windBuckets.length; i++) ...[
      windBuckets[i].$1,
      _arrowImageFor(i),
    ],
  ];

  /// Renders [Icons.navigation] (points north at 0°) as five PNGs, one per
  /// speed bucket: each is the bucket colour with a black offset-outline baked
  /// in, so the arrow silhouette stays readable over pale tiles.
  ///
  /// These are plain bitmaps — **not** SDF. MapLibre's SDF halos only work on
  /// true signed-distance-field images (which require a blurred source),
  /// and treating this glyph as one made `icon-halo-width` paint ~nothing.
  Future<List<Uint8List>> _renderArrow() async {
    // 96 px base so iconSize ≈ 0.5–1.5 reads as a clear arrow (48 px + the
    // old 0.18 floors was sub-10 px on calm stations).
    const size = 96;
    const icon = Icons.navigation;
    // Outline thickness on the 96 px canvas — 8 offset copies around the glyph.
    const halo = 5.5;
    final outline = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 80,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: const Color(0xFF000000).vision,
        ),
      ),
    )..layout();
    final center = Offset(
      (size - outline.width) / 2,
      (size - outline.height) / 2,
    );
    final glyph = String.fromCharCode(icon.codePoint);
    return [
      for (final (_, fill) in windBuckets)
        await _renderOne(
          outline,
          fill,
          glyph: glyph,
          fontFamily: icon.fontFamily,
          fontPackage: icon.fontPackage,
          center: center,
          size: size,
          halo: halo,
        ),
    ];
  }

  Future<Uint8List> _renderOne(
    TextPainter outline,
    Color fill, {
    required String glyph,
    required String? fontFamily,
    required String? fontPackage,
    required Offset center,
    required int size,
    required double halo,
  }) async {
    final fillPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontSize: 80,
          fontFamily: fontFamily,
          package: fontPackage,
          color: fill,
        ),
      ),
    )..layout();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final (dx, dy) in windOutlineDirs) {
      outline.paint(canvas, center + Offset(dx * halo, dy * halo));
    }
    fillPainter.paint(canvas, center);
    final image = await recorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
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
  Widget buildLegend(BuildContext context) {
    // Corrected here, exactly as [windBuckets] is at its own definition: the
    // arrows are app-drawn glyphs, so the key follows the setting with them.
    final rows = <(String, String)>[
      ('≥ 32.7', '#FF006B'.vision),
      ('13.9 – 32.6', '#8000FF'.vision),
      ('8.0 – 13.8', '#0085FF'.vision),
      ('3.4 – 7.9', '#00FFF0'.vision),
      ('0.1 – 3.3', '#FFFFFF'.vision),
    ];
    final outline = Theme.of(context).colorScheme.outline;
    return MapLegendCard(
      child: SymbolLegend(
        unit: unit,
        items: [
          for (final (label, hex) in rows)
            SymbolLegendItem(
              // The arrow carries the same black outline as the map; the dark
              // disc behind pale / white glyphs keeps them readable on the
              // frosted card.
              swatch: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: outline.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: WindArrowIcon(
                  size: 14,
                  outline: 1.5,
                  color: colorFromHexRgb(hex) ?? Colors.white,
                ),
              ),
              label: label,
            ),
        ],
      ),
    );
  }
}
