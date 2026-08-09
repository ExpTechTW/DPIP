@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/card_water_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the card-edge water over a synthetic card + sky so the pipeline can
/// be *looked at* and *measured* — `flutter test --run-skipped --tags preview`,
/// then open `build/card_water_preview/`.
///
/// The measurement is the point. The reference's own edge, sampled over 338 frames of a
/// 弱い雨 capture, wets **4.5 % of the card's top-edge columns** in about two
/// discrete clusters — droplets caught on the lip, not a continuous band. This
/// harness reports the same statistic so the port can be compared against that
/// number instead of against an impression.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A phone, in logical pixels: everything the engine sizes is a fraction of
  // the screen, so measuring at a real device size is the only way the numbers
  // mean anything.
  const screen = Size(402, 874);
  const width = 360.0;
  const cardHeight = 100.0;
  const threshold = 0.6;

  // The reference: 5 px drops on a tall screen, in the 800-tall buffer's pixels.
  final pointSize = 5.0 * screen.height / CardWaterField.bufferHeight;
  // The reference: a flat 1/355 **UV** step on both axes, which is anisotropic
  // in pixels because the buffer is not square.
  const sigmaUv = 0.46253 / 355;
  final sigmaX = sigmaUv * screen.width;
  final sigmaY = sigmaUv * screen.height;

  Future<({double coverage, int clusters, int live})> render({
    required String name,
    required double seconds,
    required CardWaterPreset preset,
    required CardWaterPreset secondaryPreset,
    required Color sky,
    required Color card,
    required Color ambient,
    required double specular,
  }) async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/weather/card_water.frag',
    );
    final shader = program.fragmentShader();
    final sprites = buildParticleSprites();
    final a = CardWaterField(spritePos: sprites.$1, spriteNeg: sprites.$2);
    final b = CardWaterField(
      spritePos: sprites.$1,
      spriteNeg: sprites.$2,
      seed: 23,
    );
    for (var t = 0.0; t < seconds; t += 1 / 60) {
      a.update(
        1 / 60,
        width: width,
        screenHeight: screen.height,
        intensity: 1,
        preset: preset,
      );
      b.update(
        1 / 60,
        width: width,
        screenHeight: screen.height,
        intensity: 1,
        preset: secondaryPreset,
      );
    }

    final headroom = CardWaterField.spawnHeadroom(screen.height);
    final fieldSize = Size(width, cardHeight + headroom);

    ui.Image accumulate({required bool negative}) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..saveLayer(
          Offset.zero & fieldSize,
          Paint()
            ..imageFilter = ui.ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        )
        ..translate(0, headroom);
      a.paintCoverage(canvas, dropSize: pointSize, negative: negative);
      b.paintCoverage(canvas, dropSize: pointSize, negative: negative);
      canvas.restore();
      return recorder.endRecording().toImageSync(
        fieldSize.width.ceil(),
        fieldSize.height.ceil(),
      );
    }

    final pos = accumulate(negative: false);
    final neg = accumulate(negative: true);

    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    set(fieldSize.width);
    set(fieldSize.height);
    set(ambient.r);
    set(ambient.g);
    set(ambient.b);
    set(specular);
    set(threshold * CardWaterField.accumulationScale);
    set(1.0);
    set(14.0);
    shader.setImageSampler(0, pos);
    shader.setImageSampler(1, neg);

    // Compose the scene: sky, card, then the water overlay — the exact
    // layering RainOnCard produces.
    final scene = ui.PictureRecorder();
    final canvas = Canvas(scene);
    canvas.scale(3); // inspect at 3x
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, fieldSize.height),
      Paint()..color = sky,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, headroom, width, cardHeight),
        const Radius.circular(12),
      ),
      Paint()..color = card,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, fieldSize.width, fieldSize.height),
      Paint()..shader = shader,
    );
    final image = scene.endRecording().toImageSync(
      (width * 3).ceil(),
      (fieldSize.height * 3).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/card_water_preview')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());

    // Measure the edge the way the reference capture was measured: over a band a
    // few drops tall straddling the card's top lip, a column counts as wet if
    // any pixel in it rises clearly above the dry card.
    final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final px = raw!.buffer.asUint8List();
    final w = (width * 3).ceil();
    final bandTop = ((headroom - 3 * pointSize) * 3).round();
    final bandBottom = ((headroom + 3 * pointSize) * 3).round();
    final dry = _luma(card);
    var wet = 0;
    var clusters = 0;
    var run = false;
    for (var x = 0; x < w; x++) {
      var isWet = false;
      for (var y = bandTop; y < bandBottom; y++) {
        final o = (y * w + x) * 4;
        if ((_lumaOf(px[o], px[o + 1], px[o + 2]) - dry).abs() > 20) {
          isWet = true;
          break;
        }
      }
      if (isWet) {
        wet++;
        if (!run) clusters++;
        run = true;
      } else {
        run = false;
      }
    }
    image.dispose();
    pos.dispose();
    neg.dispose();
    return (
      coverage: wet / w,
      clusters: clusters,
      live: a.liveCount + b.liveCount,
    );
  }

  test('render card water previews', () async {
    // Day rain: grey-blue sky, light glass card.
    for (final scene
        in <
          ({
            String name,
            double seconds,
            CardWaterPreset preset,
            CardWaterPreset secondary,
            Color sky,
            Color card,
            Color ambient,
            double specular,
          })
        >[
          (
            name: 'day_light_2s',
            seconds: 2.0,
            preset: CardWaterPreset.light,
            secondary: CardWaterPreset.light,
            sky: const Color(0xFF8FA3B8),
            // The reference's card is a 20 % pane of the sky, so the water is lit by
            // nearly the same colour it lands on — which is most of why its
            // edge reads as a faint disturbance rather than a bright band.
            card: const Color(0x338FA3B8),
            ambient: const Color(0xFF5C6B7E),
            specular: 1.0,
          ),
          (
            name: 'day_heavy_2s',
            seconds: 2.0,
            preset: CardWaterPreset.heavy,
            secondary: CardWaterPreset.heavySecondary,
            sky: const Color(0xFF77808C),
            card: const Color(0x3377808C),
            ambient: const Color(0xFF525E6D),
            specular: 1.0,
          ),
          (
            name: 'night_light_2s',
            seconds: 2.0,
            preset: CardWaterPreset.light,
            secondary: CardWaterPreset.light,
            sky: const Color(0xFF10151E),
            card: const Color(0x3310151E),
            ambient: const Color(0xFF161C26),
            specular: 1.2,
          ),
        ]) {
      final m = await render(
        name: scene.name,
        seconds: scene.seconds,
        preset: scene.preset,
        secondaryPreset: scene.secondary,
        sky: scene.sky,
        card: scene.card,
        ambient: scene.ambient,
        specular: scene.specular,
      );
      // ignore: avoid_print
      print(
        '${scene.name}: edge coverage ${(m.coverage * 100).toStringAsFixed(2)}%'
        ' (the reference 4.5%), clusters ${m.clusters} (the reference ~2), live ${m.live}',
      );
    }
  });
}

double _luma(Color c) =>
    _lumaOf((c.r * 255).round(), (c.g * 255).round(), (c.b * 255).round());

double _lumaOf(int r, int g, int b) => 0.299 * r + 0.587 * g + 0.114 * b;
