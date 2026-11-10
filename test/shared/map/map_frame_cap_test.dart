/// Only a low-tier phone gives up frames to save power; every other device
/// keeps the panel's rate.
library;

import 'package:dpip/core/platform/render_tier.dart';
import 'package:dpip/shared/map/map_frame_cap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a low-tier phone draws the map at 30 fps', () {
    expect(mapMaxFps(RenderTier.low), 30);
  });

  test('a high-tier device keeps the panel rate', () {
    expect(mapMaxFps(RenderTier.high), isNull);
  });
}
