/// Highest DPM MVT level that carries distinct point features.
///
/// Probed 2026-08-26 across 20 Taiwan cities/islands: AED, restroom, and
/// shelter had identical in-bounds feature sets at z15 and z16. Z14 still
/// omitted features, so MapLibre may overzoom z15 but must not stop lower.
const double dpmSourceMaxZoom = 15;
