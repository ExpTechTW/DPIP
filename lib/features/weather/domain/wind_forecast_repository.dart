import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/shared/map/raster_frame_source.dart';

/// Access to a numerical weather prediction wind field (數值預報風場) — one of
/// the ECMWF / GFS forecast models, consumed by the map surface.
///
/// The surface is [RasterFrameSource] (frame list, tile URL template, and the
/// tile-memory controls a scrubbable overlay needs) plus a [fetchWindField]
/// that returns the raw grid a frame's particle animation is advected by.
/// Named separately so call sites read as "the ECMWF/GFS wind repository" and
/// so forecast-specific additions have a home.
abstract interface class WindForecastRepository implements RasterFrameSource {
  /// The WND1 wind grid for [frame] (a Unix-second timestamp, the same id the
  /// tiles are keyed by) — the velocity field the overlay's particles ride on.
  Future<Result<WindField>> fetchWindField(String frame);
}
