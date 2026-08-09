@Tags(['preview'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'dart:typed_data';

import 'package:dpip/features/home/presentation/widgets/weather_sky/precipitation_field.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_clouds.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders reference-driven sky to PNGs for eyeballing.
///
/// Development aid, not an assertion — tagged `preview` and skipped by
/// default. Run with:
///
/// ```
/// mise exec -- flutter test --run-skipped --tags preview \
///   test/shaders/preview_render_test.dart
/// ```
void main() {
  // rootBundle needs the binding for the cloud sprite assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render sky across the keyframe ring', () async {
    final dir = Directory('build/sky_preview');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final transProgram = await ui.FragmentProgram.fromAsset(
      'shaders/sky/transmittance.frag',
    );
    final lutProgram = await ui.FragmentProgram.fromAsset(
      'shaders/sky/sky_lut.frag',
    );
    final viewProgram = await ui.FragmentProgram.fromAsset(
      'shaders/sky/sky_view.frag',
    );

    const size = Size(360, 620);

    final cases =
        <
          ({
            String name,
            List<SkyKeyframe> frames,
            double pos,
            CloudLayout layout,
            double coverage,
            double rain,
            double snow,
          })
        >[
          (
            name: 'sunny_00_night',
            frames: sunnyKeyframes,
            pos: 0,
            layout: CloudLayout.fair,
            coverage: 0.4,
            rain: 0.0,
            snow: 0.0,
          ),
          (
            name: 'sunny_04_dawn',
            frames: sunnyKeyframes,
            pos: 4,
            layout: CloudLayout.scattered,
            coverage: 0.7,
            rain: 0.0,
            snow: 0.0,
          ),
          (
            name: 'sunny_06',
            frames: sunnyKeyframes,
            pos: 6,
            layout: CloudLayout.fair,
            coverage: 1.0,
            rain: 0.0,
            snow: 0.0,
          ),
          (
            name: 'sunny_08_noon',
            frames: sunnyKeyframes,
            pos: 8,
            layout: CloudLayout.scattered,
            coverage: 0.7,
            rain: 0.0,
            snow: 0.0,
          ),
          (
            name: 'sunny_10',
            frames: sunnyKeyframes,
            pos: 10,
            layout: CloudLayout.fair,
            coverage: 1.0,
            rain: 0.0,
            snow: 0.0,
          ),
          (
            name: 'sunny_12_dusk',
            frames: sunnyKeyframes,
            pos: 12,
            layout: CloudLayout.scattered,
            coverage: 1.0,
            rain: 0.0,
            snow: 0.0,
          ),
          (
            name: 'sunny_14',
            frames: sunnyKeyframes,
            pos: 14,
            layout: CloudLayout.fair,
            coverage: 0.6,
            rain: 0.0,
            snow: 0.0,
          ),
          (
            name: 'cloudy_08',
            frames: cloudyKeyframes,
            pos: 8,
            layout: CloudLayout.scattered,
            coverage: 1.0,
            rain: 0.0,
            snow: 0.0,
          ),
          (
            name: 'overcast_01',
            frames: overcastKeyframes,
            pos: 1,
            layout: CloudLayout.overcast,
            coverage: 1.0,
            rain: 0.0,
            snow: 0.0,
          ),
          (
            name: 'rainy_heavy_01',
            frames: rainyHeavyKeyframes,
            pos: 1,
            layout: CloudLayout.rain,
            coverage: 1.0,
            rain: 0.85,
            snow: 0.0,
          ),
          (
            name: 'snow_day',
            frames: snowyMediumKeyframes,
            pos: 8,
            layout: CloudLayout.overcast,
            coverage: 1.0,
            rain: 0.0,
            snow: 0.7,
          ),
        ];

    Future<ui.Image> loadPng(String path) async {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    }

    final starMap = await loadPng('assets/weather/sky/starmap.webp');
    final galaxyProg = await ui.FragmentProgram.fromAsset(
      'shaders/weather/galaxy.frag',
    );
    final sunTex = <ui.Image>[
      await loadPng('assets/weather/sky/sun_profile.webp'),
      await loadPng('assets/weather/sky/sun_rays.webp'),
      await loadPng('assets/weather/sky/annulus.webp'),
    ];
    final sunProg = await ui.FragmentProgram.fromAsset(
      'shaders/weather/sun_flare.frag',
    );
    final rainAtlas = await loadPng('assets/weather/particles/rain_drop.png');
    final snowAtlas = await loadPng('assets/weather/particles/snow_flake.webp');
    final cloudProgram = await ui.FragmentProgram.fromAsset(
      'shaders/cloud/clouds.frag',
    );
    final sprites = <ui.Image>[];
    for (var i = 0; i < 12; i++) {
      final data = await rootBundle.load(
        'assets/weather/clouds/${i.toString().padLeft(2, '0')}.webp',
      );
      sprites.add(
        (await (await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        )).getNextFrame()).image,
      );
    }

    for (final c in cases) {
      final sky = resolveSky(c.frames, position: c.pos, humidity: 0.6);

      final trans = _bakeTransmittance(transProgram, sky);
      final lut = _bakeSkyLut(lutProgram, sky, trans);
      final image = _renderScene(
        viewProgram,
        cloudProgram,
        sprites,
        sky,
        lut,
        size,
        c.layout,
        c.coverage,
        rainAtlas,
        c.rain,
        snowAtlas,
        c.snow,
        sunProg,
        sunTex,
        c.pos,
        galaxyProg,
        starMap,
      );

      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '${dir.path}/${c.name}.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());

      final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final px = raw!.buffer.asUint8List();
      ({int r, int g, int b}) at(int y) {
        final i = (y * size.width.toInt() + size.width ~/ 2) * 4;
        return (r: px[i], g: px[i + 1], b: px[i + 2]);
      }

      // ignore: avoid_print
      print(
        '${c.name.padRight(16)} sunAngleY=${sky.sunAngleY.toStringAsFixed(3)} '
        'I=${sky.sunIntensity.toStringAsFixed(1).padLeft(5)} '
        'top=${at(10)} mid=${at(300)} low=${at(600)}',
      );

      trans.dispose();
      lut.dispose();
      image.dispose();
      // ignore: unnecessary_statements
      Uint8List;
    }

    // ignore: avoid_print
    print('wrote ${cases.length} frames to ${dir.absolute.path}');
  });
}

