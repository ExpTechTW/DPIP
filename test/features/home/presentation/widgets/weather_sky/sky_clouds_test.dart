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

  test('baked lights warm the probe, then scale by intensity and fog', () {
    final lighting = cloudLighting(sunAngleY: 0.5);
    const sky = (r: 0.4, g: 0.5, b: 0.6);
    const sunWarm = (r: 1.0, g: 0.74, b: 0.53);
    const groundWarm = (r: 0.85, g: 0.54, b: 0.37);
    const ambientWarm = (r: 0.96, g: 0.63, b: 0.42);
    const sunIntensity = 0.8;
    const fog = 0.5;
    final baked = bakeCloudLights(
      lighting: lighting,
      sunIntensity: sunIntensity,
      fog: fog,
      sunSky: sky,
      groundSky: sky,
      ambientSky: sky,
      backSky: sky,
    );

    // whitePer has to be in play, or this would not be testing the warm mix.
    final white = lighting.whitePer.clamp(0.0, 1.0);
    expect(white, greaterThan(0));
    final fogMulti = 1.0 - fog * fog;
    double channel({
      required double sample,
      required double multi,
      required double warm,
      required double intensity,
      required double fogScale,
    }) {
      final gained = sample * multi;
      final mixed = gained + (warm - gained) * white;
      final weight = 0.3 + (intensity - 0.3) * sunIntensity;
      return mixed * weight * fogScale;
    }

    expect(
      baked.sun.r,
      closeTo(
        channel(
          sample: sky.r,
          multi: lighting.sun.$2,
          warm: sunWarm.r,
          intensity: lighting.sun.$3,
          fogScale: fogMulti,
        ),
        1e-9,
      ),
    );
    expect(
      baked.sun.g,
      closeTo(
        channel(
          sample: sky.g,
          multi: lighting.sun.$2,
          warm: sunWarm.g,
          intensity: lighting.sun.$3,
          fogScale: fogMulti,
        ),
        1e-9,
      ),
    );
    expect(
      baked.sun.b,
      closeTo(
        channel(
          sample: sky.b,
          multi: lighting.sun.$2,
          warm: sunWarm.b,
          intensity: lighting.sun.$3,
          fogScale: fogMulti,
        ),
        1e-9,
      ),
    );
    expect(
      baked.ground.r,
      closeTo(
        channel(
          sample: sky.r,
          multi: lighting.ground.$2,
          warm: groundWarm.r,
          intensity: lighting.ground.$3,
          fogScale: fogMulti,
        ),
        1e-9,
      ),
    );
    expect(
      baked.ambient.b,
      closeTo(
        channel(
          sample: sky.b,
          multi: lighting.ambient.$2,
          warm: ambientWarm.b,
          intensity: lighting.ambient.$3,
          fogScale: fogMulti,
        ),
        1e-9,
      ),
    );
    expect(
      baked.sun.r,
      lessThan(
        channel(
          sample: sky.r,
          multi: lighting.sun.$2,
          warm: sunWarm.r,
          intensity: lighting.sun.$3,
          fogScale: 1,
        ),
      ),
      reason: 'fog squares away part of the sun',
    );
    // The thin-edge gain stays in the shader, so this probe is untouched.
    expect(baked.backSky, sky);
  });
}
