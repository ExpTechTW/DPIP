/// The locally rendered circular badges must keep the same geometry as the
/// square report badge, just circular: a full-bleed shell (white, or black in
/// dark mode), an inner filled circle in the discrete intensity colour, and
/// the level label — `1`…`4`, then `5⁻`/`5⁺`/`6⁻`/`6⁺`/`7`, coloured via
/// [IntensityColors.onDiscrete] for contrast.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/shared/seismic/intensity_circle_renderer.dart';
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

  test(
    'circular badges keep the report badge geometry, minus the corners',
    () async {
      final icons = await IntensityCircleRenderer.renderAll();
      final white = const Color(0xFFFFFFFF).toARGB32();
      final black = const Color(0xFF000000).toARGB32();
      for (final name in IntensityCircleRenderer.names) {
        final image = await decode(icons[name]!);
        final raw = (await image.toByteData())!;
        expect(image.width, 64, reason: name);
        final level = int.parse(name.split('-')[1]);
        final dark = name.endsWith('-dark');
        final shell = dark ? black : white;
        final badge = IntensityColors.discrete(level).toARGB32();
        final badgeRgb = badge & 0xFFFFFF;

        // Shell rim, badge fill, digit, and — unlike the square, whose corners
        // are just gently rounded — a fully transparent corner outside the
        // circle entirely.
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
          badgeRgb,
          reason: '$name badge colour',
        );
        // The label's ink ([IntensityColors.onDiscrete]) isn't always fully
        // opaque (`Colors.black87`), so it composites to some blend of ink and
        // fill rather than a single exact colour — just confirm *something*
        // was actually painted near the centre, distinct from the plain fill.
        var foundDigit = false;
        for (var dx = -6; dx <= 6 && !foundDigit; dx++) {
          for (var dy = -6; dy <= 6 && !foundDigit; dy++) {
            final d = px(image, raw, 32 + dx, 32 + dy);
            final rgb = (d.$1 << 16) | (d.$2 << 8) | d.$3;
            final diff =
                (((rgb >> 16) & 0xFF) - ((badgeRgb >> 16) & 0xFF)).abs() +
                (((rgb >> 8) & 0xFF) - ((badgeRgb >> 8) & 0xFF)).abs() +
                ((rgb & 0xFF) - (badgeRgb & 0xFF)).abs();
            if (diff > 60) foundDigit = true;
          }
        }
        expect(foundDigit, isTrue, reason: '$name digit painted');
        expect(
          px(image, raw, 0, 0).$4,
          0,
          reason: '$name corner (outside the circle)',
        );
      }
    },
  );
}
