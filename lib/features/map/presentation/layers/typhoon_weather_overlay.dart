/// Optional weather raster under the typhoon vectors — radar XOR satellite IR.
library;

/// Stacked under typhoon chrome; mutually exclusive. Frame time is the closest
/// tile ≤ the active typhoon bulletin second (see [closestAtOrBefore]).
enum TyphoonWeatherOverlay {
  /// No weather raster (meteor track-image PNG may still show).
  none,

  /// Composite radar reflectivity tiles.
  radar,

  /// Himawari infrared tiles.
  satellite,
}
