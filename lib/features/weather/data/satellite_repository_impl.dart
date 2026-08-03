import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/features/weather/data/satellite_api.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/shared/map/ambient_prefetcher.dart';
import 'package:dpip/shared/map/xyz_tiles.dart';

/// [SatelliteRepository] backed by [SatelliteApi] + [AmbientPrefetcher].
class SatelliteRepositoryImpl implements SatelliteRepository {
  SatelliteRepositoryImpl(this._api, this._prefetch);

  final SatelliteApi _api;
  final AmbientPrefetcher _prefetch;

  static const ApiTier _tileTier = ApiTier.coreStaticExclusive;
  static const int _maxZoom = 11;

  @override
  Future<Result<List<String>>> frames() => guardResult(_api.getFrames);

  @override
  String tileUrl(String frame) => _api.tileUrl(frame);

  @override
  Future<void> prefetchFrameTiles({
    required List<String> frames,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) async {
    if (frames.isEmpty) return;
    final z = zoom.floor().clamp(0, _maxZoom);
    var tiles = tilesCovering(
      south: south,
      west: west,
      north: north,
      east: east,
      z: z,
      pad: 1,
      maxTiles: 48,
    );
    if (tiles.isEmpty && z > 0) {
      tiles = tilesCovering(
        south: south,
        west: west,
        north: north,
        east: east,
        z: z - 1,
        pad: 1,
        maxTiles: 48,
      );
    }
    if (tiles.isEmpty) return;
    final paths = <String>[
      for (final frame in frames)
        for (final t in tiles)
          '/api/v2/tiles/satellite/$frame/${t.z}/${t.x}/${t.y}.webp',
    ];
    await _prefetch.prefetchPaths(
      _tileTier,
      paths,
      logLabel: 'sat×${frames.length}',
    );
  }

  @override
  void cancelTilePrefetch() => _prefetch.cancel();
}
