import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/card_water_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> _decodeAsset(String key) async {
  final data = await rootBundle.load(key);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

/// End-to-end pin on the panel-water pipeline, adversarially verified: the
/// GPU shader's output is compared per-pixel against an independent float
/// re-implementation of the reference shader's rain branch running on the same
/// accumulation buffers. A wrong uniform, a broken channel packing, or a
/// regression in the self-lit ambient shows up as a numeric divergence here —
/// not as a surprise on a device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const width = 360.0;
  const cardHeight = 120.0;
  const screenHeight = 800.0;
  const pointSize = 5.0;
  const threshold = 0.6;

  ui.Image accumulate(
    CardWaterField field,
    Size fieldSize,
    double headroom, {
    required bool negative,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..saveLayer(
        Offset.zero & fieldSize,
        Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 0.46, sigmaY: 0.46),
      )
      ..translate(0, headroom);
    field.paintCoverage(canvas, dropSize: pointSize, negative: negative);
    canvas.restore();
    return recorder.endRecording().toImageSync(
      fieldSize.width.ceil(),
      fieldSize.height.ceil(),
    );
  }

  test('the shader matches a float reference of screen.glsl', () async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/weather/card_water.frag',
    );
    final shader = program.fragmentShader();

    final sprites = buildParticleSprites();
    final field = CardWaterField(spritePos: sprites.$1, spriteNeg: sprites.$2);
    for (var t = 0.0; t < 1.5; t += 1 / 60) {
      field.update(
        1 / 60,
        width: width,
        screenHeight: screenHeight,
        intensity: 1,
        preset: CardWaterPreset.heavy,
      );
    }
    expect(field.liveCount, greaterThan(10));

    final headroom = CardWaterField.spawnHeadroom(screenHeight);
    final fieldSize = Size(width, cardHeight + headroom);
    final pos = accumulate(field, fieldSize, headroom, negative: false);
    final neg = accumulate(field, fieldSize, headroom, negative: true);
    // The composite reads one atlas. The copies stay pixel-identical to the
    // buffers the float reference reads below.
    final atlas = _packFieldAtlas(pos, neg);

    const scale = CardWaterField.accumulationScale;
    const hour = 14.0;
    // A rainy sky sample — what the LUT publishes during rain.
    const ambient = [0.36, 0.42, 0.49];
    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    set(fieldSize.width);
    set(fieldSize.height);
    set(ambient[0]);
    set(ambient[1]);
    set(ambient[2]);
    set(1.0); // specular (day)
    set(threshold * scale);
    set(1.0); // scene alpha
    set(hour);
    final atlasWidth = atlas.width.toDouble();
    set(pos.width / atlasWidth);
    set((pos.width + _fieldGutter) / atlasWidth);
    shader.setImageSampler(0, atlas);

    final out = ui.PictureRecorder();
    ui.Canvas(out).drawRect(Offset.zero & fieldSize, Paint()..shader = shader);
    final image = out.endRecording().toImageSync(
      fieldSize.width.ceil(),
      fieldSize.height.ceil(),
    );

    // rawRgba is premultiplied — the stored channel values, no division.
    final outPx = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    final posPx = (await pos.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    final negPx = (await neg.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();

    // Float reference — the reference shader's rain branch with the self-aliased
    // ambient, evaluated at texel centres where the shader's bilinear
    // degenerates to the texel itself.
    const sunColor = [0.59, 0.55, 0.61];
    final timePer = _smoothstep(0, 12, hour) - _smoothstep(12, 23, hour);
    var light = [_lerp(-0.2, 0.0, timePer), _lerp(0.4, 1.0, timePer), 0.2];
    if (hour >= 12.0) light = [-light[0], light[1], light[2]];
    final lightLen = math.sqrt(
      light[0] * light[0] + light[1] * light[1] + light[2] * light[2],
    );
    final halfV = [
      light[0] / lightLen,
      light[1] / lightLen,
      light[2] / lightLen + 1.0,
    ];
    final halfLen = math.sqrt(
      halfV[0] * halfV[0] + halfV[1] * halfV[1] + halfV[2] * halfV[2],
    );

    final w = fieldSize.width.ceil();
    final h = fieldSize.height.ceil();
    var water = 0;
    var interior = 0;
    var blueDominant = 0;
    var greyish = 0;
    var worst = 0.0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final o = (y * w + x) * 4;
        final coverage = negPx[o + 2] / 255.0;
        if (coverage <= threshold * scale) {
          expect(outPx[o + 3], 0, reason: 'water outside the cut at $x,$y');
          continue;
        }
        water++;

        final sum = [
          (posPx[o] - negPx[o]) / 255.0,
          (posPx[o + 1] - negPx[o + 1]) / 255.0,
          posPx[o + 2] / 255.0,
        ];
        final len = math.sqrt(
          sum[0] * sum[0] + sum[1] * sum[1] + sum[2] * sum[2],
        );
        if (len < 1e-4) continue;
        final normal = [sum[0] / len, sum[1] / len, sum[2] / len];
        final spec = math
            .pow(
              math.max(
                normal[0] * halfV[0] / halfLen +
                    normal[1] * halfV[1] / halfLen +
                    normal[2] * halfV[2] / halfLen,
                0.0,
              ),
              10.0,
            )
            .toDouble();

        final expected = List.generate(3, (c) {
          final color = (ambient[c] * 1.3 + spec * sunColor[c]).clamp(0.0, 1.0);
          return (color * 0.6 * 255).round();
        });

        var diff = 0;
        for (var c = 0; c < 3; c++) {
          diff = math.max(diff, (outPx[o + c] - expected[c]).abs());
        }
        worst = math.max(worst, diff.toDouble());

        // The look pins: the water is a brightened *sky tint* — it keeps the
        // sky's blue lean everywhere, and it must never clamp to white the
        // way the normal-sum ambient provably did.
        final r = outPx[o];
        final g = outPx[o + 1];
        final b = outPx[o + 2];
        // "Pooled" is 1.3x the cut, not 2x. An isolated the reference drop peaks at
        // only 1.2x the cut (0.180 against 0.1506) — the depth the composite
        // is asked to light comes from *overlap*, and a 2x bar was only ever
        // reachable while a blend bug saturated the buffer.
        if (coverage > 1.3 * threshold * scale) {
          interior++;
          if (b > r) blueDominant++;
        }
        if (r > 140 && (r - g).abs() < 12 && (g - b).abs() < 12) greyish++;
      }
    }

    expect(water, greaterThan(50), reason: 'no water survived the threshold');
    expect(
      worst,
      lessThanOrEqualTo(18),
      reason: 'shader diverged from the float reference of screen.glsl',
    );
    expect(interior, greaterThan(20), reason: 'no pooled interior formed');
    expect(blueDominant, greaterThan((interior * 0.85).floor()));
    // A specular highlight is *meant* to be bright and near-neutral, so this
    // cannot be a tight bound — it is a guard against the failure it names,
    // where a bad ambient clamped the whole surface to (1,1,1) and every water
    // pixel went grey. One eighth still catches that by a wide margin; the
    // pool's colour is pinned by the blue-dominance check above.
    expect(
      greyish,
      lessThan(water ~/ 8 + 1),
      reason: 'the water went white-grey again',
    );
  });

  test(
    'pre-blurred sprites match a saveLayer blur of the same drops',
    () async {
      // The card's blur for this 360×800 screen, in half-resolution
      // accumulation pixels: σ = 0.46253/355 UV · screen · raster scale.
      const screen = Size(width, screenHeight);
      const blurStepUv = 1 / 355;
      const blurSigmaUv = 0.46253 * blurStepUv;
      const rasterScale = CardWaterField.accumulationResolution;
      final sigmaX = blurSigmaUv * screen.width * rasterScale;
      final sigmaY = blurSigmaUv * screen.height * rasterScale;

      final sprites = buildParticleSprites();
      final field = CardWaterField(
        spritePos: sprites.$1,
        spriteNeg: sprites.$2,
      );
      for (var t = 0.0; t < 1.5; t += 1 / 60) {
        field.update(
          1 / 60,
          width: width,
          screenHeight: screenHeight,
          intensity: 1,
          preset: CardWaterPreset.heavy,
        );
      }
      expect(field.liveCount, greaterThan(10));

      final headroom = CardWaterField.spawnHeadroom(screenHeight);
      final raster = CardWaterField.accumulationSize(
        Size(width, cardHeight + headroom),
      );
      final blur = Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY);

      ui.Image? oldPos;
      ui.Image? oldNeg;
      ui.Image? newPos;
      ui.Image? newNeg;
      ui.Image? blurredPos;
      ui.Image? blurredNeg;
      try {
        oldPos = _drawCoverage(
          field,
          raster,
          headroom,
          pointSize,
          negative: false,
          blur: blur,
        );
        oldNeg = _drawCoverage(
          field,
          raster,
          headroom,
          pointSize,
          negative: true,
          blur: blur,
        );

        // Sprite-pixel width of the discrete kernel, not the nominal sigma.
        final spriteW = sprites.$1.width.toDouble();
        final perSprite = (pointSize / spriteW) * rasterScale;
        final sx = _effectiveSigma(sigmaX) / perSprite;
        final sy = _effectiveSigma(sigmaY) / perSprite;
        final margin = (3 * math.max(sx, sy)).ceil() + 1;
        blurredPos = blurParticleSprite(sprites.$1, sx, sy, margin);
        blurredNeg = blurParticleSprite(sprites.$2, sx, sy, margin);
        field
          ..spritePos = blurredPos
          ..spriteNeg = blurredNeg
          ..spriteMargin = margin.toDouble();

        newPos = _drawCoverage(
          field,
          raster,
          headroom,
          pointSize,
          negative: false,
        );
        newNeg = _drawCoverage(
          field,
          raster,
          headroom,
          pointSize,
          negative: true,
        );

        final oldPosPx = (await oldPos.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final newPosPx = (await newPos.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final oldNegPx = (await oldNeg.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final newNegPx = (await newNeg.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        expect(oldPosPx.length, newPosPx.length);
        expect(oldNegPx.length, newNegPx.length);

        final pooled = _RgbDiff()
          ..add(oldPosPx, newPosPx)
          ..add(oldNegPx, newNegPx);
        final cut = threshold * CardWaterField.accumulationScale;
        final newCut = cut * CardWaterField.blurredSpriteCutScale;
        final (inter, union, oldArea, newArea) = _coverageIou(
          oldNegPx,
          newNegPx,
          cut,
          newCut,
        );
        final iou = union == 0 ? 0.0 : inter / union;
        final detail =
            'mean |ΔRGB| r=${pooled.r} g=${pooled.g} b=${pooled.b} '
            'iou=$iou ($inter/$union) area $newArea vs $oldArea';

        const limit = 4 / 255;
        expect(pooled.r, lessThanOrEqualTo(limit), reason: detail);
        expect(pooled.g, lessThanOrEqualTo(limit), reason: detail);
        expect(pooled.b, lessThanOrEqualTo(limit), reason: detail);
        // The drops are a few pixels across, so one pixel of edge is a large
        // part of the union; the area is what the eye reads as drop size.
        expect(iou, greaterThanOrEqualTo(0.85), reason: detail);
        expect(newArea / oldArea, inInclusiveRange(0.9, 1.1), reason: detail);
      } finally {
        oldPos?.dispose();
        oldNeg?.dispose();
        newPos?.dispose();
        newNeg?.dispose();
        blurredPos?.dispose();
        blurredNeg?.dispose();
        sprites.$1.dispose();
        sprites.$2.dispose();
      }
    },
  );

  test(
    'the sprites baked from the shipped particle textures decode correctly',
    () async {
      final kernel = await _decodeAsset(
        'assets/weather/particles/particle_blurred.webp',
      );
      final normalMap = await _decodeAsset(
        'assets/weather/particles/drop_normal.webp',
      );
      // Both come from `tool/gen/particle_sprites.py`: a 64×64 blurred disc and
      // a 128×128 analytic hemisphere. The numbers below are properties of
      // those two functions, so they hold for the generator's output as they
      // did for the textures it replaced.
      expect((kernel.width, kernel.height), (64, 64));
      expect((normalMap.width, normalMap.height), (128, 128));

      final (pos, neg) = await bakeParticleSprites(
        kernel: kernel,
        normalMap: normalMap,
      );
      final posPx = (await pos.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final negPx = (await neg.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      int at(Uint8List px, int x, int y, int c) => px[(y * 64 + x) * 4 + c];

      const c = 32;
      // Centre: straight-up normal — both signed halves of x are ≈ 0, z ≈ 1,
      // and the coverage in neg.b is the kernel's 0.784.
      expect(at(posPx, c, c, 2), greaterThan(240));
      expect(at(posPx, c, c, 0), lessThan(20));
      expect(at(negPx, c, c, 0), lessThan(20));
      expect(at(negPx, c, c, 2) / 255.0, closeTo(0.784, 0.04));

      // Right edge: nx strongly positive → pos.r high, neg.r ≈ 0. Left edge is
      // the mirror. The sign split is the whole point of the pair.
      expect(at(posPx, 56, c, 0), greaterThan(150));
      expect(at(negPx, 56, c, 0), lessThan(20));
      expect(at(negPx, 8, c, 0), greaterThan(150));
      expect(at(posPx, 8, c, 0), lessThan(20));

      // The measured flat-topped kernel: still above the 0.6 cut at 60% radius.
      expect(at(negPx, c + 19, c, 2) / 255.0, greaterThan(0.6));
    },
  );
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

double _smoothstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Standard deviation of the discrete Gaussian kernel of nominal [sigma],
/// in the same pixels. Below about one pixel the sampled kernel is much
/// narrower than [sigma].
double _effectiveSigma(double sigma) {
  if (sigma <= 0) return 0;
  final radius = (3 * sigma).ceil();
  var sum = 1.0;
  var variance = 0.0;
  for (var k = 1; k <= radius; k++) {
    final g = math.exp(-(k * k) / (2 * sigma * sigma));
    sum += 2 * g;
    variance += 2 * g * k * k;
  }
  return math.sqrt(variance / sum);
}

/// One signed half of the accumulation. [blur], when set, is applied to the
/// whole half; without it the field's sprites are drawn as they stand.
ui.Image _drawCoverage(
  CardWaterField field,
  Size raster,
  double headroom,
  double dropSize, {
  required bool negative,
  Paint? blur,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final half = Offset.zero & raster;
  canvas.save();
  canvas.clipRect(half);
  if (blur != null) canvas.saveLayer(half, blur);
  canvas.scale(CardWaterField.accumulationResolution);
  canvas.translate(0, headroom);
  field.paintCoverage(canvas, dropSize: dropSize, negative: negative);
  if (blur != null) canvas.restore();
  canvas.restore();
  final picture = recorder.endRecording();
  final image = picture.toImageSync(raster.width.ceil(), raster.height.ceil());
  picture.dispose();
  return image;
}

/// Mean absolute RGB error between two rawRgba buffers.
final class _RgbDiff {
  int sumR = 0;
  int sumG = 0;
  int sumB = 0;
  int n = 0;

  void add(Uint8List a, Uint8List b) {
    for (var i = 0; i < a.length; i += 4) {
      sumR += (a[i] - b[i]).abs();
      sumG += (a[i + 1] - b[i + 1]).abs();
      sumB += (a[i + 2] - b[i + 2]).abs();
      n++;
    }
  }

  double get r => sumR / n / 255.0;
  double get g => sumG / n / 255.0;
  double get b => sumB / n / 255.0;
}

/// Coverage is the negative half's blue channel, the channel the card shader
/// cuts on. A pixel is inside when it is strictly above [cut].
(int, int, int, int) _coverageIou(
  Uint8List a,
  Uint8List b,
  double aCut,
  double bCut,
) {
  var inter = 0;
  var union = 0;
  var aArea = 0;
  var bArea = 0;
  for (var i = 0; i < a.length; i += 4) {
    final aOn = a[i + 2] / 255.0 > aCut;
    final bOn = b[i + 2] / 255.0 > bCut;
    if (aOn) aArea++;
    if (bOn) bArea++;
    if (aOn && bOn) inter++;
    if (aOn || bOn) union++;
  }
  return (inter, union, aArea, bArea);
}
