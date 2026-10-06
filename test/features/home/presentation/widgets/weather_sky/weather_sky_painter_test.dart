/// The sky painter gates every layer on its own control. A missing shader, a
/// zero intensity, or a rainbow the backdrop never asks for must still be a
/// legal frame — the home sheet builds one of these on every tick.
library;

import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/precipitation_field.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_clouds.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_lut_cache.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_sky_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('frame weights and lightning identity follow the sun', () {
    final night = _frame(sun: 0.01);
    final golden = _frame(sun: 0.02 + 0.18 * 0.42);
    final noon = _frame(sun: 0.5, coverage: 1);
    // Day 0.6 is past the golden window (it closes at 0.55).
    final edge = _frame(sun: 0.02 + 0.6 * 0.42);

    expect(night.dayAmount, 0);
    expect(night.nightAmount, 1);
    expect(night.goldenAmount, 0);
    expect(night.sunIntensity, 0);

    expect(golden.goldenAmount, greaterThan(0.9));
    expect(edge.goldenAmount, 0);
    expect(noon.dayAmount, 1);
    expect(noon.nightAmount, 0);
    expect(noon.goldenAmount, 0);
    expect(noon.sunIntensity, closeTo(0.2, 1e-9));

    const strike = LightningFrame(age: 0.1, flash: 0.4, bolt: 0.2, seed: 3);
    expect(LightningFrame.none.isActive, isFalse);
    expect(strike.isActive, isTrue);
    expect(strike, strike);
    expect(strike, isNot(LightningFrame.none));
    expect(strike.hashCode, Object.hash(0.1, 0.4, 0.2, 3));
    expect(strike == Object(), isFalse);
  });

  testWidgets('paint draws each layer and takes every early exit', (
    tester,
  ) async {
    final ambient = SkyLutCache.panelAmbient.value;
    final light = SkyLutCache.panelAmbientIsLight.value;
    addTearDown(() {
      SkyLutCache.panelAmbient.value = ambient;
      SkyLutCache.panelAmbientIsLight.value = light;
    });

    final shaders = await _shaders();
    final transmittance = shaders.remove('shaders/sky/transmittance.frag')!;
    final skyLut = shaders.remove('shaders/sky/sky_lut.frag')!;
    final lut = SkyLutCache(transmittance, skyLut);
    addTearDown(() {
      lut.dispose();
      for (final shader in shaders.values) {
        shader.dispose();
      }
      transmittance.dispose();
      skyLut.dispose();
    });

    final sprite = _image(32, 32);
    final sun = [_image(16, 16), _image(16, 16), _image(16, 16)];
    final rainAtlas = _image(128, 68);
    final snowAtlas = _image(40, 40);
    addTearDown(() {
      sprite.dispose();
      for (final image in sun) {
        image.dispose();
      }
      rainAtlas.dispose();
      snowAtlas.dispose();
    });

    final rain = PrecipitationField(
      atlas: rainAtlas,
      capacity: 8,
      variants: 4,
      cell: const Size(32, 68),
    );
    final emptyRain = PrecipitationField(
      atlas: rainAtlas,
      capacity: 0,
      variants: 4,
      cell: const Size(32, 68),
    );
    final snow = PrecipitationField(
      atlas: snowAtlas,
      capacity: 6,
      cell: const Size(40, 40),
      tumble: true,
    );

    const size = Size(80, 40);

    final withoutNightField = Map<String, ui.FragmentShader>.of(shaders)
      ..remove(WeatherSkyPainter.nightFieldAsset);

    // Flat sky (no gradient yet) and a night pass with nothing to sample.
    _draw(
      _painter(
        frame: _frame(sun: 0.01, coverage: 0),
        shaders: withoutNightField,
        sprites: const [],
        lut: lut,
      ),
      size,
    );
    _draw(
      _painter(
        frame: _frame(sun: 0.5),
        shaders: {
          WeatherSkyPainter.nightAsset: shaders[WeatherSkyPainter.nightAsset]!,
        },
        sprites: const [],
        lut: lut,
        sunTextures: sun,
      ),
      size,
    );

    // Bake the star field, then reuse it. Coverage under the cloud floor and
    // an empty sprite list both skip the deck.
    _draw(
      _painter(
        frame: _frame(sun: 0.01, coverage: 0.4, fog: 0.2),
        shaders: shaders,
        sprites: [sprite],
        lut: lut,
      ),
      size,
    );
    _draw(
      _painter(
        frame: _frame(sun: 0.01, coverage: 0.01),
        shaders: shaders,
        sprites: const [],
        lut: lut,
      ),
      size,
    );

    final baked = _sky(0.3);
    lut.update(baked);
    for (var i = 0; i < 40 && lut.skyGradient == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
    }
    expect(lut.skyGradient, isNotNull, reason: 'the LUT readback should land');
    expect(lut.skyColumn, isNotNull);

    final cloudy = _frame(
      sky: baked,
      coverage: 0.8,
      fog: 0.4,
      wind: 0.3,
      rain: 0.4,
    );
    final deck = _painter(
      frame: cloudy,
      shaders: shaders,
      sprites: [sprite],
      lut: lut,
      rainField: emptyRain,
      snowField: snow,
    );
    _draw(deck, size);
    // Same keyframe identity: the cloud-probe memo hits.
    _draw(deck, size);
    expect(deck.shouldRepaint(deck), isFalse);
    expect(
      deck.shouldRepaint(
        _painter(
          frame: _frame(sun: 0.01),
          shaders: shaders,
          sprites: [sprite],
          lut: lut,
        ),
      ),
      isTrue,
    );

    final storm = LightningFrame(age: 0.2, flash: 1, bolt: 0.6, seed: 9);
    final full = _painter(
      frame: _frame(
        sky: baked,
        coverage: 0.2,
        rain: 0.8,
        snow: 0.7,
        wind: 0.4,
        lightning: storm,
        rainbow: 0.6,
        key: 4,
        time: 1.2,
      ),
      shaders: shaders,
      sprites: [sprite],
      lut: lut,
      sunTextures: sun,
      rainField: rain,
      snowField: snow,
    );
    _draw(full, size);

    await tester.pumpWidget(CustomPaint(size: size, painter: full));
    await tester.pump();

    // Two sun textures is not a flare. A later time bucket re-bakes the one
    // that is. Rain and snow under the floor return before the field steps.
    _draw(
      _painter(
        frame: _frame(
          sky: baked,
          coverage: 0.2,
          rain: 0.001,
          snow: 0.001,
          rainbow: 0,
          key: 8,
          time: 1.2,
        ),
        shaders: shaders,
        sprites: [sprite],
        lut: lut,
        sunTextures: sun.sublist(0, 2),
        rainField: rain,
        snowField: snow,
      ),
      size,
    );
    _draw(
      _painter(
        frame: _frame(sun: 0.01, coverage: 1, key: 6, time: 0.05),
        shaders: shaders,
        sprites: [sprite],
        lut: lut,
        sunTextures: sun,
      ),
      size,
    );
    _draw(
      _painter(
        frame: _frame(
          sky: _sky(0.5),
          coverage: 0.1,
          rainbow: 0.4,
          key: 12,
          time: 2,
        ),
        shaders: shaders,
        sprites: [sprite],
        lut: lut,
        sunTextures: sun,
      ),
      size,
    );
  });
}

