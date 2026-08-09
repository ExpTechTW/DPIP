import 'package:dpip/shared/map/raster_frame_source.dart';

/// Access to QPESUMS next-1-hour precipitation forecast (未來一小時降水預報)
/// frames — the weather feature's QPESUMS overlay data, consumed by the map
/// surface.
///
/// The whole surface is [RasterFrameSource]: frame list, tile URL template, and
/// the tile-memory controls a scrubbable overlay needs. Named separately so
/// call sites read as "the QPESUMS repository" and so QPESUMS-only additions
/// have a home.
abstract interface class QpesumsRepository implements RasterFrameSource {}
