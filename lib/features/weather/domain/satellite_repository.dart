import 'package:dpip/core/error/result.dart';

/// Access to satellite IR cloud (衛星雲圖) frames — the weather feature's
/// Himawari overlay, consumed by the map surface.
///
/// Returns a [Result] so a failed frame fetch is explicit (never a silent
/// missing overlay). [tileUrl] builds the concrete tile URL MapLibre fetches.
abstract interface class SatelliteRepository {
  /// Available satellite frame timestamps, newest first; `Ok([])` when none.
  Future<Result<List<String>>> frames();

  /// XYZ raster tile URL template for a [frame].
  String tileUrl(String frame);
}
