/// The cloud deck is a 12 fps image. These tests pin the cadence, and they
/// write a same-time live-versus-deck pair so the 0.4× scale can be judged
/// on pixels rather than on a bench frame taken at a different phase.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_clouds.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_deck.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe_data.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_lut_cache.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_sky_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the deck is due on the period, a content change, or a first bake', () {
    expect(
      skyDeckDue(
        time: 1,
        bakedTime: double.nan,
        inFlight: false,
        contentChanged: false,
      ),
      isTrue,
    );
    expect(
      skyDeckDue(time: 1, bakedTime: 0.9, inFlight: true, contentChanged: true),
      isFalse,
    );
    expect(
      skyDeckDue(time: 1, bakedTime: 1, inFlight: false, contentChanged: true),
      isTrue,
    );
    expect(
      skyDeckDue(
        time: 1,
        bakedTime: 1 - kSkyDeckPeriod + 0.001,
        inFlight: false,
        contentChanged: false,
      ),
      isFalse,
    );
    expect(
      skyDeckDue(
        time: 1,
        bakedTime: 1 - kSkyDeckPeriod,
        inFlight: false,
        contentChanged: false,
      ),
      isTrue,
    );
  });

  test(
    'drift is the mean parallax, a few percent of the screen per second',
    () {
      // Fair at a clear-noon wind: 0.010 * (1 + 0.18 * 2) across depths
      // 0.75, 0.85 and 0.65.
      final clear = skyDeckDrift(CloudLayout.fair, 0.18);
      expect(clear, closeTo(0.01156, 1e-4));
      expect(clear, inInclusiveRange(0.008, 0.03));

      // Storm rain is the fast end, still well under a tenth of a screen.
      final storm = skyDeckDrift(CloudLayout.rain, 0.65);
      expect(storm, greaterThan(clear));
      expect(storm, lessThan(0.12));
      // Two periods of the fastest drift fit inside the painted margin.
      expect(storm * kSkyDeckPeriod * 2, lessThan(kSkyDeckMargin));
    },
  );

  testWidgets('a second of frames re-rasterizes the deck at most 12 times', (
    tester,
  ) async {
    final deck = SkyDeck();
    addTearDown(deck.dispose);
    debugResetSkyDeckRenders();

    const view = Size(160, 280);
    for (var i = 0; i < 60; i++) {
      _present(
        deck,
        view: view,
        time: i / 60,
        layout: CloudLayout.fair,
        wind: 0.18,
        coverage: 0.35,
        flash: 0,
      );
      await tester.pump();
    }

    // 0, 5, 10, …, 55 — one raster per period, not one per vsync.
    expect(debugSkyDeckRenders, greaterThanOrEqualTo(8));
    expect(debugSkyDeckRenders, lessThanOrEqualTo(13));
    expect(deck.debugHasImage, isTrue);

    // A lightning step is not a drift. It rebakes on the next frame.
    debugResetSkyDeckRenders();
    _present(
      deck,
      view: view,
      time: 59 / 60,
      layout: CloudLayout.fair,
      wind: 0.18,
      coverage: 0.35,
      flash: 1,
    );
    expect(debugSkyDeckRenders, 1);
  });

  testWidgets('the 0.4 deck matches a same-time live deck', (tester) async {
    // Asset and codec futures do not complete in the fake test zone.
    final shaders = (await tester.runAsync(_shaders))!;
    final sprites = (await tester.runAsync(_sprites))!;
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
      for (final sprite in sprites) {
        sprite.dispose();
      }
    });

    // The emulator's physical frame (1080×1920). dpr is 1 because this
    // canvas already is physical pixels: production multiplies by the real
    // ratio and the deck is still 0.4 of the screen. renderScale 0.75 is
    // the fast-layer buffer the blit lands in.
    const buffer = Size(810, 1440);
    const screen = Size(1080, 1920);

    final noon = keyframePosition(12, frameCount: sunnyKeyframes.length);
    final clear = await _compare(
      tester,
      lut: lut,
      shaders: shaders,
      sprites: sprites,
      name: 'clear-noon',
      sky: resolveSky(sunnyKeyframes, position: noon, humidity: 0.65),
      layout: CloudLayout.fair,
      coverage: 0.35,
      wind: 0.18,
      buffer: buffer,
      screen: screen,
    );
    final overcast = await _compare(
      tester,
      lut: lut,
      shaders: shaders,
      sprites: sprites,
      name: 'overcast-noon',
      sky: resolveSky(overcastKeyframes, position: noon, humidity: 0.65),
      layout: CloudLayout.overcast,
      coverage: 1,
      wind: 0.20,
      fog: 0.05,
      buffer: buffer,
      screen: screen,
    );

    // A vanished or shifted deck moves whole clouds (channel deltas in the
    // tens and up). The 0.4× blit only softens an edge, which stays under
    // a just-noticeable step across the cloud band.
    for (final scene in [clear, overcast]) {
      expect(scene.max, lessThan(32), reason: scene.name);
      expect(scene.mean, lessThan(2), reason: scene.name);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}

