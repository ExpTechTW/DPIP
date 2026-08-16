/// Shared tile plumbing for the frame-keyed raster overlays (radar, satellite,
/// QPESUMS).
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/features/weather/data/frame_tile_api.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/shared/map/map_tile_warmer.dart';
import 'package:dpip/shared/map/raster_frame_source.dart';
import 'package:flutter/foundation.dart';

/// Implements the tile half of [RasterFrameSource] once.
///
/// Radar, satellite, and QPESUMS differ only in endpoint and zoom ceiling:
/// all serve `…/<frame>/{z}/{x}/{y}.webp`, so warming, abandoning, and
/// releasing are identical. Subclasses supply [frames], [tileUrl], and the two
/// constants.
///
/// Every URL here is built from [tileUrl] itself rather than reassembled from
/// parts — a warmed key that differs from what MapLibre requests by so much as
/// a host would warm nothing while looking like it worked.
abstract base class FrameTileRepository implements RasterFrameSource {
  FrameTileRepository(this.warmer);

  @protected
  final MapTileWarmer warmer;

  /// Highest zoom this source publishes tiles for — asking beyond it warms keys
  /// that will never exist.
  @protected
  int get maxZoom;

  /// URL fragment common to every frame of this source (e.g.
  /// `/api/v2/tiles/radar/`), used to scope cancels and memory eviction.
  @protected
  String get tilePathPrefix;

  /// How close to native's mirror cap a fill warm fills to — a little under the
  /// cap (native trims only beyond it), so the mirror stays full but never
  /// churns.
  static const double _fillTarget = 0.9;

  @override
  Future<void> warmFrameTiles({
    required List<String> frames,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool fill = false,
  }) {
    if (frames.isEmpty) return Future<void>.value();
    final tiles = viewportTiles(
      south: south,
      west: west,
      north: north,
      east: east,
      zoom: zoom,
      maxZoom: maxZoom,
    );
    if (tiles.isEmpty) return Future<void>.value();
    return warmer.warmUrls(
      [
        // Frame order is preserved, so a fill warm injects nearest-the-finger
        // frames' tiles first and only the most distant stay cold when the
        // mirror fills.
        for (final frame in frames)
          for (final tile in tiles)
            tileUrl(frame)
                .replaceFirst('{z}', '${tile.z}')
                .replaceFirst('{x}', '${tile.x}')
                .replaceFirst('{y}', '${tile.y}'),
      ],
      logLabel: '$tilePathPrefix×${frames.length}',
      fillUntil: fill ? _fillTarget : 0,
    );
  }

  @override
  Future<void> abandonFrames(List<String> frames) =>
      warmer.abandon([for (final frame in frames) _framePrefix(frame)]);

  @override
  Future<void> releaseTiles() => warmer.release([tilePathPrefix]);

  /// The URL prefix every tile of [frame] shares — the template up to `{z}`.
  String _framePrefix(String frame) => tileUrl(frame).split('{z}').first;
}

/// [RasterFrameSource] for one v2 tile overlay, backed by [FrameTileApi].
///
/// The concrete overlay is selected by the API's [FrameTileApi.path]. The four
/// per-overlay domain interfaces are empty aliases of [RasterFrameSource], so a
/// single parameterised impl satisfies them all; the provider layer still
/// injects each overlay under its own interface.
final class FrameTileRepositoryImpl extends FrameTileRepository
    implements
        RadarRepository,
        SatelliteRepository,
        QpesumsRepository,
        WindForecastRepository {
  FrameTileRepositoryImpl(this._api, super.warmer, {this.maxZoom = 11});

  final FrameTileApi _api;

  /// Highest zoom this overlay publishes tiles for. Radar / satellite /
  /// QPESUMS reach 11; the 0.25° wind forecast grids stop at 7 (any deeper is
  /// upsampled to nothing new).
  @override
  final int maxZoom;

  @override
  String get tilePathPrefix => '${ApiPaths.tiles}/${_api.path}/';

  @override
  Future<Result<List<String>>> frames() => guardResult(_api.getFrames);

  @override
  String tileUrl(String frame) => _api.tileUrl(frame);

  @override
  Future<Result<WindField>> fetchWindField(String frame) =>
      guardResult(() async {
        final bytes = await _api.fetchWindBin(frame);
        return WindField.fromWnd1(bytes);
      });

  @override
  void setStyle(String? style) => _api.style = style;
}
