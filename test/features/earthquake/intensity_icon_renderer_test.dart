/// The locally rendered intensity markers must keep the legacy geometry: a
/// full-bleed shell (white, or black in dark mode), an inner rounded square in
/// the discrete intensity colour, and the level digit (black on the yellow /
/// orange badges 4–5, white elsewhere). `cross` is the red × station marker.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/features/earthquake/presentation/widgets/intensity_icon_renderer.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ui.Image> decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  (int, int, int, int) px(ui.Image image, ByteData raw, int x, int y) {
    final i = (y * image.width + x) * 4;
    return (
      raw.getUint8(i),
      raw.getUint8(i + 1),
      raw.getUint8(i + 2),
      raw.getUint8(i + 3),
    );
  }

  test('badges keep the legacy geometry', () async {
    final icons = await IntensityIconRenderer.renderAll();
    final white = const Color(0xFFFFFFFF).toARGB32();
    final black = const Color(0xFF000000).toARGB32();
    for (final name in IntensityIconRenderer.names) {
      final image = await decode(icons[name]!);
      final raw = (await image.toByteData())!;
      if (name == 'cross') {
        expect(image.width, 96, reason: name);
        final centre = px(image, raw, 48, 48);
        expect(
          centre.$1 > 150 && centre.$2 < 120,
          isTrue,
          reason: 'cross centre should be red',
        );
        // Rounded corners stay transparent.
        expect(px(image, raw, 0, 0).$4, lessThan(32), reason: 'cross corner');
        continue;
      }
      expect(image.width, 64, reason: name);
      final level = int.parse(name.split('-')[1]);
      final dark = name.endsWith('-dark');
      final shell = dark ? black : white;
      final badge = IntensityColors.discrete(level).toARGB32();
      final digit = ((level == 4 || level == 5) ? black : white) & 0xFFFFFF;

      // Shell rim, badge fill, digit, and a transparent rounded corner.
      final rim = px(image, raw, 2, 32);
      expect(rim.$4 > 200, isTrue, reason: '$name rim opaque');
      expect(
        (rim.$1 << 16) | (rim.$2 << 8) | rim.$3,
        shell & 0xFFFFFF,
        reason: '$name rim colour',
      );
      final fill = px(image, raw, 10, 32);
      expect(
        (fill.$1 << 16) | (fill.$2 << 8) | fill.$3,
        badge & 0xFFFFFF,
        reason: '$name badge colour',
      );
      final d = px(image, raw, 32, 32);
      expect(
        (d.$1 << 16) | (d.$2 << 8) | d.$3,
        digit,
        reason: '$name digit colour',
      );
      expect(px(image, raw, 0, 0).$4, lessThan(32), reason: '$name corner');
    }
  });
}
