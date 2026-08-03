/// Disaster-prevention map repository — wires [DisasterMapApi] into domain.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/disaster_map/data/disaster_map_api.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';

/// [DisasterMapRepository] backed by [DisasterMapApi].
class DisasterMapRepositoryImpl implements DisasterMapRepository {
  const DisasterMapRepositoryImpl(this._api);

  final DisasterMapApi _api;

  @override
  String tileUrl(String layer) => _api.tileUrl(layer);

  @override
  Future<Result<AedDetail>> aedDetail(int id) => guardResult(() async {
    final json = await _api.getAedDetail(id);
    return AedDetail.fromJson(json);
  });
}
