/// A seismic (TREM) station's place, from `/resource/station`.
library;

/// One seismic station: where it is, and the township it stands in. The RTS
/// feed carries only readings keyed by [id] (a hex device id), so the monitor
/// joins them to these positions — and to [townCode] for the per-township
/// levels an alert lights up.
class SeismicStation {
  const SeismicStation({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.townCode,
  });

  final String id;
  final double latitude;
  final double longitude;

  /// The township's code, as `TownDirectory` keys it; null when the directory
  /// row had none.
  final String? townCode;
}
