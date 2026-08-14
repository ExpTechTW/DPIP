/// Raster-level pins for the moon shader.
///
/// `moon_display.frag` projects NASA's lunar maps onto a sphere and lights
/// them by phase. What must hold, or the whole "moon phase" feature lies:
/// dark at new, bright at full, right-lit at first quarter — the terminator
/// has to land where the phase angle puts it. On top of that, two things that
/// separate a sphere from a printed disc are pinned here because they are easy
/// to lose in a refactor: nothing is drawn outside the disc, and a full moon
/// stays bright out to the limb instead of falling off like a Lambert ball.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

const int _size = 128;

Future<ui.Image> _asset(String key) async {
  final data = await rootBundle.load(key);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

Future<ui.Image> _renderPhase(
  ui.Image color,
  ui.Image height,
  double phase,
) async {
  final program = await ui.FragmentProgram.fromAsset(
    'shaders/weather/moon_display.frag',
  );
  final shader = program.fragmentShader();
  shader.setFloat(0, _size.toDouble());
  shader.setFloat(1, _size.toDouble());
  shader.setFloat(2, phase);
  shader.setFloat(3, 0); // libration held at zero so the tests are stable
  shader.setFloat(4, 0);
  shader.setImageSampler(0, color);
  shader.setImageSampler(1, height);
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    Offset.zero & Size.square(_size.toDouble()),
    Paint()..shader = shader,
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(_size, _size);
  picture.dispose();
  shader.dispose();
  return image;
}

/// Mean luminance over a rectangle, ignoring fully transparent pixels.
Future<double> _luminance(
  ui.Image image, {
  double left = 0,
  double right = 1,
}) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = bytes!.buffer.asUint8List();
  var total = 0.0;
  var count = 0;
  final from = (left * _size).round();
  final to = (right * _size).round();
  for (var y = 0; y < _size; y++) {
    for (var x = from; x < to; x++) {
      final i = (y * _size + x) * 4;
      if (pixels[i + 3] == 0) continue;
      total += (pixels[i] + pixels[i + 1] + pixels[i + 2]) / 3;
      count++;
    }
  }
  return count == 0 ? 0 : total / count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ui.Image color;
  late ui.Image height;

  setUpAll(() async {
    color = await _asset('assets/astro/moon_color_2k.jpg');
    height = await _asset('assets/astro/moon_height_1k.png');
  });

  tearDownAll(() {
    color.dispose();
    height.dispose();
  });

  test('the bundled NASA maps are equirectangular (2:1)', () {
    expect(color.width, color.height * 2);
    expect(height.width, height.height * 2);
  });

  test('new moon is dark, full moon is bright', () async {
    final newMoon = await _renderPhase(color, height, 0);
    final full = await _renderPhase(color, height, 3.14159265);

    final dark = await _luminance(newMoon);
    final bright = await _luminance(full);
    expect(dark, lessThan(30), reason: 'new moon should be nearly unlit');
    expect(bright, greaterThan(90), reason: 'full moon should be bright');
    newMoon.dispose();
    full.dispose();
  });

  test('first quarter lights the right half', () async {
    final image = await _renderPhase(color, height, 3.14159265 / 2);
    final left = await _luminance(image, left: 0.05, right: 0.45);
    final right = await _luminance(image, left: 0.55, right: 0.95);

    expect(right, greaterThan(left * 3));
    image.dispose();
  });

  test('nothing is drawn outside the disc', () async {
    final image = await _renderPhase(color, height, 3.14159265);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = bytes!.buffer.asUint8List();
    // The corners are well outside an inscribed circle.
    for (final (x, y) in [(1, 1), (_size - 2, 1), (1, _size - 2)]) {
      expect(pixels[(y * _size + x) * 4 + 3], 0, reason: 'corner ($x,$y)');
    }
    image.dispose();
  });

  test('a full moon stays bright to the limb', () async {
    // Lunar regolith backscatters: the real full Moon is famously flat, not a
    // shaded ball. A Lambert sphere would fall off toward the edge — this pins
    // the Lommel-Seeliger term that prevents exactly that.
    final image = await _renderPhase(color, height, 3.14159265);
    final centre = await _luminance(image, left: 0.42, right: 0.58);
    final edge = await _luminance(image, left: 0.02, right: 0.14);

    expect(edge, greaterThan(centre * 0.5));
    image.dispose();
  });
}
