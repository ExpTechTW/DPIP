/// Cloud placement is pure arithmetic: a wrong wrap or a near-first sort
/// paints the deck inside-out, and the lighting ramps are what turn the
/// sprites gold at dusk.
library;

import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_clouds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoothstep clamps outside the ramp and eases the middle', () {
    expect(smoothstep(0, 1, -1), 0);
    expect(smoothstep(0, 1, 2), 1);
    expect(smoothstep(0, 1, 0), 0);
    expect(smoothstep(0, 1, 1), 1);
    // Hermite at the midpoint is exactly 0.5.
    expect(smoothstep(0, 1, 0.5), 0.5);
  });

  test('placeClouds hides a clear sky and wraps a deck blown off the left', () {
    expect(
      placeClouds(
        CloudLayout.fair,
        width: 200,
        height: 100,
        time: 0,
        coverage: 0,
      ),
      isEmpty,
    );

    final blown = placeClouds(
      CloudLayout.rain,
      width: 320,
      height: 180,
      time: 40,
      coverage: 2,
      wind: -4,
    );
    expect(blown, hasLength(CloudLayout.rain.clouds.length));
    for (var i = 1; i < blown.length; i++) {
      expect(blown[i - 1].depth, greaterThanOrEqualTo(blown[i].depth));
    }
    for (final cloud in blown) {
      expect(cloud.width, greaterThan(0));
      expect(cloud.height, greaterThan(0));
      expect(cloud.left.isFinite, isTrue);
    }
  });

  test('every authored deck places and lighting follows the sun', () {
    for (final layout in const [
      CloudLayout.fair,
      CloudLayout.scattered,
      CloudLayout.overcast,
      CloudLayout.rain,
    ]) {
      final placed = placeClouds(
        layout,
        width: 400,
        height: 200,
        time: 3,
        coverage: 0.4,
        wind: 0.2,
        spriteAspect: 2,
      );
      expect(placed, isNotEmpty);
      expect(placed.length, lessThanOrEqualTo(layout.clouds.length));
    }

    final night = cloudLighting(sunAngleY: 0);
    final noon = cloudLighting(sunAngleY: 0.5);
    expect(night.whitePer, 0);
    expect(noon.whitePer, greaterThan(0));
    expect(noon.sun.$3, greaterThan(night.sun.$3));
    expect(noon.base.$1, greaterThan(night.base.$1));
  });
}
