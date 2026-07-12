import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Radar echo (雷達回波) tile endpoints.
///
/// Frames are server-rendered XYZ raster PNG tiles, one set per timestamp; the
/// frame list returns the available timestamps. Served from the legacy host
/// (`api-1.exptech.dev`) until migrated to the region topology. The tiles are
/// fetched directly by MapLibre, so [tileUrl] hands out a concrete host URL.
class RadarApi {
  const RadarApi(this._client);

  final ApiClient _client;

  static const ApiTier _tier = ApiTier.legacyApi;

  /// Available radar frame timestamps, **newest first**.
  ///
  /// `https://api-1.exptech.dev/api/v1/tiles/radar/list`
  Future<List<String>> getFrames() async {
    final data = await _client.get(_tier, '/api/v1/tiles/radar/list') as List;
    return [for (final frame in data.reversed) frame.toString()];
  }

  /// XYZ raster tile URL template for a radar [frame].
  ///
  /// `https://api-1.exptech.dev/api/v1/tiles/radar/<frame>/{z}/{x}/{y}.png`
  String tileUrl(String frame) =>
      '${_client.hostsFor(_tier).first}/api/v1/tiles/radar/$frame/{z}/{x}/{y}.png';
}
