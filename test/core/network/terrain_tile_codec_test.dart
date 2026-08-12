import 'dart:typed_data';

import 'package:dpip/core/network/terrain_tile_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Builds a Mapbox.com terrain-RGB PNG from [heights] (row-major metres).
/// Encoding: `num = (h + 10000) * 10`, stored as R·65536 + G·256 + B.
Uint8List _mapboxComPng(List<double> heights) {
  final width = 4;
  final image = img.Image(width: width, height: heights.length ~/ width);
  for (var i = 0; i < heights.length; i++) {
    final num = ((heights[i] + 10000) * 10).round();
    final x = i % width;
    final y = i ~/ width;
    image.setPixelRgb(x, y, (num >> 16) & 0xFF, (num >> 8) & 0xFF, num & 0xFF);
  }
  return Uint8List.fromList(img.encodePng(image));
}

double _decodeTerrarium(Uint8List png, int x, int y) {
  final image = img.decodePng(png)!;
  final pixel = image.getPixel(x, y);
  return pixel.r.toDouble() * 256 + pixel.g - 32768;
}

void main() {
  test('isTerrainPng matches the terrain endpoint only', () {
    expect(
      isTerrainPng(
        Uri.parse(
          'https://static.lb.exptech.dev/api/v1/map/terrain/7/107/55.png',
        ),
      ),
      isTrue,
    );
    expect(
      isTerrainPng(
        Uri.parse(
          'https://static.lb.exptech.dev/api/v1/map/tiles/7/107/55.pbf',
        ),
      ),
      isFalse,
      reason: 'basemap vector tiles are not DEM data',
    );
    expect(
      isTerrainPng(
        Uri.parse(
          'https://static.core-tnn1.exptech.dev/api/v2/tiles/radar/0/1/1.webp',
        ),
      ),
      isFalse,
    );
  });

  test(
    'a Mapbox.com terrain-RGB PNG converts to terrarium with height preserved',
    () {
      const heights = [-100.0, 0.0, 500.5, 3952.0];
      final converted = ensureTerrarium(_mapboxComPng(heights));

      expect(converted, isNotNull, reason: 'raw terrain-RGB must be rewritten');
      for (var i = 0; i < heights.length; i++) {
        final got = _decodeTerrarium(converted!, i % 4, i ~/ 4);
        // Terrarium is 16-bit (1 m steps) against the source's 0.1 m — a
        // half-metre rounding is the encoding's floor, not a bug.
        expect(got, closeTo(heights[i], 1.0), reason: 'pixel $i');
      }
    },
  );

  test('an already-terrarium PNG is left untouched (null)', () {
    final once = ensureTerrarium(_mapboxComPng(const [0, 100, 1000, 3000]))!;
    expect(
      ensureTerrarium(once),
      isNull,
      reason: 'converted bytes must not re-encode',
    );
  });
}
