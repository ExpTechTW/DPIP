import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/weather/data/frame_tile_repository.dart';
import 'package:dpip/features/weather/data/satellite_api.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';

/// [SatelliteRepository] backed by [SatelliteApi], with tile warming from
/// [FrameTileRepository].
final class SatelliteRepositoryImpl extends FrameTileRepository
    implements SatelliteRepository {
  SatelliteRepositoryImpl(this._api, super.warmer);

  final SatelliteApi _api;

  @override
  int get maxZoom => 11;

  @override
  String get tilePathPrefix => '/api/v2/tiles/satellite/';

  @override
  Future<Result<List<String>>> frames() => guardResult(_api.getFrames);

  @override
  String tileUrl(String frame) => _api.tileUrl(frame);
}
