import 'dart:io';

import 'package:dpip/core/platform/device_info.dart';

/// How much GPU/CPU a device can spend on decorative animation.
///
/// The animated weather backdrop (full-screen fragment shaders, ~1800 rain
/// particles) is authored for a mid-range phone. On the low end it should keep
/// the same look at a lower resolution and particle budget rather than drop
/// frames — a softer upscale reads as the same sky, a stutter does not.
enum RenderTier {
  /// Full-quality: the authored resolution and particle pools.
  high,

  /// Reduced: render at a lower internal scale and smaller particle pools.
  low,
}

/// Picks the tier from a device snapshot.
///
/// RAM is the cheap proxy for GPU class on Android — the devices that can't
/// drive a full-screen shader stack at 60 fps are the same 2–4 GB ones. iOS is
/// never downgraded (its oldest supported devices still outdraw them), and an
/// unknown/absent reading stays high — never degrade an experience on a
/// measurement we didn't get.
///
/// [isAndroid] is injectable so the host platform (`dart:io`) doesn't leak
/// into tests; production callers omit it.
RenderTier renderTierFor(DeviceDetails device, {bool? isAndroid}) {
  final totalMb = device.totalMemoryMb;
  if ((isAndroid ?? Platform.isAndroid) == false || totalMb == null) {
    return RenderTier.high;
  }
  return totalMb < 4096 ? RenderTier.low : RenderTier.high;
}
