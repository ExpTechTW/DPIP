import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe.dart';
import 'package:flutter/material.dart';

/// Bakes and caches the two atmospheric lookup tables the sky is drawn from.
///
/// This is what lets a physically-integrated sky run at 60 fps on a phone, and
/// it is the reference engine's own design: ray-marching scattering per pixel per
/// frame is far too expensive, so the integral is evaluated into small
/// textures and the per-frame shader becomes a lookup.
///
/// 1. [transmittance] (256×256) — how much sunlight survives to any altitude
///    and sun angle. Depends only on the medium.
/// 2. [skyView] (256×141) — the sky's radiance, with the sun's position along
///    its arc on the u axis. Both sizes are the engine's own.
///
/// The engine re-bakes only when the weather or time slot changes, gated on a
/// dirty flag; [update] does the same by comparing the resolved keyframe.
class SkyLutCache {
  final ui.FragmentShader _transmittanceShader;
  final ui.FragmentShader _skyLutShader;

  ui.Image? _transmittance;
  ui.Image? _skyView;
  ResolvedSky? _baked;

  /// The baked LUT's raw RGBA rows, read back once per bake so pixel-
  /// independent probes (the cloud shader's base/haze colours) can be sampled
  /// on the CPU instead of the GPU fetching them on every cloud pixel.
  Uint8List? _skyViewBytes;

  /// The LUT column at the keyframe's sun angle, CPU-extracted (1×141). The
  /// cloud shader samples this instead of the full 2D LUT — its u is the
  /// constant sun angle, so horizontal filtering happens once at bake time and
  /// every probe costs a 2-tap vertical fetch instead of a 4-tap bilinear.
  ui.Image? _skyColumn;

  /// The screen sky gradient (4×1024), rebuilt whenever the keyframe re-bakes.
  /// The sky pass is a pure vertical gradient of a fixed LUT column, so it is
  /// precomputed here and drawn as one stretched image per frame instead of
  /// running a full-screen shader.
  ui.Image? _skyGradient;

  /// Takes the stage-1 and stage-2 bake shaders, in pipeline order. They stay
  /// owned by the caller; [dispose] only releases the baked images.
  SkyLutCache(this._transmittanceShader, this._skyLutShader);

  /// The current sky-view LUT, or `null` before the first bake.
  ui.Image? get skyView => _skyView;

  /// The LUT column at the keyframe's sun angle, for the cloud shader's
  /// probes — or `null` before the first bake's readback completes.
  ui.Image? get skyColumn => _skyColumn;

  /// The screen sky gradient the backdrop draws each frame, or `null` before
  /// the first readback completes.
  ui.Image? get skyGradient => _skyGradient;

  /// Size of [skyView] in texels, for the samplers' manual bilinear filter.
  static const Size skyViewSize = Size(256, 141);

  /// The sky colour the reference's panel water sees.
  ///
  /// The reference shader's `uBgLightTex` is the 256×141 sky-view LUT (the cloud
  /// shader indexes the same texture with the LUT's own `(y·256−115)/141`
  /// layout, and the city scene passes the LUT in directly); the water pass
  /// samples it at the panel's on-screen `vUv`, i.e. a lower-middle row.
  /// Published here as one colour — the LUT row the panel band covers — every
  /// time the LUT re-bakes, so the water is lit by the *same sky it falls
  /// out of*, experimental overrides included.
  static final ValueNotifier<Color?> panelAmbient = ValueNotifier(null);

  /// Where the panel water samples the LUT: `vUv` ≈ (0.5, 0.7) — the card
  /// sits in the lower third of the screen.
  static const Offset _ambientSample = Offset(0.5, 0.7);

  /// Re-bakes if [sky] differs from what is cached. Returns whether it did.
  bool update(ResolvedSky sky) {
    final previous = _baked;
    if (previous != null && !previous.needsRebake(sky)) return false;

    // The medium changes with almost every keyframe, so both stages re-bake
    // together; splitting them would save little and risk them disagreeing.
    _transmittance?.dispose();
    _transmittance = _bakeTransmittance(sky);

    _skyView?.dispose();
    _skyView = _bakeSkyView(sky, _transmittance!);
    _baked = sky;
    _publishReadback(_skyView!, sky);
    return true;
  }