/// The reference's frustum construction: fixed 20° vertical FOV, 0.1 near
/// plane, camera at y = 0.017, pitched by the keyframe's `cameraYaw`.
({List<double> a, List<double> c}) _frustum(double cameraYawDeg) {
  const nearZ = 0.1;
  const eyeY = 0.017;
  final fTan = nearZ * math.tan(10.0 * math.pi / 180.0);
  final p = cameraYawDeg * math.pi / 180.0;
  final cp = math.cos(p);
  final sp = math.sin(p);
  return (
    a: [nearZ * cp - fTan * sp, eyeY + nearZ * sp + fTan * cp, 0.0],
    c: [nearZ * cp + fTan * sp, eyeY + nearZ * sp - fTan * cp, 0.0],
  );
}

ui.Image _bakeTransmittance(ui.FragmentProgram program, ResolvedSky sky) {
  final s = program.fragmentShader();
  var i = 0;
  void f(double v) => s.setFloat(i++, v);
  f(SkyConstants.transmittanceWidth.toDouble());
  f(SkyConstants.transmittanceHeight.toDouble());
  f(SkyConstants.rayleighScatter.$1);
  f(SkyConstants.rayleighScatter.$2);
  f(SkyConstants.rayleighScatter.$3);
  f(SkyConstants.ozoneAbsorb.$1);
  f(SkyConstants.ozoneAbsorb.$2);
  f(SkyConstants.ozoneAbsorb.$3);
  f(sky.rayleighHeight);
  f(sky.mieScatter);
  f(sky.mieAbsorb);
  f(sky.mieHeight);
  f(SkyConstants.ozoneCentre);
  f(sky.ozoneThickness);
  f(SkyConstants.planetRadius);
  f(SkyConstants.atmosphereRadius);
  return _rasterise(
    s,
    SkyConstants.transmittanceWidth,
    SkyConstants.transmittanceHeight,
  );
}

ui.Image _bakeSkyLut(
  ui.FragmentProgram program,
  ResolvedSky sky,
  ui.Image trans,
) {
  final s = program.fragmentShader();
  var i = 0;
  void f(double v) => s.setFloat(i++, v);
  f(SkyConstants.skyLutWidth.toDouble());
  f(SkyConstants.skyLutHeight.toDouble());
  f(SkyConstants.rayleighScatter.$1);
  f(SkyConstants.rayleighScatter.$2);
  f(SkyConstants.rayleighScatter.$3);
  f(SkyConstants.ozoneAbsorb.$1);
  f(SkyConstants.ozoneAbsorb.$2);
  f(SkyConstants.ozoneAbsorb.$3);
  f(sky.sunIntensity);
  f(sky.sunIntensity);
  f(sky.sunIntensity);
  f(sky.postColor.$1);
  f(sky.postColor.$2);
  f(sky.postColor.$3);
  f(sky.postColor.$4);
  f(sky.postColor.$5);
  f(sky.rayleighHeight);
  f(sky.mieScatter);
  f(sky.mieAbsorb);
  f(sky.mieHeight);
  f(sky.mieAsymmetry);
  f(SkyConstants.ozoneCentre);
  f(sky.ozoneThickness);
  f(SkyConstants.planetRadius);
  f(SkyConstants.atmosphereRadius);
  f(SkyConstants.eyeAltitude);
  f(SkyConstants.transmittanceWidth.toDouble());
  f(SkyConstants.transmittanceHeight.toDouble());
  s.setImageSampler(0, trans);
  return _rasterise(s, SkyConstants.skyLutWidth, SkyConstants.skyLutHeight);
}

