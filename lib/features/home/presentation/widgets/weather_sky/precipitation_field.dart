import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A CPU particle field for rain and snow, drawn with `Canvas.drawAtlas`.
///
/// The reference does not draw its rain with a procedural shader. It runs a GPU compute
/// particle system and draws each drop as an **instanced textured quad** using
/// a motion-blurred streak sprite — which is why a fragment-shader curtain
/// never looks right no matter how it is tuned. Flutter has no compute stage,
/// but `drawAtlas` submits thousands of transformed sprites in a single call,
/// so the same design ports directly with the simulation moved to Dart.
///
/// The behaviour below is a translation of the reference's own shaders, not an
/// invention — see `particle_rain_line_emitter.comp` and `particle_rain.comp`:
///
/// * Particles spawn on a **line** across the top, at a uniformly random point.
/// * Depth comes from `easeInCubic(0, 1, rand)`, which despite its name is
///   `rand⁴` — heavily biased toward zero, so most drops are distant and only
///   a few are close. That distribution is what gives the rain its depth.
/// * Motion is **purely linear and perfectly vertical**: no gravity, no
///   acceleration and — for rain — no wind at all. Speed scales by
///   `mix(0.12, 1, depth)`, so near drops fall about eight times faster.
/// * Lifetime is a **constant 3.0 s** (`setLife(3.0f, 3.0f)`), not a range.
/// * Intensity is expressed almost entirely through **particle count**, not
///   speed: the reference's presets run 576 / 1024 / 1472 / 1792 particles for light /
///   moderate / heavy / storm while `speed` moves only -4.5 → -5.2 (±7%).
/// * Drops composite **additively** at very low alpha — peak per-drop alpha is
///   0.24 and a typical far drop is 0.046. The reference's rain is a faint veil, not an
///   opaque curtain, and drawing it over-strong is the single thing that makes
///   a port look most unlike it.
/// * Opacity scales by `mix(0.3, 2, depth)`, so near drops are ~7x stronger,
///   and each particle fades over its life as `1 - progress²`.
/// * Width scales by `(3 - 2·depth)` — far drops are relatively wider, which
///   keeps them visible at a couple of pixels tall. `drawAtlas` cannot scale
///   non-uniformly, so the atlas carries four width variants (widest first,
///   baked by `tool/build_rain_sprite.py`) and depth indexes them directly.
class PrecipitationField {
  /// Sprite atlas: rain has [rainVariants] width variants side by side.
  final ui.Image atlas;

  /// Number of width variants packed across the atlas (1 for snow).
  final int variants;

  /// Cell size within the atlas, in texels.
  final Size cell;

  /// Maximum particles this field can draw.
  final int capacity;

  /// Whether particles tumble as they fall (snow) or stay upright (rain).
  final bool tumble;

  final _Particle _p;
  final math.Random _random;

  PrecipitationField({
    required this.atlas,
    required this.capacity,
    this.variants = 1,
    required this.cell,
    this.tumble = false,
    int seed = 1,
  }) : _p = _Particle(capacity),
       _random = math.Random(seed);

  bool _seeded = false;

  /// Slowly moving centre for the gust clustering.
  double _gustPhase = 0;

