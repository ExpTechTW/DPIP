/// Shared tile plumbing for the frame-keyed raster overlays (radar, satellite,
/// QPESUMS).
library;

import 'dart:math' as math;

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
import 'package:dpip/shared/map/xyz_tiles.dart';
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
    bool immediate = false,
  }) {
    if (frames.isEmpty || !zoom.isFinite) return Future<void>.value();
    final groups = _viewportTileGroups(
      south: south,
      west: west,
      north: north,
      east: east,
      zoom: zoom,
    );
    if (groups.isEmpty) return Future<void>.value();
    return warmer.warmUrls(
      [
        // Frame order is preserved, so a fill warm injects nearest-the-finger
        // frames' tiles first and only the most distant stay cold when the
        // mirror fills. Within each frame the native display zoom comes first,
        // followed by its fallback and prefetch levels. Warming only
        // cameraZoom.floor() missed the z+1 requests MapLibre makes for 256 px
        // tiles on Retina displays, which made an apparently full L1 useless
        // during scrubs.
        for (final frame in frames)
          for (final group in groups)
            for (final tile in group) _urlFor(frame, tile),
      ],
      logLabel: '$tilePathPrefix×${frames.length}',
      fillUntil: fill ? _fillTarget : 0,
      immediate: immediate,
    );
  }

  @override
  Future<FrameTileReadiness> frameTileReadiness({
    required String frame,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool warm = false,
  }) async {
    if (!zoom.isFinite) {
      return (ready: false, resident: 0, required: 0);
    }
    final tileGroups = _viewportTileGroups(
      south: south,
      west: west,
      north: north,
      east: east,
      zoom: zoom,
    );
    if (tileGroups.isEmpty) {
      return (ready: false, resident: 0, required: 0);
    }
    final groups = [
      for (final tiles in tileGroups)
        [for (final tile in tiles) _urlFor(frame, tile)],
    ];
    final wanted = <String>{for (final group in groups) ...group};
    final resident = warm
        ? (await warmer.prepareUrls(wanted)).resident
        : await warmer.residentUrls(wanted);

    // Parent tiles are a useful visual fallback, but revealing on a complete
    // parent lets MapLibre replace it child-by-child a moment later — exactly
    // the patchwork flash this gate exists to prevent. The first group is the
    // highest display level native is expected to request, so only that whole
    // group makes the timestamp display-ready.
    final display = groups.first;
    return (
      ready: display.every(resident.contains),
      resident: display.where(resident.contains).length,
      required: display.length,
    );
  }

  List<List<XyzTile>> _viewportTileGroups({
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) {
    if (!zoom.isFinite) return const [];
    final idealZoom = math.min(zoom.floor(), maxZoom);
    final groups = <List<XyzTile>>[];
    // Native may pick one level above the nominal camera zoom on a Retina
    // display, retain a parent as fallback, and prefetch four source levels
    // below the display level for a later camera animation. The device trace at
    // zoom 6.00 requested z7, z6, z5 and z3. Preserve that priority for both the
    // background warm and the reveal gate; otherwise every L1-ready scrub mount
    // still performs one avoidable SQLite lookup for its z3 prefetch tile.
    for (final z in <int>{
      math.min(maxZoom, idealZoom + 1),
      idealZoom,
      math.max(0, idealZoom - 1),
      math.max(0, idealZoom - 3),
    }) {
      final tiles = viewportTiles(
        south: south,
        west: west,
        north: north,
        east: east,
        zoom: z.toDouble(),
        maxZoom: maxZoom,
        pad: 0,
      );
      if (tiles.isEmpty) continue;
      groups.add(tiles);
    }
    return groups;
  }

  String _urlFor(String frame, XyzTile tile) =>
      tileUrl(frame)
          .replaceFirst('{z}', '${tile.z}')
          .replaceFirst('{x}', '${tile.x}')
          .replaceFirst('{y}', '${tile.y}');

  @override
  void cancelTileWarm() => warmer.cancel();

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
