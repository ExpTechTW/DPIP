/// The intensity artwork is a fixed 64px canvas. MapLibre divides those
/// pixels by the scale recorded with the bitmap — the screen scale on both
/// iOS and Android — so the icon-size curve is multiplied by
/// `devicePixelRatio / 3` to land on the 3x iPhone size. A constant `1/3`
/// only did that on an mdpi Android panel.
library;

import 'package:dpip/shared/map/map_image_density.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// What a [artworkPixels] icon actually renders at, in points: MapLibre
  /// divides the image's pixels by the density the platform recorded with it.
  /// On both phones that divisor is the screen scale.
  double renderedPoints({
    required int artworkPixels,
    required List<Object> curve,
    required double iconSize,
    required double platformDivisor,
  }) => artworkPixels * iconSize / platformDivisor;

  double iconSizeAt(List<Object> curve, int zoomStop) =>
      curve[curve.indexOf(zoomStop) + 1] as double;

  test('a 3x iPhone is the reference: the factor is 1', () {
    expect(
      mapIconDensityFactor(isIOS: true, devicePixelRatio: 3),
      closeTo(1.0, 1e-9),
    );
  });

  test('Android follows the screen scale; only mdpi stays at 1/3', () {
    expect(
      mapIconDensityFactor(isIOS: false, isAndroid: true, devicePixelRatio: 1),
      closeTo(1 / 3, 1e-9),
    );
    expect(
      mapIconDensityFactor(isIOS: false, isAndroid: true, devicePixelRatio: 2),
      closeTo(2 / 3, 1e-9),
    );
    expect(
      mapIconDensityFactor(isIOS: false, isAndroid: true, devicePixelRatio: 3),
      closeTo(1.0, 1e-9),
    );
  });

  test('a lower-density iOS display scales the curve down with it', () {
    expect(
      mapIconDensityFactor(isIOS: true, devicePixelRatio: 1),
      closeTo(1 / 3, 1e-9),
    );
    expect(
      mapIconDensityFactor(isIOS: true, devicePixelRatio: 2),
      closeTo(2 / 3, 1e-9),
    );
  });

  test('a host with no platform keeps the artwork at its pixel size', () {
    expect(
      mapIconDensityFactor(isIOS: false, isAndroid: false),
      closeTo(1.0, 1e-9),
    );
  });

  test('the curve carries the factor', () {
    final unscaled = intensityIconSizeCurve(1);
    final mdpi = intensityIconSizeCurve(1 / 3);

    expect(iconSizeAt(unscaled, 5), closeTo(0.75, 1e-9));
    expect(iconSizeAt(unscaled, 15), closeTo(1.7, 1e-9));
    expect(iconSizeAt(mdpi, 5), closeTo(0.25, 1e-9));
    expect(iconSizeAt(mdpi, 15), closeTo(1.7 / 3, 1e-9));
  });

  test('every platform now renders the badge at the same point size', () {
    // Android's divisor is the screen scale, same as iOS. The 540×960
    // emulator is the mdpi row; a 1080×2340 phone is the 3x row.
    final cases = <({double factor, double divisor, String name})>[
      (
        name: 'Android 3x',
        factor: mapIconDensityFactor(
          isIOS: false,
          isAndroid: true,
          devicePixelRatio: 3,
        ),
        divisor: 3,
      ),
      (
        name: 'Android mdpi',
        factor: mapIconDensityFactor(
          isIOS: false,
          isAndroid: true,
          devicePixelRatio: 1,
        ),
        divisor: 1,
      ),
      (
        name: 'iPhone 3x',
        factor: mapIconDensityFactor(isIOS: true, devicePixelRatio: 3),
        divisor: 3,
      ),
      (
        name: '1x display',
        factor: mapIconDensityFactor(isIOS: true, devicePixelRatio: 1),
        divisor: 1,
      ),
    ];

    for (final zoomStop in [5, 15]) {
      final sizes = [
        for (final entry in cases)
          renderedPoints(
            artworkPixels: 64,
            curve: intensityIconSizeCurve(entry.factor),
            iconSize: iconSizeAt(
              intensityIconSizeCurve(entry.factor),
              zoomStop,
            ),
            platformDivisor: entry.divisor,
          ),
      ];
      for (final size in sizes) {
        expect(sizes.first, closeTo(size, 1e-9));
      }
    }
  });
}