  /// Reads the LUT rows back — async and once per bake, never per frame. The
  /// buffer is kept so [skyAt] can serve the pixel-independent cloud probes;
  /// the panel-water ambient row, the cloud shader's column and the screen
  /// gradient are all derived from the same read.
  void _publishReadback(ui.Image skyView, ResolvedSky sky) {
    skyView
        .toByteData(format: ui.ImageByteFormat.rawRgba)
        .then((data) {
          if (data == null) return;
          _skyViewBytes = data.buffer.asUint8List();
          final bytes = _skyViewBytes!;
          final x = (_ambientSample.dx * (skyViewSize.width - 1)).round();
          final y = (_ambientSample.dy * (skyViewSize.height - 1)).round();
          final o = (y * skyViewSize.width.toInt() + x) * 4;
          panelAmbient.value = Color.fromARGB(
            255,
            bytes[o],
            bytes[o + 1],
            bytes[o + 2],
          );
          _bakeSkyColumn(sky);
          _bakeSkyGradient(sky);
        })
        .catchError((Object _) {});
  }

  /// Extracts the LUT column at the keyframe's sun angle into a 1×141 image.
  ///
  /// The horizontal tap pair and blend factor are the shaders' own — the same
  /// texel-centre convention as `sampleLut`, evaluated once on the CPU. A GPU
  /// 2D bilinear at the constant u then reduces to the identical 2-tap
  /// vertical fetch, so the cloud lighting is unchanged.
  void _bakeSkyColumn(ResolvedSky sky) {
    final bytes = _skyViewBytes;
    if (bytes == null) return;
    const width = SkyConstants.skyLutWidth;
    const height = SkyConstants.skyLutHeight;
    final sx = sky.sunAngleY.clamp(0.0, 1.0) * width - 0.5;
    final x0 = sx.floor();
    final fx = sx - x0;
    final xa = x0.clamp(0, width - 1);
    final xb = (x0 + 1).clamp(0, width - 1);

    final image = _rasterize(1, height, (canvas) {
      for (var r = 0; r < height; r++) {
        final o = r * width * 4;
        final ca = o + xa * 4;
        final cb = o + xb * 4;
        canvas.drawRect(
          Rect.fromLTWH(0, r.toDouble(), 1, 1),
          Paint()
            ..color = Color.fromARGB(
              255,
              (bytes[ca] + (bytes[cb] - bytes[ca]) * fx).round().clamp(0, 255),
              (bytes[ca + 1] + (bytes[cb + 1] - bytes[ca + 1]) * fx)
                  .round()
                  .clamp(0, 255),
              (bytes[ca + 2] + (bytes[cb + 2] - bytes[ca + 2]) * fx)
                  .round()
                  .clamp(0, 255),
            ),
        );
      }
    });
    _skyColumn?.dispose();
    _skyColumn = image;
  }

