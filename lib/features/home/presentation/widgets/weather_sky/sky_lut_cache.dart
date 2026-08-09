import 'dart:math' as math;
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

  /// Takes the stage-1 and stage-2 bake shaders, in pipeline order. They stay
  /// owned by the caller; [dispose] only releases the baked images.
  SkyLutCache(this._transmittanceShader, this._skyLutShader);

  /// The current sky-view LUT, or `null` before the first bake.
  ui.Image? get skyView => _skyView;

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
    _publishPanelAmbient(_skyView!);
    return true;
  }

  /// Reads the ambient row back — async and once per bake, never per frame.
  void _publishPanelAmbient(ui.Image skyView) {
    final x = (_ambientSample.dx * (skyViewSize.width - 1)).round();
    final y = (_ambientSample.dy * (skyViewSize.height - 1)).round();
    skyView
        .toByteData(format: ui.ImageByteFormat.rawRgba)
        .then((data) {
          if (data == null) return;
          final o = (y * skyViewSize.width.toInt() + x) * 4;
          final px = data.buffer.asUint8List();
          panelAmbient.value = Color.fromARGB(255, px[o], px[o + 1], px[o + 2]);
        })
        .catchError((Object _) {});
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

  static ui.Image _rasterise(ui.FragmentShader shader, int width, int height) {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..shader = shader,
    );
    final picture = recorder.endRecording();
    // Synchronous and GPU-resident — no CPU round trip, which is what makes
    // an in-frame bake affordable.
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return image;
  }

  /// Releases the baked images. The shaders are owned by the caller.
  void dispose() {
    _transmittance?.dispose();
    _skyView?.dispose();
    _transmittance = null;
    _skyView = null;
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
