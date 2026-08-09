import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_clouds.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/precipitation_field.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_lut_cache.dart';
import 'package:flutter/material.dart';

/// The per-frame scene state the painter renders.
///
/// [sky] is the resolved keyframe — the reference engine drives everything from a
/// keyframe ring rather than a sun position, so `sky.sunAngleY` (the sky LUT's
/// u coordinate) is what every layer derives its time of day from.
class SkyFrame {
  /// Seconds since the animation started.
  final double time;

  /// The interpolated atmosphere and colours for this moment.
  final ResolvedSky sky;

  /// Cloud arrangement and how much of it is shown.
  final CloudLayout cloudLayout;
  final double cloudCoverage;

  /// Rain intensity 0..1.
  final double rain;

  /// Snow heaviness 0..1.
  final double snow;

  /// Fog density 0..1.
  final double fog;

  /// Rainbow opacity 0..1.
  final double rainbow;

  /// Wind, signed; slants precipitation and speeds cloud drift.
  final double wind;

  /// Lightning state for this frame.
  final LightningFrame lightning;

  /// Moon phase 0 new → 0.5 full → 1 new.
  final double moonPhase;

  /// Where the scene sits on its keyframe ring — the sun's arc is a function
  /// of this, not of wall-clock time.
  final double keyframePosition;

  const SkyFrame({
    required this.time,
    required this.sky,
    required this.cloudLayout,
    required this.cloudCoverage,
    required this.rain,
    required this.snow,
    required this.fog,
    required this.rainbow,
    required this.wind,
    required this.lightning,
    required this.moonPhase,
    required this.keyframePosition,
  });

  /// How high the sun sits, 0 (night) … 1 (midday), from the keyframe's
  /// authored `sunAngleY` rather than any elevation angle.
  double get dayAmount => ((sky.sunAngleY - 0.02) / 0.42).clamp(0.0, 1.0);

  /// Night weight — drives the star field and the grade's cool cast.
  double get nightAmount => (1.0 - dayAmount / 0.25).clamp(0.0, 1.0);

  /// Golden-hour weight, peaking when the sun is low but present.
  double get goldenAmount {
    final d = dayAmount;
    if (d <= 0.02 || d >= 0.55) return 0.0;
    return (1.0 - ((d - 0.18).abs() / 0.30)).clamp(0.0, 1.0);
  }

  /// Direct-sun strength reaching the scene, cut by cloud cover.
  double get sunIntensity => dayAmount * (1.0 - 0.8 * cloudCoverage);
}

/// A single lightning strike's state within its own timeline.
class LightningFrame {
  final double age;
  final double flash;
  final double bolt;
  final double seed;

  const LightningFrame({
    required this.age,
    required this.flash,
    required this.bolt,
    required this.seed,
  });

  static const LightningFrame none = LightningFrame(
    age: 0,
    flash: 0,
    bolt: 0,
    seed: 0,
  );

  bool get isActive => flash > 0.002 || bolt > 0.002;

  @override
  bool operator ==(Object other) =>
      other is LightningFrame &&
      other.age == age &&
      other.flash == flash &&
      other.bolt == bolt &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(age, flash, bolt, seed);
}

/// Draws the layer stack in the reference scene order.
///
/// Order mirrors the original engine: sky → night → clouds → precipitation →
/// lightning → sun flare → rainbow → fog → grade. Each layer gates itself on
/// its own control value, so drawing all of them costs almost nothing when
/// the weather is calm.
class WeatherSkyPainter extends CustomPainter {
  final Map<String, ui.FragmentShader> shaders;
  final ui.Image? skyView;
  final List<ui.Image> cloudSprites;

  /// Sun disc ramp, static ray pattern and ring ramp, in that order.
  final List<ui.Image> sunTextures;

  /// Equirectangular Milky Way, or `null` if it failed to load.
  final ui.Image? starMap;
  final SkyFrame frame;

  /// Rain and snow particle fields, or `null` before their sprites load.
  final PrecipitationField? rainField;
  final PrecipitationField? snowField;

