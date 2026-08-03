import 'package:dpip/core/error/result.dart';

/// Access to radar echo (雷達回波) frames — the weather feature's radar overlay
/// data, consumed by the map surface and the home backdrop.
///
/// Returns a [Result] so a failed frame fetch is explicit (never a silent
/// missing overlay). [tileUrl] builds the concrete tile URL MapLibre fetches;
/// [prefetchFrameTiles] warms those same URLs via ApiClient + ambient preload.
abstract interface class RadarRepository {
  /// Available radar frame timestamps, newest first; `Ok([])` when none.
  Future<Result<List<String>>> frames();

  /// XYZ raster tile URL template for a [frame].
  String tileUrl(String frame);

  /// Fetch viewport WebP tiles for each of [frames] via ApiClient (ETag) and
  /// pin into MapLibre ambient under the same HTTPS URLs (one generation).
  Future<void> prefetchFrameTiles({
    required List<String> frames,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  });

  /// Abort in-flight [prefetchFrameTiles].
  void cancelTilePrefetch();
}