void _present(
  SkyDeck deck, {
  required Size view,
  required double time,
  required CloudLayout layout,
  required double wind,
  required double coverage,
  required double flash,
}) {
  final recorder = ui.PictureRecorder();
  deck.present(
    canvas: Canvas(recorder),
    view: view,
    renderScale: 0.75,
    devicePixelRatio: 1,
    time: time,
    layout: layout,
    wind: wind,
    coverage: coverage,
    flash: flash,
    paintClouds: (canvas, size) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0x66FFFFFF),
      );
    },
  );
  recorder.endRecording().dispose();
}

class _SceneDiff {
  final String name;
  final int max;
  final double mean;
  final double changedFraction;
  const _SceneDiff(this.name, this.max, this.mean, this.changedFraction);
}

Future<_SceneDiff> _compare(
  WidgetTester tester, {
  required SkyLutCache lut,
  required Map<String, ui.FragmentShader> shaders,
  required List<ui.Image> sprites,
  required String name,
  required ResolvedSky sky,
  required CloudLayout layout,
  required double coverage,
  required double wind,
  required Size buffer,
  required Size screen,
  double fog = 0,
}) async {
  final generation = lut.readbackGeneration;
  lut.update(sky);
  for (
    var i = 0;
    i < 40 && (lut.readbackGeneration == generation || lut.skyColumn == null);
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
  }
  expect(lut.skyColumn, isNotNull, reason: '$name LUT');
  expect(lut.readbackGeneration, greaterThan(generation), reason: '$name LUT');

  const time = 4.0;
  final frame = SkyFrame(
    time: time,
    sky: sky,
    cloudLayout: layout,
    cloudCoverage: coverage,
    rain: 0,
    snow: 0,
    fog: fog,
    rainbow: 0,
    wind: wind,
    lightning: LightningFrame.none,
    moonPhase: 0.5,
    keyframePosition: 8,
  );

  WeatherSkyPainter painter({SkyDeck? deck}) => WeatherSkyPainter(
    shaders: shaders,
    lutCache: lut,
    cloudSprites: sprites,
    sunTextures: const [],
    frame: frame,
    rainField: null,
    snowField: null,
    dt: 0,
    deck: deck,
    renderScale: 0.75,
    devicePixelRatio: 1,
  );

  // Finish the live raster before the deck mutates the shared cloud shader.
  final live = _capture(painter(), buffer);
  final deck = SkyDeck();
  addTearDown(deck.dispose);
  // Record the first deck without rasterizing that picture. The deck's own
  // toImage is the raster that has to land, and it only completes outside
  // the fake async zone.
  await tester.runAsync(() async {
    final opening = ui.PictureRecorder();
    painter(deck: deck).paint(Canvas(opening), buffer);
    opening.endRecording().dispose();
    for (var i = 0; i < 50 && !deck.debugHasImage; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
  expect(deck.debugHasImage, isTrue, reason: '$name deck');
  final cached = _capture(painter(deck: deck), buffer);

  final liveScreen = _upscale(live, buffer, screen);
  final cachedScreen = _upscale(cached, buffer, screen);
  live.dispose();
  cached.dispose();

  final liveBytes = await tester.runAsync(
    () => liveScreen.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final cachedBytes = await tester.runAsync(
    () => cachedScreen.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final a = liveBytes!.buffer.asUint8List();
  final b = cachedBytes!.buffer.asUint8List();
  final width = screen.width.toInt();
  final height = screen.height.toInt();
  final y0 = (height * 0.05).floor();
  final y1 = (height * 0.70).floor();
  var max = 0;
  var sum = 0;
  var samples = 0;
  var changed = 0;
  final diff = Uint8List(a.length);
  for (var y = y0; y < y1; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final dr = (a[i] - b[i]).abs();
      final dg = (a[i + 1] - b[i + 1]).abs();
      final db = (a[i + 2] - b[i + 2]).abs();
      final d = dr > dg ? (dr > db ? dr : db) : (dg > db ? dg : db);
      if (d > max) max = d;
      if (d > 24) changed++;
      sum += dr + dg + db;
      samples++;
      final amp = d * 4 > 255 ? 255 : d * 4;
      diff[i] = amp;
      diff[i + 1] = amp;
      diff[i + 2] = amp;
      diff[i + 3] = 255;
    }
  }
  final mean = sum / (samples * 3);
  final fraction = changed / samples;

  final dir = Directory('build/bench/cloud-deck')..createSync(recursive: true);
  await _writePng(tester, liveScreen, '${dir.path}/$name-live.png');
  await _writePng(tester, cachedScreen, '${dir.path}/$name-deck.png');
  final diffImage = await _imageFromRgba(tester, diff, width, height);
  await _writePng(tester, diffImage, '${dir.path}/$name-diff.png');
  diffImage.dispose();
  liveScreen.dispose();
  cachedScreen.dispose();

  File('${dir.path}/$name.json').writeAsStringSync(
    '{"max":$max,"mean":${mean.toStringAsFixed(3)},'
    '"changedFraction":${fraction.toStringAsFixed(4)},'
    '"samples":$samples}\n',
  );
  return _SceneDiff(name, max, mean, fraction);
}

ui.Image _capture(WeatherSkyPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(size.width.toInt(), size.height.toInt());
  picture.dispose();
  return image;
}

ui.Image _upscale(ui.Image source, Size from, Size to) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    source,
    Offset.zero & from,
    Offset.zero & to,
    Paint()..filterQuality = FilterQuality.low,
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(to.width.toInt(), to.height.toInt());
  picture.dispose();
  return image;
}

Future<void> _writePng(WidgetTester tester, ui.Image image, String path) async {
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<ui.Image> _imageFromRgba(
  WidgetTester tester,
  Uint8List pixels,
  int width,
  int height,
) async {
  final image = await tester.runAsync(() async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    descriptor.dispose();
    codec.dispose();
    buffer.dispose();
    return frame.image;
  });
  expect(image, isNotNull);
  return image!;
}

Future<Map<String, ui.FragmentShader>> _shaders() async {
  const assets = [
    'shaders/sky/transmittance.frag',
    'shaders/sky/sky_lut.frag',
    WeatherSkyPainter.cloudsAsset,
  ];
  final loaded = <String, ui.FragmentShader>{};
  for (final asset in assets) {
    final program = await ui.FragmentProgram.fromAsset(asset);
    loaded[asset] = program.fragmentShader();
  }
  return loaded;
}

Future<List<ui.Image>> _sprites() async {
  final sprites = <ui.Image>[];
  for (var i = 0; i < 12; i++) {
    final data = await rootBundle.load(
      'assets/weather/clouds/${i.toString().padLeft(2, '0')}.webp',
    );
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    sprites.add((await codec.getNextFrame()).image);
    codec.dispose();
  }
  return sprites;
}
