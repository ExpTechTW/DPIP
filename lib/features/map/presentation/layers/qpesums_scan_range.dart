import 'package:dpip/features/map/presentation/layers/radar_scan_range.dart';

/// The area the QPESUMS next-1-hour precipitation forecast covers.
///
/// A plain rectangle, and **not** [RadarScanRange]'s geometry. The composite
/// the radars observe is a union of four range circles clipped to a wider grid;
/// the forecast is computed on its own grid and published over all of it, so
/// outlining it with the radar circles claimed coverage on the corners the
/// forecast does have and denied it along the edges of the circles.
///
/// 441 × 561 cells at the same 0.0125° step the composite uses. 118.0°E,
/// 20.0°N is the south-west edge of the first cell; the opposite **outer**
/// edges are `118.0 + 441 × 0.0125 = 123.5125` and
/// `20.0 + 561 × 0.0125 = 27.0125`. The bounds are written out rather than
/// derived so the numbers in the file are the numbers on the wire.
abstract final class QpesumsScanRange {
  QpesumsScanRange._();

  /// Grid step, in degrees — the same resolution as the radar composite.
  static const double gridResolution = 0.0125;

  static const double west = 118.0;
  static const double east = 123.5125;
  static const double south = 20.0;
  static const double north = 27.0125;

  /// Source and layer ids, kept distinct from the radar raster's own so a map
  /// showing both draws two outlines instead of clashing over one.
  static const String sourceId = 'qpesums-scan-range';
  static const String outlineLayerId = 'qpesums-scan-range-outline';

  /// The rectangle as a closed, counter-clockwise `[lon, lat]` ring — right
  /// edge up, top edge across, left edge down, and back.
  ///
  /// Four corners is exact here: this is Web Mercator, where a constant
  /// latitude projects to a horizontal straight line and a constant longitude
  /// to a vertical one, so densifying the edges would add vertices that all
  /// land on the segment already being drawn.
  static const List<List<double>> ring = [
    [east, south],
    [east, north],
    [west, north],
    [west, south],
    [east, south],
  ];

  /// The coverage outline as a GeoJSON polygon.
  ///
  /// A **map**, never an encoded string: `addSource` hands this straight to
  /// `NSJSONSerialization.dataWithJSONObject` on iOS, which throws — crashing
  /// the app, not returning an error — on a top-level string.
  static Map<String, dynamic> geoJson() => {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'properties': <String, Object?>{
          'name': 'effective_extent',
          'note': 'QPESUMS forecast grid, 441×561 cells at 0.0125°',
        },
        'geometry': {
          'type': 'Polygon',
          'coordinates': [ring],
        },
      },
    ],
  };
}
