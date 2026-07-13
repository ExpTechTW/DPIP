import 'package:dpip/core/error/result.dart';

/// Access to radar echo (雷達回波) frames — the weather feature's radar overlay
/// data, consumed by the map surface and the home backdrop.
///
/// Returns a [Result] so a failed frame fetch is explicit (never a silent
/// missing overlay). [tileUrl] builds the concrete tile URL MapLibre fetches.
/// The first of the rain/lightning/typhoon overlay family that will live here.
abstract interface class RadarRepository {
  /// Available radar frame timestamps, newest first; `Ok([])` when none.
  Future<Result<List<String>>> frames();

  /// XYZ raster tile URL template for a [frame].
  String tileUrl(String frame);
}
