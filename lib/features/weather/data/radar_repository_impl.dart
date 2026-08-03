import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/weather/data/frame_tile_repository.dart';
import 'package:dpip/features/weather/data/radar_api.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';

/// [RadarRepository] backed by [RadarApi], with tile warming from
/// [FrameTileRepository].
final class RadarRepositoryImpl extends FrameTileRepository
    implements RadarRepository {
  RadarRepositoryImpl(this._api, super.warmer);

  final RadarApi _api;

  @override
  int get maxZoom => 11;

  @override
  String get tilePathPrefix => '/api/v2/tiles/radar/';

  @override
  Future<Result<List<String>>> frames() => guardResult(_api.getFrames);

  @override
  String tileUrl(String frame) => _api.tileUrl(frame);
}
