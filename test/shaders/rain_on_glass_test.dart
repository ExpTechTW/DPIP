@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('rain-on-glass refracts its input', () async {
    const w = 360, h = 300;
    // Stand-in "card": text-like bars on a panel, so refraction is visible.
    final rec0 = ui.PictureRecorder();
    final c0 = ui.Canvas(rec0);
    c0.drawRect(
      const Rect.fromLTWH(0, 0, 360, 300),
      Paint()..color = const Color(0xFF2A3550),
    );
    c0.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 20, 320, 260),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFF19233A),
    );
    for (var i = 0; i < 7; i++) {
      c0.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(44, 48.0 + i * 32, 200 - (i % 3) * 40, 12),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFFBFD0E8),
      );
      c0.drawCircle(
        Offset(290, 54.0 + i * 32),
        10,
        Paint()..color = const Color(0xFF62D0C0),
      );
    }
    final content = rec0.endRecording().toImageSync(w, h);

    final prog = await ui.FragmentProgram.fromAsset(
      'shaders/weather/rain_on_glass.frag',
    );
    Future<ui.Image> render(double refraction, double time) async {
      final sh = prog.fragmentShader();
      var i = 0;
      void f(double v) => sh.setFloat(i++, v);
      f(w.toDouble());
      f(h.toDouble()); // engine normally sets this
      f(time);
      f(1.0);
      f(1.0);
      f(1.0); // static size/amount/speed
      f(1.0);
      f(1.0);
      f(1.0); // running size/amount/speed
      f(refraction);
      sh.setImageSampler(0, content);
      final r = ui.PictureRecorder();
      ui.Canvas(
        r,
      ).drawRect(const Rect.fromLTWH(0, 0, 360, 300), Paint()..shader = sh);
      return r.endRecording().toImageSync(w, h);
    }

    final off = await render(0.0, 6.0);
    final on = await render(1.0, 6.0);

    Future<List<int>> px(ui.Image im) async => (await im.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    final a = await px(off), b = await px(on);
    var diff = 0;
    for (var k = 0; k < a.length; k += 4) {
      if ((a[k] - b[k]).abs() > 6) diff++;
    }
    // ignore: avoid_print
    print('pixels displaced by refraction: $diff / ${a.length ~/ 4}');

    final rec = ui.PictureRecorder();
    final cv = ui.Canvas(rec);
    cv.drawImage(off, Offset.zero, Paint());
    cv.drawImage(on, const Offset(370, 0), Paint());
    final out = rec.endRecording().toImageSync(730, 300);
    final png = await out.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/sky_preview').createSync(recursive: true);
    File(
      'build/sky_preview/_rain_glass.png',
    ).writeAsBytesSync(png!.buffer.asUint8List());
    expect(
      diff,
      greaterThan(500),
      reason: 'refraction should displace content',
    );
  });
}
