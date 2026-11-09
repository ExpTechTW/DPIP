import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_sky_painter.dart';

/// Minimum time between painted sky frames for this scene.
///
/// Clouds, stars and the sun drift slowly enough that a full-screen picture
/// on every vsync is wasted. Rain and a lightning strike do not: a near drop
/// falls a few percent of the screen in one frame, and a bolt is a flash.
/// Snow sits between them. Rain and a strike share the fast budget and are
/// checked first, so either one outranks snow — a rain-snow mix, or a bolt
/// over snow, stays on the rain clock.
///
/// The gates are the painter's own ([skyPrecipitationOn] and
/// [LightningFrame.isActive]). 16 ms and 33 ms are both under the backdrop's
/// 1/20 s particle clamp, so a paced rain or snow step is not shortened and
/// the flakes are not slowed. The calm budget can reach that clamp; nothing
/// on that path integrates `dt`.
Duration skyFrameInterval({
  required double rain,
  required double snow,
  required LightningFrame lightning,
}) {
  if (skyPrecipitationOn(rain) || lightning.isActive) {
    return const Duration(milliseconds: 16);
  }
  if (skyPrecipitationOn(snow)) {
    return const Duration(milliseconds: 33);
  }
  return const Duration(milliseconds: 66);
}
