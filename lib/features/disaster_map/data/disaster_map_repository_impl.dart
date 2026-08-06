/// Disaster-prevention map repository — wires [DisasterMapApi] into domain.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/disaster_map/data/disaster_map_api.dart';
import 'package:dpip/features/disaster_map/data/dpm_tile_prefetcher.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:dpip/features/disaster_map/domain/restroom_detail.dart';
import 'package:dpip/features/disaster_map/domain/shelter_detail.dart';

/// [DisasterMapRepository] backed by [DisasterMapApi] + [DpmTilePrefetcher].
class DisasterMapRepositoryImpl implements DisasterMapRepository {
  DisasterMapRepositoryImpl(this._api, this._prefetcher);

  final DisasterMapApi _api;
  final DpmTilePrefetcher _prefetcher;

  @override
  String tileUrl(String layer) => _api.tileUrl(layer);

  @override
  Future<Result<AedDetail>> aedDetail(int id) => guardResult(() async {
    final json = await _api.getAedDetail(id);
    return AedDetail.fromJson(json);
  });

  @override
  Future<Result<RestroomDetail>> restroomDetail(int id) =>
      guardResult(() async {
        final json = await _api.getRestroomDetail(id);
        return RestroomDetail.fromJson(json);
      });

  @override
  Future<Result<ShelterDetail>> shelterDetail(int id) => guardResult(() async {
    final json = await _api.getShelterDetail(id);
    return ShelterDetail.fromJson(json);
  });

  @override
  Future<void> prefetchTiles({
    required String layer,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) => _prefetcher.prefetch(
    layer: layer,
    south: south,
    west: west,
    north: north,
    east: east,
    zoom: zoom,
  );

  @override
  void cancelTilePrefetch() => _prefetcher.cancel();
}