  /// Bakes the screen sky gradient — a 4×1024 image whose rows are the exact
  /// colour the old `sky_view.frag` screen pass produced at that screen
  /// position, evaluated on the CPU from the frustum and the LUT column.
  ///
  /// The shader's per-pixel `normalize → asin → sqrt` chain and its 4-tap
  /// bilinear are replaced by a piecewise-linear ramp of 1024 exact samples,
  /// drawn stretched once per frame. Near the horizon — where the mapping is
  /// steepest — a sample every ~2px keeps the error below one 8-bit level.
  /// The reference's sub-texel dither is dropped: it existed to hide LUT row
  /// seams, and this ramp is smooth by construction.
  void _bakeSkyGradient(ResolvedSky sky) {
    final bytes = _skyViewBytes;
    if (bytes == null) return;
    const width = 4;
    const rows = 1024;
    final fr = buildFrustum(sky.cameraYaw);
    final ax = fr.top[0];
    final ay = fr.top[1];
    final bx = fr.bottom[0];
    final by = fr.bottom[1];
    final u = sky.sunAngleY.clamp(0.0, 1.0);

    final image = _rasterize(width, rows, (canvas) {
      for (var r = 0; r < rows; r++) {
        final t = (r + 0.5) / rows;
        final x = ax + (bx - ax) * t;
        final y = ay + (by - ay) * t;
        final len = math.sqrt(x * x + y * y);
        final theta = math.asin((y / len).clamp(-1.0, 1.0));
        final v =
            0.5 + 0.5 * theta.sign * math.sqrt(theta.abs() / (math.pi / 2.0));
        final lutV = ((v * 256.0 - 115.0) / 141.0).clamp(0.0, 1.0);
        final color = skyAt(u, lutV) ?? const Color(0xFF3F6DAE);
        canvas.drawRect(
          Rect.fromLTWH(0, r.toDouble(), width.toDouble(), 1),
          Paint()..color = color,
        );
      }
    });
    _skyGradient?.dispose();
    _skyGradient = image;
  }

  /// The baked sky's colour at LUT coordinate ([u], [v]), bilinear — the same
  /// manual filtering the shaders' `sampleLut` does (Flutter binds samplers
  /// NEAREST), and in the same texel-centre convention: `uv · size − 0.5`,
  /// so the first tap lands on a texel's centre and out-of-range indices
  /// clamp to the edge texel. `null` before the first readback completes.
  ///
  /// Lives here because [sky_view.frag]'s u axis *is* the keyframe's
  /// `sunAngleY`, so a probe's u is known on the CPU; probes whose picker is
  /// pixel-independent (the cloud shader's base and haze colours) are then
  /// baked once per keyframe rather than fetched on every cloud pixel.
  Color? skyAt(double u, double v) {
    final bytes = _skyViewBytes;
    if (bytes == null) return null;
    const width = SkyConstants.skyLutWidth;
    const height = SkyConstants.skyLutHeight;
    Color texel(int px, int py) {
      final o = (py * width + px) * 4;
      return Color.fromARGB(255, bytes[o], bytes[o + 1], bytes[o + 2]);
    }

    final sx = u.clamp(0.0, 1.0) * width - 0.5;
    final x0 = sx.floor();
    final fx = sx - x0;
    final sy = v.clamp(0.0, 1.0) * height - 0.5;
    final y0 = sy.floor();
    final fy = sy - y0;
    int px(int i) => i.clamp(0, width - 1);
    int py(int j) => j.clamp(0, height - 1);

    final c00 = texel(px(x0), py(y0));
    final c10 = texel(px(x0 + 1), py(y0));
    final c01 = texel(px(x0), py(y0 + 1));
    final c11 = texel(px(x0 + 1), py(y0 + 1));
    return Color.lerp(Color.lerp(c00, c10, fx), Color.lerp(c01, c11, fx), fy)!;
  }

  ui.Image _bakeTransmittance(ResolvedSky sky) {
    final shader = _transmittanceShader;
    var i = 0;
    void set(double v) => shader.setFloat(i++, v);

    set(SkyConstants.transmittanceWidth.toDouble());
    set(SkyConstants.transmittanceHeight.toDouble());
    set(SkyConstants.rayleighScatter.$1);
    set(SkyConstants.rayleighScatter.$2);
    set(SkyConstants.rayleighScatter.$3);
    set(SkyConstants.ozoneAbsorb.$1);
    set(SkyConstants.ozoneAbsorb.$2);
    set(SkyConstants.ozoneAbsorb.$3);
    set(sky.rayleighHeight);
    set(sky.mieScatter);
    set(sky.mieAbsorb);
    set(sky.mieHeight);
    set(SkyConstants.ozoneCentre);
    set(sky.ozoneThickness);
    set(SkyConstants.planetRadius);
    set(SkyConstants.atmosphereRadius);

    return _rasterise(
      shader,
      SkyConstants.transmittanceWidth,
      SkyConstants.transmittanceHeight,
    );
  }

