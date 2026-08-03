import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/weather/data/satellite_api.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';

/// [SatelliteRepository] backed by [SatelliteApi], mapping transport errors to
/// typed failures via [guardResult].
class SatelliteRepositoryImpl implements SatelliteRepository {
  const SatelliteRepositoryImpl(this._api);

  final SatelliteApi _api;

  @override
  Future<Result<List<String>>> frames() => guardResult(_api.getFrames);

  @override
  String tileUrl(String frame) => _api.tileUrl(frame);
}
