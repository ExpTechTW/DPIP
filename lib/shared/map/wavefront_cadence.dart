/// How often the EEW wave-front rings are redrawn, by device class — shared by
/// the live monitor and the report replay so both surfaces animate alike.
library;

import 'package:dpip/core/platform/render_tier.dart';

/// The redraw interval for the P/S wave-front rings on a [tier] device.
///
/// The rings are real polygon geometry, not a paint property MapLibre can
/// tween, so this interval *is* the animation's frame rate — and every frame
/// is a GeoJSON serialisation, a platform-channel hop and a re-tessellation on
/// the map's own thread.
///
/// - [RenderTier.high]: 16 ms, about display rate, for an expansion that reads
///   as continuous motion.
/// - [RenderTier.low]: 200 ms (5 Hz). On a 2–4 GB phone sixty ring uploads a
///   second compete with the map's rendering and the alert UI for the same
///   few cores, during the minute it matters most that both stay responsive.
///   The cost is smoothness, not accuracy: each redraw is computed from the
///   calibrated clock when it is sent, so a ring is never more than 200 ms
///   behind the model — the S wave moves about 0.7 km and the P wave about
///   1.2 km in that time, roughly a pixel at island zoom and well inside the
///   travel-time model's own uncertainty. Zoomed in to a city, the expansion
///   visibly steps rather than glides.
Duration wavefrontTick(RenderTier tier) => switch (tier) {
  RenderTier.high => const Duration(milliseconds: 16),
  RenderTier.low => const Duration(milliseconds: 200),
};
