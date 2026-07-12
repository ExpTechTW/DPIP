import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/shared/map/radar_api.dart';

/// Access to radar echo frames, shared by the map tab and the home backdrop.
///
/// Returns a [Result] so a failed frame fetch is explicit (never a silent
/// missing overlay). [tileUrl] builds the concrete tile URL MapLibre fetches.
abstract interface class RadarRepository {
  /// Available radar frame timestamps, newest first; `Ok([])` when none.
  Future<Result<List<String>>> frames();

  /// XYZ raster tile URL template for a [frame].
  String tileUrl(String frame);
}

/// [RadarRepository] backed by [RadarApi], mapping transport errors to typed
/// failures.
class RadarRepositoryImpl implements RadarRepository {
  const RadarRepositoryImpl(this._api);

  final RadarApi _api;

  @override
  Future<Result<List<String>>> frames() async {
    try {
      return Ok(await _api.getFrames());
    } catch (error) {
      return Err(mapException(error));
    }
  }

  @override
  String tileUrl(String frame) => _api.tileUrl(frame);
}