ui.Image _renderScene(
  ui.FragmentProgram viewProgram,
  ui.FragmentProgram cloudProgram,
  List<ui.Image> sprites,
  ResolvedSky sky,
  ui.Image lut,
  Size size,
  CloudLayout layout,
  double coverage,
  ui.Image rainAtlas,
  double rain,
  ui.Image snowAtlas,
  double snow,
  ui.FragmentProgram sunProgram,
  List<ui.Image> sunTextures,
  double keyframePos,
  ui.FragmentProgram galaxyProgram,
  ui.Image starMapImage,
) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    Offset.zero & size,
    Paint()..shader = _skyShader(viewProgram, sky, lut, size),
  );

  // Milky Way first, under everything else.
  final night = (1.0 - ((sky.sunAngleY - 0.02) / 0.42).clamp(0.0, 1.0) / 0.25)
      .clamp(0.0, 1.0);
  if (night > 0.01) {
    final sh = galaxyProgram.fragmentShader();
    var k = 0;
    void f(double v) => sh.setFloat(k++, v);
    f(size.width);
    f(size.height);
    f(0.38);
    f(0.64);
    f(0.16);
    f(0.27);
    f(20.0);
    f(0.9);
    f(night * (1.0 - 0.95 * coverage));
    sh.setImageSampler(0, starMapImage);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = sh
        ..blendMode = BlendMode.plus,
    );
  }

  // The sun rides its arc with the keyframe's height.
  final day = ((sky.sunAngleY - 0.02) / 0.42).clamp(0.0, 1.0);
  if (day > 0.02) {
    final sh = sunProgram.fragmentShader();
    var k = 0;
    void f(double v) => sh.setFloat(k++, v);
    // Quarter-resolution buffer, as the reference does — the softness comes from the
    // 4x upscale afterwards.
    final q = Size(
      (size.width / 4).ceilToDouble(),
      (size.height / 4).ceilToDouble(),
    );
    f(q.width);
    f(q.height);
    final theta = ((keyframePos - 6.0) / 4.0).clamp(-0.5, 1.5);
    final ang = (theta - 0.5) * math.pi / 2.0;
    f(0.5 + math.sin(ang) * 0.5);
    f(0.5 - (0.5 - (1.0 - math.cos(ang)) * 0.15 + (-0.06 + 0.08 * day)));
    f(1.0);
    f(0.80);
    f(0.45);
    f(9.0);
    f(day);
    f(1.0 - 0.55 * coverage);
    f(0.45 * (1.0 - 0.7 * coverage));
    f(0.13 * (1.0 - coverage));
    f(1.03 * (1.0 - 0.8 * coverage));
    f(-0.5);
    f(3.0);
    f(0.8 * (1.0 - 0.5 * coverage));
    sh.setImageSampler(0, sunTextures[0]);
    sh.setImageSampler(1, sunTextures[1]);
    sh.setImageSampler(2, sunTextures[2]);
    final rec = ui.PictureRecorder();
    ui.Canvas(rec).drawRect(Offset.zero & q, Paint()..shader = sh);
    final small = rec.endRecording().toImageSync(
      q.width.toInt(),
      q.height.toInt(),
    );
    canvas.drawImageRect(
      small,
      Offset.zero & q,
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.low
        ..blendMode = BlendMode.plus,
    );
  }

  final lighting = cloudLighting(sunAngleY: sky.sunAngleY);
  final placed = placeClouds(
    layout,
    width: size.width,
    height: size.height,
    time: 40,
    coverage: coverage,
    wind: 0.2,
  );
  for (final p in placed) {
    final sprite = sprites[p.sprite % sprites.length];
    final shader = cloudProgram.fragmentShader();
    var i = 0;
    void f(double v) => shader.setFloat(i++, v);
    f(p.width);
    f(p.height);
    // Sun direction: swings with the sun's height across the sky.
    final el = (sky.sunAngleY / 0.57).clamp(0.0, 1.0);
    f(-0.55 + 1.1 * el);
    f(0.25 + 0.70 * el);
    f(0.45);
    f(0.0);
    f(-1.0);
    f(0.2); // ground bounce, from below
    f(0.0);
    f(1.0);
    f(0.1); // ambient, from above
    f(lighting.base.$1);
    f(lighting.base.$2);
    f(lighting.base.$3);
    f(lighting.sun.$1);
    f(lighting.sun.$2);
    f(lighting.sun.$3);
    f(lighting.ground.$1);
    f(lighting.ground.$2);
    f(lighting.ground.$3);
    f(lighting.ambient.$1);
    f(lighting.ambient.$2);
    f(lighting.ambient.$3);
    f(sky.sunAngleY);
    f(p.opacity);
    f(0.05); // start edge
    f(0.23); // end edge
    f(1.0); // progress — fully revealed
    f(0.35); // smooth
    f(0.85); // cloud depth
    f(el); // sun intensity
    f(0.0); // fog
    f(0.0); // inner
    f(lighting.whitePer);
    f(SkyConstants.skyLutWidth.toDouble());
    f(SkyConstants.skyLutHeight.toDouble());
    f(sprite.width.toDouble());
    f(sprite.height.toDouble());
    shader.setImageSampler(0, sprite);
    shader.setImageSampler(1, lut);

    canvas.save();
    canvas.translate(p.left, p.top);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, p.width, p.height),
      Paint()..shader = shader,
    );
    canvas.restore();
  }

  if (rain > 0.002) {
    final field = PrecipitationField(
      atlas: rainAtlas,
      capacity: 1792,
      variants: 4,
      cell: const Size(32, 68),
      seed: 7,
    );
    late ({
      Float32List transforms,
      Float32List rects,
      Int32List colors,
      int count,
    })
    batch;
    // Step a few frames so the field is in its steady state, not its seed.
    for (var i = 0; i < 40; i++) {
      // Mirrors `WeatherSkyPainter._paintRain` — keep the two in step or the
      // preview stops previewing anything.
      const lightRung = 0.321;
      final tier = ((rain - lightRung) / (1 - lightRung)).clamp(0.0, 1.0);
      batch = field.step(
        size: size,
        dt: 1 / 60,
        intensity: rain,
        fallSpeed: 2.25 + 0.35 * tier,
        wind: 0.0,
        opacity: 0.30,
        tint: const Color(0xFFF8F8F8),
        sizeMin: 0.018,
        sizeMax: 0.036 + 0.024 * tier,
        life: 3.0,
      );
    }
    canvas.drawRawAtlas(
      rainAtlas,
      batch.transforms,
      batch.rects,
      batch.colors,
      BlendMode.modulate,
      null,
      Paint()..blendMode = BlendMode.plus,
    );
  }
  if (snow > 0.002) {
    final field = PrecipitationField(
      atlas: snowAtlas,
      capacity: 900,
      cell: const Size(40, 40),
      tumble: true,
      seed: 11,
    );
    late ({
      Float32List transforms,
      Float32List rects,
      Int32List colors,
      int count,
    })
    batch;
    for (var i = 0; i < 8; i++) {
      batch = field.step(
        size: size,
        dt: 1 / 60,
        intensity: snow,
        fallSpeed: 0.10 + 0.10 * snow,
        wind: 0.2,
        opacity: 0.7 + 0.3 * snow,
        tint: const Color(0xFFF2F4F8),
        sizeMin: 0.004,
        sizeMax: 0.016,
        life: 3.0,
      );
    }
    canvas.drawRawAtlas(
      snowAtlas,
      batch.transforms,
      batch.rects,
      batch.colors,
      BlendMode.modulate,
      null,
      Paint(),
    );
  }

  return recorder.endRecording().toImageSync(
    size.width.toInt(),
    size.height.toInt(),
  );
}

ui.FragmentShader _skyShader(
  ui.FragmentProgram program,
  ResolvedSky sky,
  ui.Image lut,
  Size size,
) {
  final fr = _frustum(sky.cameraYaw);
  final s = program.fragmentShader();
  var i = 0;
  void f(double v) => s.setFloat(i++, v);
  f(size.width);
  f(size.height);
  f(fr.a[0]);
  f(fr.a[1]);
  f(fr.a[2]);
  f(fr.c[0]);
  f(fr.c[1]);
  f(fr.c[2]);
  f(sky.sunAngleY);
  f(4.0); // time
  f(SkyConstants.skyLutWidth.toDouble());
  f(SkyConstants.skyLutHeight.toDouble());
  s.setImageSampler(0, lut);
  return s;
}

ui.Image _rasterise(ui.FragmentShader shader, int width, int height) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..shader = shader,
  );
  return recorder.endRecording().toImageSync(width, height);
}
