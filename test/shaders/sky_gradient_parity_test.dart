import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe_data.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_lut_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The CPU-baked sky gradient (`SkyLutCache._bakeSkyGradient`) must reproduce
/// what the `sky_view.frag` screen pass drew, within the shader's own
/// sub-texel dither.
///
/// The gradient samples 1024 rows with the shader's exact frustum → elevation
/// → LUT-v mapping. The reference is rasterised at 4×2048 so its odd rows
/// align with the gradient's rows; every channel is compared against the
/// reference with the dither's worst-case half-row shift allowed for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('baked sky gradient matches the sky_view reference pass', () async {
    final trans = await ui.FragmentProgram.fromAsset(
      'shaders/sky/transmittance.frag',
    );
    final lut = await ui.FragmentProgram.fromAsset('shaders/sky/sky_lut.frag');
    final view = await ui.FragmentProgram.fromAsset(
      'shaders/sky/sky_view.frag',
    );

    final cache = SkyLutCache(trans.fragmentShader(), lut.fragmentShader());
    final sky = resolveSky(sunnyKeyframes, position: 8, humidity: 0.6);
    expect(cache.update(sky), isTrue);

    // The readback is async — poll for the baked gradient.
    final stopwatch = Stopwatch()..start();
    ui.Image? gradient;
    while (stopwatch.elapsed < const Duration(seconds: 2)) {
      gradient = cache.skyGradient;
      if (gradient != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(gradient, isNotNull, reason: 'LUT readback never completed');

    const width = 4;
    const rows = 1024;
    final fr = buildFrustum(sky.cameraYaw);
    final s = view.fragmentShader();
    var i = 0;
    void set(double v) => s.setFloat(i++, v);
    set(width.toDouble());
    set((rows * 2).toDouble());
    set(fr.top[0]);
    set(fr.top[1]);
    set(fr.top[2]);
    set(fr.bottom[0]);
    set(fr.bottom[1]);
    set(fr.bottom[2]);
    set(sky.sunAngleY);
    set(4.0); // time — a fixed dither scroll
    set(SkyConstants.skyLutWidth.toDouble());
    set(SkyConstants.skyLutHeight.toDouble());
    s.setImageSampler(0, cache.skyView!);

    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), (rows * 2).toDouble()),
      Paint()..shader = s,
    );
    final reference = recorder.endRecording().toImageSync(width, rows * 2);

    final gradBytes = (await gradient!.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    final refBytes = (await reference.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();

    var maxDiff = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < width; c++) {
        final go = (r * width + c) * 4;
        final ro = ((r * 2 + 1) * width + c) * 4;
        for (var ch = 0; ch < 3; ch++) {
          final d = (gradBytes[go + ch] - refBytes[ro + ch]).abs();
          if (d > maxDiff) maxDiff = d;
        }
      }
    }

    // Worst case the dither shifts lutV by ±0.26 of a LUT row (sub-texel by
    // design); allow that plus a small margin for the piecewise-linear ramp.
    expect(
      maxDiff,
      lessThanOrEqualTo(3),
      reason: 'gradient diverged from the sky_view pass (maxDiff=$maxDiff)',
    );
  });
}
