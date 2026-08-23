/// What a raster timeline layer needs from a feature's repository.
library;

import 'package:dpip/core/error/result.dart';

/// How much of one frame's current viewport is already in MapLibre's L1.
///
/// [ready] is computed by the repository from complete display-resolution
/// coverage, not from a raw percentage: every viewport tile at the native
/// display level must be resident before a timeline may replace the frame.
typedef FrameTileReadiness = ({bool ready, int resident, int required});

/// The tile-side contract behind a scrubbable raster overlay (radar echo,
/// satellite IR, …).
///
/// A feature's `Repository` implements this so [RasterTimelineLayer] can drive
/// any of them without knowing which — the layer owns MapLibre bookkeeping, the
/// repository owns endpoints and URL shape.
abstract interface class RasterFrameSource {
  /// Available frame ids, newest first; `Ok([])` when none.
  Future<Result<List<String>>> frames();

  /// Highest zoom this overlay's tiles genuinely exist for.
  ///
  /// Measured from the live endpoints, not guessed: radar / QPESUMS publish
  /// real bytes for z3–12 and satellite / wind z0–11 (everything outside is
  /// the empty placeholder), but each product's own resolution runs out around
  /// z7–8 — deeper levels are the server resampling the same pixels, so a
  /// request there costs a full viewport of round trips per zoom crossing and
  /// gains no detail. The timeline passes this as the MapLibre source
  /// `maxzoom`, so the renderer overzooms the top level instead of fetching
  /// placeholders.
  int get sourceMaxZoom;

  /// XYZ raster tile URL **template** for [frame] (contains `{z}/{x}/{y}`).
  String tileUrl(String frame);

  /// Pushes the cached bytes for each of [frames]' viewport tiles into
  /// MapLibre's in-process tile memory, so revealing those frames costs no I/O.
  ///
  /// Local only — a tile the app has never downloaded stays a miss, and
  /// MapLibre fetches it the ordinary way.
  ///
  /// When [fill] is true, [frames] must be ordered nearest-the-finger first and
  /// the implementation tops the native mirror up until it is nearly full,
  /// skipping nothing it holds already — so a timeline can warm far past its
  /// mounted ring and only the most distant frames stay cold.
  /// [refreshResident] overwrites matching L1 entries from L2 once after a
  /// hidden map returns; native presence alone cannot distinguish a decodable
  /// image from a failed placeholder retained under the same URL.
  Future<void> warmFrameTiles({
    required List<String> frames,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool fill = false,
    bool immediate = false,
    bool refreshResident = false,
  });

  /// Probes the tiles needed to reveal one [frame] in the current viewport.
  ///
  /// With [warm] true, cached L2 bodies are first pushed into L1. This never
  /// starts HTTP itself; mounting the frame's transparent raster layer is what
  /// lets MapLibre fetch a genuinely cold tile. Callers can then poll with
  /// [warm] false until the complete native display level is resident.
  Future<FrameTileReadiness> frameTileReadiness({
    required String frame,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool warm = false,
  });

  /// Cancels a pending or in-flight speculative L1 warm without evicting the
  /// bytes already resident there.
  ///
  /// Timeline scrubbing calls this as soon as the finger moves to a new frame:
  /// the final destination is not known yet, so a large SQLite read centred on
  /// the previous settle must yield before it reaches the injection bridge.
  void cancelTileWarm();

  /// Aborts in-flight tile HTTP for [frames] — a scrub swept past them and
  /// their tiles will never be drawn.
  ///
  /// Scoped on purpose: cancelling everything would take the basemap and the
  /// frame the user actually landed on down with it.
  Future<void> abandonFrames(List<String> frames);

  /// Cancels any pending warm and drops this source's tiles from MapLibre's
  /// memory (bytes stay in the app's store). For a layer switch / teardown.
  Future<void> releaseTiles();
}
