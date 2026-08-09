import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compile-and-paint check for every layer shader in `shaders/`.
///
/// `ui.FragmentProgram.fromAsset` is the only true syntax check for these
/// files — `flutter analyze` never looks at them — so each one is loaded and
/// painted with a full set of uniforms mirroring its slot contract (see
/// `shaders/README.md`). A shader that fails to compile, or whose declared
/// uniform count no longer matches the painter's, fails here.
///
/// Layers that take the sky LUT as a sampler are fed a stand-in image, so
/// this also pins the sampler bindings.
void main() {
  late ui.Image lut;

  setUpAll(() {
    lut = _solidImage(const Color(0xFF6E9BD1), 16, 16);
  });

  final cases = <({String asset, List<double> floats, int samplers})>[
    (
      asset: 'shaders/sky/transmittance.frag',
      floats: [
        64, 64, // uResolution
        5.802, 13.558, 33.1, // uRayleighScatter
        0.650, 1.881, 0.085, // uOzoneAbsorb
        0.008, // uRayleighHeight
        3.996, 4.400, 0.0012, // uMie{Scatter,Absorb,Height}
        0.025, 0.015, // uOzone{Centre,Thickness}
        6.360, 6.460, // radii
      ],
      samplers: 0,
    ),
    (
      asset: 'shaders/sky/sky_lut.frag',
      floats: [
        256, 141, // uResolution
        5.802e-6, 1.3558e-5, 3.31e-5, // uRayleighScatter (1/m)
        6.5e-7, 1.881e-6, 8.5e-8, // uOzoneAbsorb (1/m)
        12, 12, 12, // uSunRadiance
        1, 0, 0, 0, 1, // uPostA..E
        3000, // uRayleighHeight (m)
        5e-6, 0, 3000, 0.05, // uMie{Scatter,Absorb,Height,Asymmetry}
        25000, 8000, // uOzone{Centre,Thickness} (m)
        6360000, 6460000, // radii (m)
        739.98, // uEyeAltitude
        256, 256, // uTransSize
      ],
      samplers: 1,
    ),
    (
      asset: 'shaders/sky/sky_view.frag',
      floats: [
        200, 300, // uResolution
        0.9214, 0.3886, 0.0, // uFrustumA
        0.9980, 0.0628, 0.0, // uFrustumC
        0.5, // uSunAngleY
        7.0, // uTime
        16, 16, // uLutSize
      ],
      samplers: 1,
    ),
    (
      asset: 'shaders/cloud/clouds.frag',
      floats: [
        256, 288, // iSpriteSize
        0.3, 0.7, 0.45, // iLightDir0 (sun)
        0.0, -1.0, 0.2, // iLightDir1 (ground bounce)
        0.0, 1.0, 0.1, // iLightDir2 (ambient)
        0.10, 0.90, 1.0, // iBaseCfg
        0.55, 1.20, 1.0, // iSunCfg
        0.02, 0.70, 0.5, // iGroundCfg
        0.90, 0.80, 0.6, // iAmbientCfg
        0.5, // iSunElevParam
        1.0, // iOpacity
        0.05, 0.23, // edges
        1.0, 0.35, 0.85, // progress, smooth, cloudDepth
        0.8, // iSunIntensity
        0.0, 0.0, // fog, inner
        0.1, // iWhitePer
        16, 16, // iLutSize
        0.9214, 0.3886, 0.0, // iFrustumA
        0.9980, 0.0628, 0.0, // iFrustumC
        256, 288, // iTexSize
      ],
      samplers: 2,
    ),
    (
      asset: 'shaders/weather/sun_flare.frag',
      floats: [
        200, 300, // iResolution
        0.7, 0.35, // iSunPos
        1.0, 0.80, 0.45, // iRayColor
        7.0, // iTime
        0.9, // iOpacity
        1.0, // iDiscAlpha
        0.6, // iRayAlpha
        0.13, // iAnnulusAlpha
        1.03, // iGhostAlpha
        -0.5, // iGhostOffset
        3.0, // iSeed
        0.8, // iGlowAlpha
      ],
      samplers: 3,
    ),
    (
      asset: 'shaders/weather/galaxy.frag',
      floats: [
        200, 300, // iResolution
        0.38, 0.64, 0.16, // iRotation (alpha/theta/phi, in turns)
        0.27, // iFov
        20.0, // iStaticTime
        0.9, // iOpacity
        1.0, // iAlpha
      ],
      samplers: 1,
    ),
    (
      asset: 'shaders/weather/night.frag',
      floats: [
        200, 300, // iResolution
        0.62, 0.68, 0.92, // iGalaxyTint
        7.0, // iTime
        1.0, // iAlpha
        0.0, // iScroll
        0.1, // iCloudCover
        0.0, // iGalaxy
      ],
      samplers: 0,
    ),
    (
      asset: 'shaders/weather/lightning.frag',
      floats: [
        200, 300, // iResolution
        0.70, 0.80, 1.00, // iTopCol
        0.25, 0.32, 0.55, // iBottomCol
        1.0, 1.0, 1.0, // iBoltCol
        0.2, // iTime
        0.8, // iFlash
        1.0, // iBoltAlpha
        3.0, // iSeed
        0.16, // iExpandPath
        0.16, // iBranchShow
        0.50, // iBranchFade
        0.42, // iSubFade
      ],
      samplers: 0,
    ),
    (
      asset: 'shaders/weather/rainbow.frag',
      floats: [
        200, 300, // iResolution
        0.2, -0.4, 0.9, // iSunDir
        0.8, // iOpacity
        0.5, // iRadius
        0.5, // iGap
        0.85, // iBrightness0
        0.22, // iBrightness1
        4.0, // iVisRange
        1.05, 0.525, // iFov, iPitch
      ],
      samplers: 0,
    ),
    (
      asset: 'shaders/weather/rain_on_glass.frag',
      floats: [
        200, 160, // uSize (engine-set at runtime)
        1080, 1080, // uResolution — the reference's fixed frame
        3.0, // uTime
        1.0, 1.0, 2.0, // static size / amount / speed  (the rain set, 4..9)
        1.4, 1.0, 1.3, // running size / amount / speed
        0.6, // uAlpha
      ],
      samplers: 1,
    ),
    (
      asset: 'shaders/weather/card_water.frag',
      floats: [
        200, 160, // iResolution
        0.36, 0.42, 0.49, // iAmbient — a rainy sky sample
        1.0, // iSpecular
        0.15, // iThreshold (0.6 × accum scale)
        1.0, // iAlpha
        14.0, // iHour
      ],
      samplers: 2,
    ),
  ];

  for (final c in cases) {
    test('${c.asset} compiles and paints', () async {
      final program = await ui.FragmentProgram.fromAsset(c.asset);
      final shader = program.fragmentShader();
      for (var i = 0; i < c.floats.length; i++) {
        shader.setFloat(i, c.floats[i]);
      }
      for (var i = 0; i < c.samplers; i++) {
        shader.setImageSampler(i, lut);
      }

      final recorder = ui.PictureRecorder();
      ui.Canvas(
        recorder,
      ).drawRect(const Rect.fromLTWH(0, 0, 200, 300), Paint()..shader = shader);
      final image = recorder.endRecording().toImageSync(200, 300);
      expect(image.width, 200);

      // A layer that renders nothing at all usually means a uniform slot
      // shifted; require at least one non-transparent pixel.
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final px = bytes!.buffer.asUint8List();
      var opaque = 0;
      for (var i = 3; i < px.length; i += 4) {
        if (px[i] > 0) opaque++;
      }
      expect(opaque, greaterThan(0), reason: '${c.asset} painted nothing');
    });
  }
}

ui.Image _solidImage(Color color, int width, int height) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  return recorder.endRecording().toImageSync(width, height);
}
