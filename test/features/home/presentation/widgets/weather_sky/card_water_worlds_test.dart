/// Same-time picture of a storm card with both water worlds and with only
/// the slow one. The two heavy presets are different on purpose; this is the
/// check that decides whether one solver can feed both.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/card_water_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('storm worlds at the same time', () async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/weather/card_water.frag',
    );
    final shader = program.fragmentShader();
    addTearDown(shader.dispose);
    final sprites = buildParticleSprites();
    addTearDown(() {
      sprites.$1.dispose();
      sprites.$2.dispose();
    });

    const width = 360.0;
    const cardHeight = 140.0;
    const screen = Size(411, 731);
    const seconds = 2.0;

    final both = _render(
      shader,
      _stepped(
        sprites,
        seconds,
        primary: CardWaterPreset.heavy,
        secondary: CardWaterPreset.heavySecondary,
      ),
      width,
      cardHeight,
      screen,
    );
    final primaryOnly = _render(
      shader,
      _stepped(sprites, seconds, primary: CardWaterPreset.heavy),
      width,
      cardHeight,
      screen,
    );

    final a = (await both.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    final b = (await primaryOnly.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    var max = 0;
    var sum = 0;
    var samples = 0;
    var changed = 0;
    for (var i = 0; i < a.length; i += 4) {
      final dr = (a[i] - b[i]).abs();
      final dg = (a[i + 1] - b[i + 1]).abs();
      final db = (a[i + 2] - b[i + 2]).abs();
      final d = dr > dg ? (dr > db ? dr : db) : (dg > db ? dg : db);
      if (d > max) max = d;
      if (d > 24) changed++;
      sum += dr + dg + db;
      samples++;
    }
    final mean = sum / (samples * 3);
    final fraction = changed / samples;

    final dir = Directory('build/bench/card-water')
      ..createSync(recursive: true);
    await _png(both, '${dir.path}/storm-both.png');
    await _png(primaryOnly, '${dir.path}/storm-primary.png');
    both.dispose();
    primaryOnly.dispose();
    File('${dir.path}/storm.json').writeAsStringSync(
      '{"max":$max,"mean":${mean.toStringAsFixed(3)},'
      '"changedFraction":${fraction.toStringAsFixed(4)}}\n',
    );

    // The fast world is a second grade, not a copy. A max under a
    // just-noticeable step would mean one solver could feed both.
    expect(max, greaterThan(24));
  });
}

({CardWaterField primary, CardWaterField? secondary}) _stepped(
  (ui.Image, ui.Image) sprites,
  double seconds, {
  required CardWaterPreset primary,
  CardWaterPreset? secondary,
}) {
  final first = CardWaterField(spritePos: sprites.$1, spriteNeg: sprites.$2);
  final second = secondary == null
      ? null
      : CardWaterField(spritePos: sprites.$1, spriteNeg: sprites.$2, seed: 23);
  const width = 360.0;
  const screenHeight = 731.0;
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    first.update(
      1 / 60,
      width: width,
      screenHeight: screenHeight,
      intensity: 0.85,
      preset: primary,
    );
    second?.update(
      1 / 60,
      width: width,
      screenHeight: screenHeight,
      intensity: 0.85,
      preset: secondary!,
    );
  }
  return (primary: first, secondary: second);
}

ui.Image _render(
  ui.FragmentShader shader,
  ({CardWaterField primary, CardWaterField? secondary}) fields,
  double width,
  double cardHeight,
  Size screen,
) {
  const pointSize = 5.0;
  const threshold = 0.6;
  final headroom = CardWaterField.spawnHeadroom(screen.height);
  final full = Size(width, cardHeight + headroom);
  final raster = CardWaterField.accumulationSize(full);
  // The card's own blur, in the half-resolution accumulation's pixels.
  const blurStepUv = 1 / 355;
  const blurSigmaUv = 0.46253 * blurStepUv;
  final scale = CardWaterField.accumulationResolution;
  final blur = Paint()
    ..imageFilter = ui.ImageFilter.blur(
      sigmaX: blurSigmaUv * screen.width * scale,
      sigmaY: blurSigmaUv * screen.height * scale,
    );

  ui.Image pass(bool negative) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..saveLayer(Offset.zero & raster, blur)
      ..scale(scale)
      ..translate(0, headroom);
    fields.primary.paintCoverage(
      canvas,
      dropSize: pointSize,
      negative: negative,
    );
    fields.secondary?.paintCoverage(
      canvas,
      dropSize: pointSize,
      negative: negative,
    );
    canvas.restore();
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      raster.width.ceil(),
      raster.height.ceil(),
    );
    picture.dispose();
    return image;
  }

  final pos = pass(false);
  final neg = pass(true);
  final atlas = _packFieldAtlas(pos, neg);
  const hour = 12.0;
  const ambient = [0.25, 0.32, 0.42];
  final halfWidth = pos.width.toDouble();
  final atlasWidth = atlas.width.toDouble();
  var i = 0;
  void set(double v) => shader.setFloat(i++, v);
  set(halfWidth);
  set(pos.height.toDouble());
  set(ambient[0]);
  set(ambient[1]);
  set(ambient[2]);
  set(1.0);
  set(threshold * CardWaterField.accumulationScale);
  set(1.0);
  set(hour);
  set(halfWidth / atlasWidth);
  set((halfWidth + _fieldGutter) / atlasWidth);
  shader.setImageSampler(0, atlas);

  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Offset.zero & Size(pos.width.toDouble(), pos.height.toDouble()),
    Paint()..shader = shader,
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(pos.width, pos.height);
  picture.dispose();
  atlas.dispose();
  pos.dispose();
  neg.dispose();
  return image;
}

/// Blank columns between the halves, so a bilinear tap on one cannot read
/// the other. Matches the gap the card records.
const int _fieldGutter = 4;

ui.Image _packFieldAtlas(ui.Image pos, ui.Image neg) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..filterQuality = FilterQuality.none;
  canvas.drawImage(pos, Offset.zero, paint);
  canvas.drawImage(
    neg,
    Offset((pos.width + _fieldGutter).toDouble(), 0),
    paint,
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(pos.width * 2 + _fieldGutter, pos.height);
  picture.dispose();
  return image;
}

Future<void> _png(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}
