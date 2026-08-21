import 'package:dpip/shared/map/raster_frame_source.dart';

/// Access to satellite IR cloud (衛星雲圖) frames — the weather feature's
/// Himawari overlay, consumed by the map surface.
///
/// The whole surface is [RasterFrameSource]: frame list, tile URL template, and
/// the tile-memory controls a scrubbable overlay needs. Named separately so call
/// sites read as "the satellite repository" and so satellite-only additions have
/// a home.
abstract interface class SatelliteRepository implements RasterFrameSource {
  /// Switches the colour rendering of **single-band** channels to [style] (a
  /// style path segment — `normal` / `jma` / `bd`); `null` restores `normal`.
  /// Named-product channels carry their own palette and ignore this.
  ///
  /// Live only — it changes the URL of subsequently fetched tiles; the caller
  /// decides whether to re-mount the layer (reload) so the map reflects it.
  void setStyle(String? style);
}
