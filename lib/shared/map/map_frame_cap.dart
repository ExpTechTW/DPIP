import 'package:dpip/core/platform/render_tier.dart';

/// The most frames a second the map may draw on [tier], or `null` for the
/// panel's own rate.
///
/// A low-tier phone draws the map at 30 fps. Measured on a Pixel 9 at 60 Hz,
/// that cut pan power by 23% and double-tap zoom by 19%, for a visibly coarser
/// drag. The higher tier keeps the full rate.
int? mapMaxFps(RenderTier tier) => switch (tier) {
  RenderTier.low => 30,
  RenderTier.high => null,
};