void _draw(WeatherSkyPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(size.width.toInt(), size.height.toInt());
  picture.dispose();
  image.dispose();
}

WeatherSkyPainter _painter({
  required SkyFrame frame,
  required Map<String, ui.FragmentShader> shaders,
  required List<ui.Image> sprites,
  required SkyLutCache lut,
  List<ui.Image> sunTextures = const [],
  PrecipitationField? rainField,
  PrecipitationField? snowField,
}) {
  return WeatherSkyPainter(
    shaders: shaders,
    lutCache: lut,
    cloudSprites: sprites,
    sunTextures: sunTextures,
    frame: frame,
    rainField: rainField,
    snowField: snowField,
    dt: 1 / 60,
  );
}

Future<Map<String, ui.FragmentShader>> _shaders() async {
  const assets = [
    'shaders/sky/transmittance.frag',
    'shaders/sky/sky_lut.frag',
    WeatherSkyPainter.nightAsset,
    WeatherSkyPainter.nightFieldAsset,
    WeatherSkyPainter.cloudsAsset,
    WeatherSkyPainter.lightningAsset,
    WeatherSkyPainter.sunFlareAsset,
    WeatherSkyPainter.rainbowAsset,
  ];
  final loaded = <String, ui.FragmentShader>{};
  for (final asset in assets) {
    final program = await ui.FragmentProgram.fromAsset(asset);
    loaded[asset] = program.fragmentShader();
  }
  return loaded;
}

ui.Image _image(int width, int height) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}

ResolvedSky _sky(double sun) => ResolvedSky(
  sunAngleY: sun,
  cameraYaw: 20,
  sunIntensity: 1,
  rayleighHeight: 8000,
  mieScatter: 0.005,
  mieAbsorb: 0.001,
  mieHeight: 1200,
  mieAsymmetry: 0.8,
  ozoneThickness: 0.3,
  postColor: (1, 1, 1, 0, 0),
);

SkyFrame _frame({
  double sun = 0.3,
  ResolvedSky? sky,
  double coverage = 0.5,
  double rain = 0,
  double snow = 0,
  double fog = 0,
  double wind = 0,
  double rainbow = 0,
  LightningFrame lightning = LightningFrame.none,
  double key = 8,
  double time = 0.4,
}) => SkyFrame(
  time: time,
  sky: sky ?? _sky(sun),
  cloudLayout: CloudLayout.scattered,
  cloudCoverage: coverage,
  rain: rain,
  snow: snow,
  fog: fog,
  rainbow: rainbow,
  wind: wind,
  lightning: lightning,
  moonPhase: 0.5,
  keyframePosition: key,
);
