import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/weather/data/radar_api.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';

/// [RadarRepository] backed by [RadarApi], mapping transport errors to typed
/// failures via [guardResult].
class RadarRepositoryImpl implements RadarRepository {
  const RadarRepositoryImpl(this._api);

  final RadarApi _api;

  @override
  Future<Result<List<String>>> frames() => guardResult(_api.getFrames);

  @override
  String tileUrl(String frame) => _api.tileUrl(frame);
}
