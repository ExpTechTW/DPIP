/// Repository for disaster-prevention map (DPM) layers — AED today, more later.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/restroom_detail.dart';
import 'package:dpip/features/disaster_map/domain/shelter_detail.dart';

/// DPM tile URLs + per-layer detail fetches. Tiles are also warm-prefetched
/// into MapLibre ambient via [prefetchTiles]; detail is app-fetched on tap.
abstract interface class DisasterMapRepository {
  /// XYZ MVT template for [layer] (e.g. `aed`, `restroom`, `shelter`).
  ///
  /// `https://static.core-tnn1.exptech.dev/api/v2/tiles/dpm/{layer}/{z}/{x}/{y}.mvt`
  String tileUrl(String layer);

  /// AED detail by internal tile feature [id] (not `aed_id`).
  Future<Result<AedDetail>> aedDetail(int id);

  /// Restroom detail by internal tile feature [id].
  Future<Result<RestroomDetail>> restroomDetail(int id);

  /// Shelter detail by internal tile feature [id].
  Future<Result<ShelterDetail>> shelterDetail(int id);

  /// Fetch viewport [layer] MVT via app HTTP (+ ETag) and pin into MapLibre
  /// ambient under the same HTTPS URLs the baked style uses.
  Future<void> prefetchTiles({
    required String layer,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  });

  /// Abort any in-flight [prefetchTiles].
  void cancelTilePrefetch();
}
