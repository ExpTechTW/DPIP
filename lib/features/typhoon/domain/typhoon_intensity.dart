/// CWA tropical-cyclone intensity from sustained wind (m/s).
library;

import 'package:dpip/core/a11y/color_vision.dart';

/// Near-centre max mean wind → CWA class (TD / mild / moderate / intense).
enum TyphoonIntensity {
  /// 熱帶性低氣壓 — below 17.2 m/s.
  td,

  /// 輕度颱風 — 17.2–32.6 m/s.
  mild,

  /// 中度颱風 — 32.7–50.9 m/s.
  moderate,

  /// 強烈颱風 — ≥ 51.0 m/s.
  intense,
}

/// GeoJSON `properties.intensity` / MapLibre match keys.
extension TyphoonIntensityWire on TyphoonIntensity {
  String get wire => name;

  /// Past-track stroke colour (hex) for map + legend.
  String get colorHex => switch (this) {
    TyphoonIntensity.td => '#2196F3'.vision,
    TyphoonIntensity.mild => '#43A047'.vision,
    TyphoonIntensity.moderate => '#FB8C00'.vision,
    TyphoonIntensity.intense => '#E53935'.vision,
  };
}

/// Classifies sustained wind (m/s). `null` / non-finite → `null` (grey fallback).
TyphoonIntensity? typhoonIntensityFromWind(double? windMs) {
  if (windMs == null || !windMs.isFinite) return null;
  if (windMs < 17.2) return TyphoonIntensity.td;
  if (windMs < 32.7) return TyphoonIntensity.mild;
  if (windMs < 51.0) return TyphoonIntensity.moderate;
  return TyphoonIntensity.intense;
}