  /// Seconds since the previous frame, for the particle integration.
  final double dt;

  const WeatherSkyPainter({
    required this.shaders,
    required this.skyView,
    required this.cloudSprites,
    required this.sunTextures,
    required this.starMap,
    required this.frame,
    required this.rainField,
    required this.snowField,
    required this.dt,
  });

  // Asset keys, matching `pubspec.yaml`.
  static const String skyViewAsset = 'shaders/sky/sky_view.frag';
  static const String cloudsAsset = 'shaders/cloud/clouds.frag';
  static const String galaxyAsset = 'shaders/weather/galaxy.frag';
  static const String nightAsset = 'shaders/weather/night.frag';
  static const String lightningAsset = 'shaders/weather/lightning.frag';
  static const String sunFlareAsset = 'shaders/weather/sun_flare.frag';
  static const String rainbowAsset = 'shaders/weather/rainbow.frag';

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintGalaxy(canvas, size);
    _paintNight(canvas, size);
    _paintClouds(canvas, size);
    _paintRain(canvas, size);
    _paintSnow(canvas, size);
    _paintLightning(canvas, size);
    _paintSunFlare(canvas, size);
    _paintRainbow(canvas, size);
  }

  @override
  bool shouldRepaint(WeatherSkyPainter old) =>
      old.frame.time != frame.time ||
      !identical(old.frame, frame) ||
      !identical(old.skyView, skyView);

  void _fill(
    Canvas canvas,
    Size size,
    ui.FragmentShader shader, [
    BlendMode blend = BlendMode.srcOver,
  ]) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = blend,
    );
  }

  // --- sky ----------------------------------------------------------------
  void _paintSky(Canvas canvas, Size size) {
    final shader = shaders[skyViewAsset];
    final lut = skyView;
    if (shader == null || lut == null) return;

    final fr = buildFrustum(frame.sky.cameraYaw);
    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    set(size.width);
    set(size.height);
    set(fr.top[0]);
    set(fr.top[1]);
    set(fr.top[2]);
    set(fr.bottom[0]);
    set(fr.bottom[1]);
    set(fr.bottom[2]);
    set(frame.sky.sunAngleY);
    set(frame.time);
    set(SkyLutCache.skyViewSize.width);
    set(SkyLutCache.skyViewSize.height);
    shader.setImageSampler(0, lut);

    _fill(canvas, size, shader);
  }

  // --- galaxy ---------------------------------------------------------------
  void _paintGalaxy(Canvas canvas, Size size) {
    final shader = shaders[galaxyAsset];
    final map = starMap;
    final night = frame.nightAmount;
    if (shader == null || map == null || night < 0.01) return;

    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    set(size.width);
    set(size.height);
    // The engine's own orientation. Note the first is
    // a rotation angle, not an opacity, despite its name.
    set(0.38);
    set(0.64);
    set(0.16);
    set(0.27); // fov
    set(frame.time);
    set(0.9);
    // Cloud hides the galaxy faster than it hides the brighter stars.
    set(night * (1.0 - 0.95 * frame.cloudCoverage));
    shader.setImageSampler(0, map);

    // `SRC_ALPHA, ONE` in the engine.
    _fill(canvas, size, shader, BlendMode.plus);
  }

  // --- night --------------------------------------------------------------
  void _paintNight(Canvas canvas, Size size) {
    final shader = shaders[nightAsset];
    final night = frame.nightAmount;
    if (shader == null || night < 0.01) return;

    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    set(size.width);
    set(size.height);
    set(0.62);
    set(0.68);
    set(0.92); // galaxy tint
    set(frame.time);
    set(night);
    set(0.0); // scroll
    set(frame.cloudCoverage);
    // The real Milky Way is its own layer now; the procedural band is off.
    set(0.0);

    _fill(canvas, size, shader);
  }

  // --- clouds -------------------------------------------------------------
  void _paintClouds(Canvas canvas, Size size) {
    final shader = shaders[cloudsAsset];
    final lut = skyView;
    if (shader == null || lut == null || cloudSprites.isEmpty) return;
    if (frame.cloudCoverage < 0.02) return;

    // Clouds probe the same frustum the sky is drawn through.
    final fr = buildFrustum(frame.sky.cameraYaw);
    final lighting = cloudLighting(sunAngleY: frame.sky.sunAngleY);
    final placed = placeClouds(
      frame.cloudLayout,
      width: size.width,
      height: size.height,
      time: frame.time,
      coverage: frame.cloudCoverage,
      wind: frame.wind,
    );

    // The sun's direction swings across the sky with its height, so lit faces
    // move around the cloud through the day.
    final day = frame.dayAmount;
    final sunDir = [-0.55 + 1.1 * day, 0.25 + 0.70 * day, 0.45];

    for (final p in placed) {
      final sprite = cloudSprites[p.sprite % cloudSprites.length];
      var i = 0;
      void set(double v) => shader.setFloat(i++, v);
      set(p.width);
      set(p.height);
      set(sunDir[0]);
      set(sunDir[1]);
      set(sunDir[2]);
      set(0.0);
      set(-1.0);
      set(0.2); // ground bounce, from below
      set(0.0);
      set(1.0);
      set(0.1); // ambient, from above
      set(lighting.base.$1);
      set(lighting.base.$2);
      set(lighting.base.$3);
      set(lighting.sun.$1);
      set(lighting.sun.$2);
      set(lighting.sun.$3);
      set(lighting.ground.$1);
      set(lighting.ground.$2);
      set(lighting.ground.$3);
      set(lighting.ambient.$1);
      set(lighting.ambient.$2);
      set(lighting.ambient.$3);
      set(frame.sky.sunAngleY);
      set(p.opacity);
      set(0.05); // start edge
      set(0.23); // end edge
      set(1.0); // progress — deck fully revealed
      set(0.35); // smooth
      set(0.85); // cloud depth
      set(day);
      set(frame.fog * 0.5);
      set(frame.lightning.flash * 0.8);
      set(lighting.whitePer);
      set(SkyLutCache.skyViewSize.width);
      set(SkyLutCache.skyViewSize.height);
      set(fr.top[0]);
      set(fr.top[1]);
      set(fr.top[2]);
      set(fr.bottom[0]);
      set(fr.bottom[1]);
      set(fr.bottom[2]);
      set(sprite.width.toDouble());
      set(sprite.height.toDouble());
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
  }

  // --- rain ---------------------------------------------------------------
  //
  // Drawn as sprites rather than a fragment shader, because that is what the reference
  // does: instanced textured quads of a motion-blurred streak. A procedural
  // curtain cannot reproduce the sprite's taper and head, which is most of
  // what makes rain read as rain.
  void _paintRain(Canvas canvas, Size size) {
    final field = rainField;
    if (field == null || frame.rain < 0.002) return;

    // The reference's streak sprite is WHITE (its texture's RGB is 248/255 wherever
    // alpha > 0) and composites additively — night rain dims because the
    // *alpha* is tiny over a dark sky, not because the drops are tinted. An
    // earlier version tinted them with the sky *and* ran them at 2.5x the reference's
    // alpha, which is two compensating errors that never cancel.
    final lift = frame.lightning.flash * 0.8;
    final white = (248 + lift * 7).clamp(0.0, 255.0).round();
    final tint = Color.fromARGB(255, white, white, white);

    // Where this rain sits on the reference's four-preset ladder (0 = 小雨, 1 = 暴雨).
    // `frame.rain` is the particle-count fraction, and 小雨 is 576/1792.
    const lightRung = 0.321;
    final tier = ((frame.rain - lightRung) / (1 - lightRung)).clamp(0.0, 1.0);

    final batch = field.step(
      size: size,
      dt: dt,
      intensity: frame.rain,
      // The reference's speed uniform is -4.5 (小雨) to -5.2 (暴雨) in NDC units per
      // second, and the screen spans 2.0 NDC — so 2.25 to 2.60 screen heights
      // per second. This is the *near* drop's speed; `speedScale` scales the
      // rest of the field down from it.
      fallSpeed: 2.25 + 0.35 * tier,
      // The reference's rain falls perfectly vertically — the compute shader has no
      // wind term at all.
      wind: 0.0,
      // A flat 0.30, not a ramp: `particle_rain_frag_shader` multiplies this by
      // `mix(0.3, 2, depth)` and the life curve, which is where the variation
      // comes from. Peak per-drop alpha lands at 0.229 and a median drop at
      // 0.047 — a faint veil.
      opacity: 0.30,
      tint: tint,
      // `particle_rain.comp` sets the quad's `scale.y` to `startSize * 3.0`,
      // and this field's `size` *is* the drawn length as a fraction of the
      // widget height — so the reference's startSize range carries that x3. Light rain
      // spans 0.018..0.036 of the height; the storm preset reaches 0.060.
      sizeMin: 0.018,
      sizeMax: 0.036 + 0.024 * tier,
      life: 3.0,
    );
    if (batch.count == 0) return;

    // Additive, as the reference sets `setBlendFunc(SRC_ALPHA, ONE)`.
    canvas.drawRawAtlas(
      field.atlas,
      batch.transforms,
      batch.rects,
      batch.colors,
      BlendMode.modulate,
      null,
      Paint()..blendMode = BlendMode.plus,
    );
  }

  // --- snow ---------------------------------------------------------------
  void _paintSnow(Canvas canvas, Size size) {
    final field = snowField;
    if (field == null || frame.snow < 0.002) return;

    // Flakes are lit by the sky, so they grey down at night.
    final lit = ((1.0 - 0.5 * frame.nightAmount) * 255).round();
    final tint = Color.fromARGB(
      255,
      lit,
      lit,
      (lit * 1.02).clamp(0, 255).round(),
    );

    final batch = field.step(
      size: size,
      dt: dt,
      intensity: frame.snow,
      fallSpeed: 0.10 + 0.10 * frame.snow,
      wind: frame.wind * 1.6,
      opacity: 0.7 + 0.3 * frame.snow,
      tint: tint,
      sizeMin: 0.004,
      sizeMax: 0.016,
      life: 8.0,
    );
    if (batch.count == 0) return;

    canvas.drawRawAtlas(
      field.atlas,
      batch.transforms,
      batch.rects,
      batch.colors,
      BlendMode.modulate,
      null,
      Paint(),
    );
  }

  // --- lightning ----------------------------------------------------------
  void _paintLightning(Canvas canvas, Size size) {
    final shader = shaders[lightningAsset];
    if (shader == null || !frame.lightning.isActive) return;

    final l = frame.lightning;
    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    set(size.width);
    set(size.height);
    set(0.70);
    set(0.80);
    set(1.00);
    set(0.25);
    set(0.32);
    set(0.55);
    set(1.0);
    set(1.0);
    set(1.0);
    set(l.age);
    set(l.flash);
    set(l.bolt);
    set(l.seed);
    // The reference's frame-count envelope, converted to seconds at 60 fps.
    set(10.0 / 60.0);
    set(10.0 / 60.0);
    set(30.0 / 60.0);
    set(25.0 / 60.0);

    _fill(canvas, size, shader);
  }

  // --- sun ------------------------------------------------------------------
  void _paintSunFlare(Canvas canvas, Size size) {
    final shader = shaders[sunFlareAsset];
    if (shader == null || sunTextures.length < 3) return;

    final intensity = frame.sunIntensity;
    if (intensity < 0.02) return;

    // The reference's sun rides a shallow parametric arc driven by the keyframe ring
    // (`SunUniform`'s transition listener), not a linear sweep:
    //
    //   t = (clamp((p - 6) / 4, -0.5, 1.5) - 0.5) * pi/2
    //   x = sin(t) * 0.5
    //   y = 0.5 - (1 - cos(t)) * 0.15
    //
    // Keyframe 4 puts it at the left, 8 at the top, 12 at the right.
    final t = (frame.keyframePosition.clamp(6.0 - 2.0, 6.0 + 6.0) - 6.0) / 4.0;
    final theta = (t.clamp(-0.5, 1.5) - 0.5) * math.pi / 2.0;
    final offsetY = -0.06 + 0.08 * frame.dayAmount;
    final sunX = 0.5 + math.sin(theta) * 0.5;
    final arcY = 0.5 - (1.0 - math.cos(theta)) * 0.15 + offsetY;
    final sunY = 0.5 - arcY;
    final golden = frame.goldenAmount;

    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    set(size.width);
    set(size.height);
    set(sunX);
    set(sunY);
    set(1.0);
    set(0.80 - 0.14 * golden);
    set(0.45 - 0.22 * golden); // ray tint
    set(frame.time);
    set(intensity);
    // The disc survives cloud better than the rays do — it is far brighter.
    set((1.0 - 0.55 * frame.cloudCoverage).clamp(0.0, 1.0));
    set((0.35 + 0.5 * golden) * (1.0 - 0.7 * frame.cloudCoverage));
    // `uAnnulusAlpha` is 0.13 while the sun is up.
    set(0.13 * (1.0 - frame.cloudCoverage));
    // `uCircleAlpha` 1.03, and `uCircleOffset` -0.5.
    set(1.03 * (1.0 - 0.8 * frame.cloudCoverage));
    set(-0.5);
    set((frame.time / 9.0).floorToDouble());
    set((0.7 + 0.3 * golden) * (1.0 - 0.5 * frame.cloudCoverage));
    shader.setImageSampler(0, sunTextures[0]);
    shader.setImageSampler(1, sunTextures[1]);
    shader.setImageSampler(2, sunTextures[2]);

    // The reference renders the sun into a **quarter-resolution** buffer
    // (`new C1502b(ctx, w / 4, h / 4, true)`) and blits it back up with
    // The reference shader, which is just `texture(uTex, vUv) * uOpacity`. All of the
    // softness in its rays and glow comes from that 4x upscale — drawing the
    // shader straight to the screen gives a much harsher, more aliased sun.
    //
    // (the reference shader is the sun's upsample pass, despite the reference notes
    // filing it as an aurora effect.)
    final quarter = Size(
      (size.width / 4).ceilToDouble().clamp(1, double.infinity),
      (size.height / 4).ceilToDouble().clamp(1, double.infinity),
    );
    // The shader's own resolution uniform must match the buffer it draws into.
    shader.setFloat(0, quarter.width);
    shader.setFloat(1, quarter.height);

    final recorder = ui.PictureRecorder();
    ui.Canvas(
      recorder,
    ).drawRect(Offset.zero & quarter, Paint()..shader = shader);
    final picture = recorder.endRecording();
    final small = picture.toImageSync(
      quarter.width.toInt(),
      quarter.height.toInt(),
    );
    picture.dispose();

    canvas.drawImageRect(
      small,
      Offset.zero & quarter,
      Offset.zero & size,
      Paint()
        // Bilinear on the way up is what softens it.
        ..filterQuality = FilterQuality.low
        ..blendMode = BlendMode.plus,
    );
    small.dispose();
  }

  // --- rainbow ------------------------------------------------------------
  void _paintRainbow(Canvas canvas, Size size) {
    final shader = shaders[rainbowAsset];
    if (shader == null || frame.rainbow < 0.002) return;

    final day = frame.dayAmount;
    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    set(size.width);
    set(size.height);
    set(-0.4 + 0.8 * day);
    set(0.2 + 0.6 * day);
    set(0.85); // sun direction
    set(frame.rainbow);
    set(0.5);
    set(0.5);
    set(0.85);
    set(0.22);
    set(4.0);
    // The rainbow shares the sky's narrow frustum so it sits consistently.
    set(20.0 * math.pi / 180.0);
    set(frame.sky.cameraYaw * math.pi / 180.0);

    _fill(canvas, size, shader);
  }
}
