import 'dart:ui' show Size;

import 'package:dpip/shared/map/camera_fit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() {
  group('boundsFitCamera', () {
    final box = LatLngBounds(
      southwest: const LatLng(22.0, 120.0),
      northeast: const LatLng(25.0, 122.0),
    );
    const viewport = Size(400, 800);

    test('centres on the box with a finite, in-range fit zoom', () {
      final fit = boundsFitCamera(box, viewport: viewport)!;
      expect(fit.zoom.isFinite, isTrue);
      expect(fit.zoom, inInclusiveRange(2, 16));
      expect(fit.target.longitude, closeTo(121.0, 0.05));
      expect(fit.target.latitude, closeTo(23.5, 0.3));
    });

    test(
      'a bottom inset lifts the box into the band (target shifts south)',
      () {
        final plain = boundsFitCamera(box, viewport: viewport)!;
        final inset = boundsFitCamera(
          box,
          viewport: viewport,
          bottomInset: 300,
        )!;
        expect(inset.target.latitude, lessThan(plain.target.latitude));
      },
    );

    test('returns null when the viewport leaves no room', () {
      expect(boundsFitCamera(box, viewport: const Size(400, 40)), isNull);
      expect(boundsFitCamera(box, viewport: Size.zero), isNull);
    });
  });

  group('safeFitBounds', () {
    test('leaves a normal, well-ordered box intact', () {
      final result = safeFitBounds(
        LatLngBounds(
          southwest: const LatLng(21.9, 120.0),
          northeast: const LatLng(25.3, 122.0),
        ),
      )!;
      expect(result.southwest.latitude, closeTo(21.9, 1e-9));
      expect(result.southwest.longitude, closeTo(120.0, 1e-9));
      expect(result.northeast.latitude, closeTo(25.3, 1e-9));
      expect(result.northeast.longitude, closeTo(122.0, 1e-9));
    });

    test('widens a zero-span (point) box to the minimum span, centred', () {
      const point = LatLng(24.0, 121.0);
      final result = safeFitBounds(
        LatLngBounds(southwest: point, northeast: point),
      )!;
      expect(
        result.northeast.latitude - result.southwest.latitude,
        closeTo(0.02, 1e-9),
      );
      expect(
        result.northeast.longitude - result.southwest.longitude,
        closeTo(0.02, 1e-9),
      );
      expect(
        (result.southwest.latitude + result.northeast.latitude) / 2,
        closeTo(24.0, 1e-9),
      );
      expect(
        (result.southwest.longitude + result.northeast.longitude) / 2,
        closeTo(121.0, 1e-9),
      );
    });

    test('widens only the degenerate axis', () {
      // Zero latitude span, healthy longitude span.
      final result = safeFitBounds(
        LatLngBounds(
          southwest: const LatLng(24.0, 120.0),
          northeast: const LatLng(24.0, 121.0),
        ),
      )!;
      expect(
        result.northeast.latitude - result.southwest.latitude,
        closeTo(0.02, 1e-9),
      );
      expect(
        result.northeast.longitude - result.southwest.longitude,
        closeTo(1.0, 1e-9),
      );
    });

    // LatLngBounds itself asserts ordered latitudes, so an out-of-order or
    // non-finite corner can only reach the guard via longitude (unconstrained).
    test('orders an inverted-longitude box', () {
      final result = safeFitBounds(
        LatLngBounds(
          southwest: const LatLng(21.9, 122.0),
          northeast: const LatLng(25.3, 120.0),
        ),
      )!;
      expect(result.southwest.longitude, lessThan(result.northeast.longitude));
      expect(result.southwest.longitude, closeTo(120.0, 1e-9));
      expect(result.northeast.longitude, closeTo(122.0, 1e-9));
    });

    test('returns null when a corner longitude is non-finite', () {
      expect(
        safeFitBounds(
          LatLngBounds(
            southwest: LatLng(21.0, double.nan),
            northeast: const LatLng(25.0, 122.0),
          ),
        ),
        isNull,
      );
      expect(
        safeFitBounds(
          LatLngBounds(
            southwest: const LatLng(21.0, 120.0),
            northeast: LatLng(25.0, double.infinity),
          ),
        ),
        isNull,
      );
    });
  });
}
