/// A seismic (TREM) station's location, from `/api/v1/trem/station`.
library;

/// One seismic station's latest coordinates. The RTS feed carries only per-id
/// intensities, so the map joins them to these positions by station id.
class SeismicStation {
  const SeismicStation({
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final double latitude;
  final double longitude;
}
