import 'package:dpip/core/platform/render_tier.dart';
import 'package:dpip/shared/map/wavefront_cadence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a capable phone redraws the rings at about display rate', () {
    expect(wavefrontTick(RenderTier.high), const Duration(milliseconds: 16));
  });

  test('a low-end phone redraws them at 5 Hz', () {
    expect(wavefrontTick(RenderTier.low), const Duration(milliseconds: 200));
  });
}
