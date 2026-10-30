import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the glass field is baked at 256 and its coverage is not empty',
    () async {
      expect(kRainOnGlassFieldEdge, 256);
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/weather/rain_on_glass.frag',
      );
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 1, 1),
        Paint()..color = const Color(0x00000000),
      );
      final dummy = recorder.endRecording().toImageSync(1, 1);
      final field = bakeRainOnGlassField(
        shader: program.fragmentShader(),
        dummy: dummy,
        time: 6,
        opacity: 1,
        staticSize: 1,
        staticAmount: 1,
        staticSpeed: 1,
        runningSize: 1,
        runningAmount: 1,
        runningSpeed: 1,
      );
      expect(field.width, kRainOnGlassFieldEdge);
      expect(field.height, kRainOnGlassFieldEdge);

      final bytes = await field.toByteData(format: ui.ImageByteFormat.rawRgba);
      final px = bytes!.buffer.asUint8List();
      var covered = 0;
      for (var i = 0; i < px.length; i += 4) {
        if (px[i] > 0) covered++;
      }
      expect(covered, greaterThan(0), reason: 'R is droplet coverage');
      field.dispose();
      dummy.dispose();
    },
  );
}