  /// Advances the simulation by [dt] seconds and returns the draw payload.
  ///
  /// [intensity] 0..1 scales how many particles are live; [fallSpeed] is in
  /// widget heights per second at full depth; [wind] tilts the fall (rain
  /// passes zero — the reference's rain is perfectly vertical).
  ({Float32List transforms, Float32List rects, Int32List colors, int count})
  step({
    required Size size,
    required double dt,
    required double intensity,
    required double fallSpeed,
    required double wind,
    required double opacity,
    required Color tint,
    required double sizeMin,
    required double sizeMax,
    required double life,
  }) {
    final live = (capacity * intensity.clamp(0.0, 1.0)).round();
    // Drift the gust centre so the clustering moves across the sky.
    _gustPhase = (_gustPhase + dt * 0.06) % 1.0;

    if (!_seeded) {
      for (var i = 0; i < capacity; i++) {
        _spawn(i, size, sizeMin, sizeMax, life);
        // Pre-warm: scatter the initial ages so the field starts full rather
        // than as one synchronised wave falling from the top.
        _p.age[i] = _random.nextDouble() * _p.life[i];
        _p.y[i] = _random.nextDouble() * (size.height + cell.height);
      }
      _seeded = true;
    }

    // Tilt the streak into the wind; the sprite's long axis follows the fall.
    final tilt = math.atan(wind * 0.6);
    final cosT = math.cos(tilt);
    final sinT = math.sin(tilt);

    var n = 0;
    for (var i = 0; i < live; i++) {
      _p.age[i] += dt;

      final depth = _p.depth[i];
      // The reference's `particle_rain.comp`, verbatim: linear, depth-scaled.
      final speedScale = 0.12 + 0.88 * depth;
      final fall = fallSpeed * size.height * speedScale * dt;
      _p.y[i] += fall;
      _p.x[i] += fall * wind * 0.6;

      // Age is the *only* respawn trigger, as in the reference: a drop that has fallen
      // off the bottom stays dead for the rest of its 3 s life. Recycling it on
      // exit — as an earlier version did — keeps the fastest drops permanently
      // on screen and makes the whole field read as far too quick, because the
      // near drops cross in well under a second.
      if (_p.age[i] >= _p.life[i]) {
        _spawn(i, size, sizeMin, sizeMax, life);
      }

      // `alpha = mix(1, 0, progress²)` from `updateRunState`.
      final progress = (_p.age[i] / _p.life[i]).clamp(0.0, 1.0);
      final lifeAlpha = 1.0 - progress * progress;
      // `alphaScale = mix(0.3, 2, depth)` from `particle_rain_frag_shader`.
      final depthAlpha = 0.3 + 1.7 * depth;
      final a = (lifeAlpha * depthAlpha * 0.4 * opacity).clamp(0.0, 1.0);
      if (a < 0.004) continue;

      // Uniform scale: the sprite's cell height maps to the drop's length.
      final scale = _p.size[i] * size.height / cell.height;

      final o = n * 4;
      if (tumble) {
        final spin = _p.spin[i] * (_p.age[i] + _p.phase[i]);
        _p.transforms[o] = math.cos(spin) * scale;
        _p.transforms[o + 1] = math.sin(spin) * scale;
      } else {
        _p.transforms[o] = cosT * scale;
        _p.transforms[o + 1] = sinT * scale;
      }
      // Anchor at the cell centre so rotation pivots on the drop.
      final ax = cell.width * 0.5;
      final ay = cell.height * 0.5;
      _p.transforms[o + 2] =
          _p.x[i] - (_p.transforms[o] * ax - _p.transforms[o + 1] * ay);
      _p.transforms[o + 3] =
          _p.y[i] - (_p.transforms[o + 1] * ax + _p.transforms[o] * ay);

      // Depth picks the width variant. `particle_rain.comp` makes the quad's
      // width `startSize * 0.4 * (3 - 2*depth)` against a length of
      // `startSize * 3.0`, so a *distant* drop is relatively the widest — and
      // the atlas is baked widest-first, so the index is depth itself.
      final v = variants == 1
          ? 0
          : ((depth * (variants - 1)).round()).clamp(0, variants - 1);
      _p.rects[o] = v * cell.width;
      _p.rects[o + 1] = 0;
      _p.rects[o + 2] = (v + 1) * cell.width;
      _p.rects[o + 3] = cell.height;

      _p.colors[n] = tint.withValues(alpha: a).toARGB32();
      n++;
    }

    return (
      transforms: Float32List.sublistView(_p.transforms, 0, n * 4),
      rects: Float32List.sublistView(_p.rects, 0, n * 4),
      colors: Int32List.sublistView(_p.colors, 0, n),
      count: n,
    );
  }

  void _spawn(int i, Size size, double sizeMin, double sizeMax, double life) {
    // The reference's `easeInCubic(0, 1, r)` is `r⁴` despite the name — most particles
    // land near zero, so the field is mostly distant with a few close drops.
    final r = _random.nextDouble();
    final depth = r * r * r * r;

    _p.depth[i] = depth;
    _p.size[i] = sizeMin + (sizeMax - sizeMin) * depth;
    // The reference sets `setLife(3.0f, 3.0f)` — a constant, not a range.
    _p.life[i] = life;
    _p.age[i] = 0;
    // `particle_rain_line_emitter.comp` spawns uniformly along a line exactly
    // one screen wide, just above the top edge — no gust clustering. The
    // clustering an earlier version added is visible as drifting bands that
    // The reference never shows. Snow keeps the wide, clustered line: it is the only
    // one with wind, so it does need to enter from off-screen.
    if (tumble) {
      final u = (_random.nextDouble() + _random.nextDouble()) * 0.5;
      final drift = (_gustPhase + _random.nextDouble() * 0.35) % 1.0;
      _p.x[i] = ((u + drift) % 1.0 * 1.6 - 0.3) * size.width;
    } else {
      _p.x[i] = _random.nextDouble() * size.width;
    }
    _p.y[i] = -0.025 * size.height - 0.5 * _p.size[i] * size.height;
    _p.spin[i] = (_random.nextDouble() - 0.5) * 1.6;
    _p.phase[i] = _random.nextDouble() * 6.28;
  }
}

/// Struct-of-arrays particle storage — one allocation, reused every frame.
class _Particle {
  final Float64List x;
  final Float64List y;
  final Float64List depth;
  final Float64List size;
  final Float64List life;
  final Float64List age;
  final Float64List spin;
  final Float64List phase;

  final Float32List transforms;
  final Float32List rects;
  final Int32List colors;

  _Particle(int n)
    : x = Float64List(n),
      y = Float64List(n),
      depth = Float64List(n),
      size = Float64List(n),
      life = Float64List(n),
      age = Float64List(n),
      spin = Float64List(n),
      phase = Float64List(n),
      transforms = Float32List(n * 4),
      rects = Float32List(n * 4),
      colors = Int32List(n);
}
