/// Shared tile plumbing for the frame-keyed raster overlays (radar, satellite).
library;

import 'package:dpip/shared/map/map_tile_warmer.dart';
import 'package:dpip/shared/map/raster_frame_source.dart';
import 'package:flutter/foundation.dart';

/// Implements the tile half of [RasterFrameSource] once.
///
/// Radar and satellite differ only in endpoint and zoom ceiling: both serve
/// `…/<frame>/{z}/{x}/{y}.webp`, so warming, abandoning, and releasing are
/// identical. Subclasses supply [frames], [tileUrl], and the two constants.
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
  static const double _fillTarget = 0.85;

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
