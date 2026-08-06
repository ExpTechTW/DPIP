import 'package:dpip/shared/map/raster_frame_source.dart';

/// Access to radar echo (雷達回波) frames — the weather feature's radar overlay
/// data, consumed by the map surface and the home backdrop.
///
/// The whole surface is [RasterFrameSource]: frame list, tile URL template, and
/// the tile-memory controls a scrubbable overlay needs. Named separately so
/// call sites read as "the radar repository" and so radar-only additions have a
/// home.
abstract interface class RadarRepository implements RasterFrameSource {}