  ui.Image _bakeSkyView(ResolvedSky sky, ui.Image transmittance) {
    final shader = _skyLutShader;
    var i = 0;
    void set(double v) => shader.setFloat(i++, v);

    set(SkyConstants.skyLutWidth.toDouble());
    set(SkyConstants.skyLutHeight.toDouble());
    set(SkyConstants.rayleighScatter.$1);
    set(SkyConstants.rayleighScatter.$2);
    set(SkyConstants.rayleighScatter.$3);
    set(SkyConstants.ozoneAbsorb.$1);
    set(SkyConstants.ozoneAbsorb.$2);
    set(SkyConstants.ozoneAbsorb.$3);
    set(sky.sunIntensity);
    set(sky.sunIntensity);
    set(sky.sunIntensity);
    set(sky.postColor.$1);
    set(sky.postColor.$2);
    set(sky.postColor.$3);
    set(sky.postColor.$4);
    set(sky.postColor.$5);
    set(sky.rayleighHeight);
    set(sky.mieScatter);
    set(sky.mieAbsorb);
    set(sky.mieHeight);
    set(sky.mieAsymmetry);
    set(SkyConstants.ozoneCentre);
    set(sky.ozoneThickness);
    set(SkyConstants.planetRadius);
    set(SkyConstants.atmosphereRadius);
    set(SkyConstants.eyeAltitude);
    set(SkyConstants.transmittanceWidth.toDouble());
    set(SkyConstants.transmittanceHeight.toDouble());
    shader.setImageSampler(0, transmittance);

    return _rasterise(
      shader,
      SkyConstants.skyLutWidth,
      SkyConstants.skyLutHeight,
    );
  }

  static ui.Image _rasterise(ui.FragmentShader shader, int width, int height) =>
      _rasterize(
        width,
        height,
        (canvas) => canvas.drawRect(
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          Paint()..shader = shader,
        ),
      );

  /// Rasterises [draw] into a small GPU-resident image. Synchronous — no CPU
  /// round trip, which is what makes an in-frame bake affordable.
  static ui.Image _rasterize(
    int width,
    int height,
    void Function(ui.Canvas) draw,
  ) {
    final recorder = ui.PictureRecorder();
    draw(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return image;
  }

  /// Releases the baked images. The shaders are owned by the caller.
  void dispose() {
    _transmittance?.dispose();
    _skyView?.dispose();
    _skyGradient?.dispose();
    _skyColumn?.dispose();
    _transmittance = null;
    _skyView = null;
    _skyGradient = null;
    _skyColumn = null;
    _skyViewBytes = null;
    _baked = null;
  }
}

/// The view frustum's top and bottom rays, as the engine builds them.
///
/// Two properties here are load-bearing for the look and are kept deliberately:
///
///   • A fixed 20° vertical field of view. The visible sky is a narrow ~19°
///     band, not a dome — widening it is the quickest way to change the look.
///     There is nothing to aspect-correct: the sky has no azimuthal variation,
///     so only the vertical extent means anything.
///   • The camera's 0.017 height offset is baked into the corners and the
///     shader normalises them from the world origin rather than the camera, so
///     that offset acts as a permanent upward pitch bias of about 9.7°.
typedef Frustum = ({List<double> top, List<double> bottom});

/// Builds the frustum for a keyframe's `cameraYaw` (degrees).
Frustum buildFrustum(double cameraYawDeg) {
  const nearZ = 0.1;
  const eyeY = 0.017;
  const fovDeg = 20.0;

  final fTan = nearZ * math.tan((fovDeg / 2.0) * math.pi / 180.0);
  final p = cameraYawDeg * math.pi / 180.0;
  final cp = math.cos(p);
  final sp = math.sin(p);

  return (
    top: [nearZ * cp - fTan * sp, eyeY + nearZ * sp + fTan * cp, 0.0],
    bottom: [nearZ * cp + fTan * sp, eyeY + nearZ * sp - fTan * cp, 0.0],
  );
}
