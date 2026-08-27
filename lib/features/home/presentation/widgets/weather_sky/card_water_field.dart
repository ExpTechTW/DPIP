import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Rain landing on a card and pooling along its top edge — a CPU port of
/// The reference's **panel** water.
///
/// This is not the same system as the water on the temperature digits
///, and porting that one by mistake produces the opposite effect.
/// The digits build a collision mesh from a bitmap and *throw water upward* off
/// whatever faces the sky. The panel does not:
///
/// * The card is a plain `PolygonShape.setAsBox(halfWidth, 20)` — one big
///   rectangle, no mesh, no ray-casts.
/// * the emitter launches every drop **downward**: `Vec2((rand - 0.5) * spread,
///   -fallSpeed)`. Nothing is ever thrown up.
/// * The fixture is `restitution = 0`, `friction = 10`. Drops do not bounce and
///   barely slide — they stop dead where they land and pool.
///
/// So what the eye reads as a splash on the card's upper edge is water falling
/// from above, being caught by the edge, and accumulating there until each
/// drop's lifetime expires. The engine spawns them 0.91 world units above the
/// edge, which at its scale is a third of the screen up.
///
/// Scale: the reference builds the projection as `translate(-1,-1) · scale(2/aspect3,
/// 2/3)`, so the world is `3.0` units tall and **3 world units span the screen
/// height**. (The digit painter uses a different scale entirely — 40 units to
/// the screen *width* — which is why its numbers cannot be reused here.)
///
/// The field only accumulates coverage. Turning that into water is
/// `shaders/weather/card_water.frag`, which is where the reference's threshold and
/// lighting live; drawing these particles directly would show the dots the
/// metaball is supposed to fuse.
///
/// [update]'s [CardWaterSurface] parameter is a *third* variant, not the
/// digit system above: it keeps the panel's own falling-and-pooling model —
/// downward launch, no bounce, no mesh ray-casts — and only replaces the
/// single flat `topEdge` with a per-column one, so the pool follows whatever
/// silhouette is actually there (text, an icon) instead of a rectangle around
/// it. `topEdge` is still what a flat card uses; a surface is additive.
class CardWaterField {
  /// The per-drop sprites: positive and negative halves of the signed normal.
  ///
  /// The reference shader writes the **signed** sphere normal into RGBA16F; 8-bit
  /// surfaces are unsigned, so the sign is split across two buffers —
  /// [spritePos] carries `(max(n,0), kernel)` and [spriteNeg] `max(−n, 0)` —
  /// and the composite reassembles `Σn = pos − neg`. Mutable so the procedural
  /// stand-ins can be swapped for sprites baked from the real extracted
  /// textures the moment their async decode lands.
  ui.Image spritePos;
  ui.Image spriteNeg;

  /// Hard cap on live drops — `B.a.run()` clamps each world at 200.
  final int capacity;

  final _Drops _p;
  final math.Random _random;

  double _stepCarry = 0;
  int _stepIndex = 0;
  int _live = 0;

  CardWaterField({
    required this.spritePos,
    required this.spriteNeg,
    this.capacity = 200,
    int seed = 7,
  }) : _p = _Drops(capacity),
       _random = math.Random(seed);

  /// Drops currently alive.
  int get liveCount => _live;

  /// Live positions relative to the card's top-left; negative y is above it.
  /// Runs the emitter alone, with no world step behind it.
  ///
  /// The emitter's output is not observable through [update]: the reference's timer
  /// task emits and *then* steps, and a fresh drop crosses the 15 px spawn gap
  /// in well under one 1/60 s step — so by the time a tick returns, the group
  /// is already parked on the edge. This is the seam that lets a test see what
  /// the emitter actually produced.
  @visibleForTesting
  void debugEmit({
    required double width,
    required double screenHeight,
    CardWaterPreset preset = CardWaterPreset.moderate,
    double topEdge = 0,
    CardWaterSurface? surface,
  }) => _emit(width, screenHeight / _worldHeight, preset, topEdge, surface);

  @visibleForTesting
  List<Offset> get debugPositions => [
    for (var i = 0; i < _live; i++) Offset(_p.x[i], _p.y[i]),
  ];

  /// Live velocities, logical pixels per second.
  @visibleForTesting
  List<Offset> get debugVelocities => [
    for (var i = 0; i < _live; i++) Offset(_p.vx[i], _p.vy[i]),
  ];

  /// Drops resting on or near the edge, within one particle diameter of it.
  ///
  /// There is no "settled" flag any more: every drop stays in the solver, which
  /// is what lets the pile push new arrivals back out.
  @visibleForTesting
  int settledCount(
    double screenHeight, {
    double topEdge = 0,
    CardWaterSurface? surface,
  }) {
    final band = 2 * _particleRadius * screenHeight / _worldHeight;
    var n = 0;
    for (var i = 0; i < _live; i++) {
      final edge = surface?.heightAt(_p.x[i]) ?? topEdge;
      if (_p.y[i] > edge - band) n++;
    }
    return n;
  }

  /// Height of the particle render texture, in buffer pixels.
  ///
  /// The reference's FBO and its point sizes are both expressed against
  /// this, so it is the unit that makes a drop the same fraction of the screen
  /// on every device.
  static const double bufferHeight = 800;

  /// The wall-clock period of the emitter's timer: the reference builds an
  /// `Timer.schedule(task, 0, 20)` — **50 Hz**, not 60.
  static const double emitterTick = 0.020;

  /// What one tick hands the solver: `world.step(0.016666668f, 6, 2, 5)`.
  ///
  /// The two together are the whole clock. A 20 ms timer advancing 1/60 s of
  /// simulated time means the panel water runs at **0.833x real time**, which
  /// is most of why the reference's drops crawl down the edge instead of snapping to
  /// it, and lifetimes/spawn intervals are all counted in this simulated time.
  static const double _worldStep = 1 / 60;

  /// How much room a field needs *above* the card, in logical pixels.
  ///
  /// Covers the short drop from the spawn line plus the spray thrown back up by
  /// the solver, which goes higher than the spawn point does.
  static double spawnHeadroom(double screenHeight) =>
      math.max(3 * spawnHeight * screenHeight / _worldHeight, 48);

  /// Height above the card's top edge that drops are born at, in world units.
  ///
  /// The emitter's spawn y is 0.91 for every grade, but that is an
  /// **absolute** world y: the collision box sits 19.148 units below the panel
  /// line with a half-height of 20, so the card's top face is 0.852 above it
  /// and the spawn line sits only `0.91 - 0.852` above that. Reading 0.91 as a relative height — as an
  /// earlier version did — starts drops a third of a screen up instead of a
  /// centimetre, and the whole descent then happens off-card.
  static const double spawnHeight = 0.91 - _boxTopOffset;

  /// `setAsBox(halfWidth, 20)`, centred 19.148 below the panel line.
  static const double _boxTopOffset = 20.0 - 19.148;

  /// World units to the screen height.
  static const double _worldHeight = 3.0;

  /// Advances the simulation by [dt] seconds.
  ///
  /// [width] is the card, [screenHeight] the scale the engine's world units are
  /// defined against, and [topEdge] the y (in card space) drops land on — 0 is
  /// the card's own top. [surface], when given, overrides [topEdge] per
  /// column instead of everywhere at once — see [CardWaterSurface].
  void update(
    double dt, {
    required double width,
    required double screenHeight,
    required double intensity,
    required CardWaterPreset preset,
    double topEdge = 0,
    double gravityScale = 1.0,
    CardWaterSurface? surface,
  }) {
    if (dt <= 0 || width <= 0 || screenHeight <= 0) return;
    // A backgrounded tab must not replay minutes of physics on resume.
    final elapsed = math.min(dt, 0.1);
    final unit = screenHeight / _worldHeight;

    // The timer is the clock, not the frame. Each 20 ms tick runs the emitter
    // and then one world step, in that order — the reference's `TimerTask.run()`
    // calls `m(particleSystem)` before `world.step(…)`. Driving the solver off
    // the frame's own dt instead, as an earlier version did, runs the physics
    // at 1.2x the reference's rate and makes every lifetime and spawn interval mean
    // something different from what the presets say.
    _stepCarry += elapsed;
    final ticks = _stepCarry ~/ emitterTick;
    _stepCarry -= ticks * emitterTick;

    for (var s = 0; s < ticks; s++) {
      _stepIndex++;
      // the emitter: one group every `interval` ticks, nothing in between.
      if (_stepIndex % preset.interval == 0 && intensity > 0.001) {
        _emit(width, unit, preset, topEdge, surface);
      }

      // Five particle iterations per world step, each on `_worldStep/5`.
      // Everything in `_solveIteration` is one iteration of
      // `b2ParticleSystem::Solve` with the stages plain water never reaches
      // (viscous, powder, tensile, rigid) removed.
      const sub = _worldStep / _particleIterations;
      for (var it = 0; it < _particleIterations; it++) {
        _solveIteration(sub, unit, preset, topEdge, gravityScale, surface);
      }

      for (var i = 0; i < _live; i++) {
        _p.age[i] += _worldStep;
      }
      _compact();
    }
  }

  /// `world.step(..., particleIterations = 5)`.
  static const int _particleIterations = 5;

  /// One `b2ParticleSystem` particle iteration.
  ///
  /// The order is the engine's, and it is load-bearing: SolveForce (the
  /// reaction SolveCollision stored last iteration) → SolveGravity →
  /// contacts → ComputeWeight → SolvePressure → SolveDamping → LimitVelocity
  /// → SolveCollision → integrate. An earlier version integrated first and
  /// then clamped positions, which skipped the collision velocity fix
  /// entirely.
  ///
  /// Two facts here were verified against the engine and both had been got
  /// wrong: the fixture's **friction and restitution are never read by the
  /// particle solver** (particle-vs-body response is pressure + damping +
  /// collision, nothing else), and the body-contact distance is **signed** —
  /// SolveCollision parks a particle's centre at `surface + b2_linearSlop`,
  /// which is inside its own radius, so the contact survives instead of
  /// vanishing the moment the drop lands. Clamping that distance at zero, as
  /// an earlier version did, made the pile impossible.
  ///
  /// A parked particle's *body* weight is only `1 - 0.005/0.02` = 0.75, never
  /// above 1. The `w > 1` SolvePressure needs comes from ComputeWeight's
  /// **sum** — the body contact plus every neighbour within a diameter — which
  /// is why water piles only once drops start landing on each other, and why
  /// the pile is the port's one and only source of rebound.
  void _solveIteration(
    double dt,
    double unit,
    CardWaterPreset preset,
    double topEdge,
    double gravityScale,
    CardWaterSurface? surface,
  ) {
    if (_live == 0) return;
    final invDt = 1.0 / dt;
    final diameter = 2 * _particleRadius * unit;
    final slop = _b2LinearSlop * unit;

    // Scratch reused across iterations: this runs five times per 20 ms tick,
    // and allocating four fresh Float32Lists each pass (a thousand a second
    // while it rains) is GC churn for buffers whose lifetime is one call.
    _ensureScratch();
    final edge = _edgeScratch;
    final weight = _weightScratch;
    final bodyW = _bodyWScratch;
    final accum = _accumScratch;
    weight.fillRange(0, _live, 0);
    bodyW.fillRange(0, _live, 0);

    // Resolved once per iteration, not re-looked-up per section: positions
    // (and so each particle's column) are fixed until Integrate, at the very
    // end. `double.infinity` for a column with nothing solid in it compares
    // false against every finite y below, which is what lets the rest of this
    // function stay unaware a surface is not flat at all — see
    // [CardWaterSurface].
    for (var i = 0; i < _live; i++) {
      edge[i] = surface?.heightAt(_p.x[i]) ?? topEdge;
    }

    // SolveForce — consumes what SolveCollision stored.
    if (_hasForce) {
      for (var i = 0; i < _live; i++) {
        _p.vx[i] += dt * _particleInvMass * _p.fx[i];
        _p.vy[i] += dt * _particleInvMass * _p.fy[i];
        _p.fx[i] = 0;
        _p.fy[i] = 0;
      }
      _hasForce = false;
    }

    // SolveGravity.
    final gravity = preset.gravity * gravityScale * unit;
    for (var i = 0; i < _live; i++) {
      _p.vy[i] += gravity * dt;
    }

    // Contacts. Screen y grows downward, so "above the edge" is y < edge[i]
    // and the signed surface distance is edge[i] - y.
    for (var i = 0; i < _live; i++) {
      final d = edge[i] - _p.y[i];
      if (d < diameter) {
        bodyW[i] = 1.0 - d / diameter; // > 1 once the centre is inside
        weight[i] += bodyW[i];
      }
    }
    _buildPairs(diameter, weight);
    final pairCount = _pairCount;

    // SolvePressure.
    final criticalVelocity = diameter * invDt;
    final criticalPressure = _density * criticalVelocity * criticalVelocity;
    final ppw = preset.pressure * criticalPressure;
    final maxPressure = _b2MaxParticlePressure * criticalPressure;
    final vpp = dt / (_density * diameter);
    for (var i = 0; i < _live; i++) {
      accum[i] = math.min(
        ppw * math.max(0.0, weight[i] - _b2MinParticleWeight),
        maxPressure,
      );
    }
    // Body contacts first; `ppw * w` is the wall repulsion with no
    // particle-particle counterpart. The normal points out of the surface,
    // i.e. up the screen.
    for (var i = 0; i < _live; i++) {
      if (bodyW[i] == 0) continue;
      _p.vy[i] -= vpp * bodyW[i] * (accum[i] + ppw * bodyW[i]);
    }
    for (var k = 0; k < pairCount; k++) {
      final a = _pairA[k], b = _pairB[k];
      final nx = _pairNx[k], ny = _pairNy[k];
      final f = vpp * _pairW[k] * (accum[a] + accum[b]);
      _p.vx[a] -= f * nx;
      _p.vy[a] -= f * ny;
      _p.vx[b] += f * nx;
      _p.vy[b] += f * ny;
    }

    // SolveDamping.
    final quad = 1.0 / criticalVelocity;
    for (var i = 0; i < _live; i++) {
      if (bodyW[i] == 0) continue;
      // `UpdateBodyContacts` stores `contact.normal = -n`, pointing from the
      // particle **into** the body — screen +y here, not up. With
      // `v = bodyVelocity(0) - particleVelocity`, `vn = dot(v, n)` is `-vy`,
      // so the gate below selects drops still *approaching* the face and the
      // update reads `vy *= (1 - damp)`.
      //
      // Taking the normal as up instead flips both: the gate fires on drops
      // already leaving, and `vy += damp * vn` becomes `vy *= (1 + damp)` — an
      // amplifier of up to 1.75x per sub-step, five sub-steps a step. That is
      // a geometric runaway, and it is what threw every drop clean out of the
      // render buffer to be clipped at the same line, which reads as a bounce
      // height that never varies.
      final vn = -_p.vy[i];
      if (vn >= 0) continue;
      final damp = math.max(
        _dampingStrength * bodyW[i],
        math.min(-quad * vn, 0.5),
      );
      _p.vy[i] += damp * vn;
    }
    for (var k = 0; k < pairCount; k++) {
      final a = _pairA[k], b = _pairB[k];
      final nx = _pairNx[k], ny = _pairNy[k];
      final vn = (_p.vx[b] - _p.vx[a]) * nx + (_p.vy[b] - _p.vy[a]) * ny;
      if (vn >= 0) continue;
      final damp = math.max(
        _dampingStrength * _pairW[k],
        math.min(-quad * vn, 0.5),
      );
      final f = damp * vn;
      _p.vx[a] += f * nx;
      _p.vy[a] += f * ny;
      _p.vx[b] -= f * nx;
      _p.vy[b] -= f * ny;
    }

    // LimitVelocity — one diameter of travel per sub-step.
    final maxV2 = criticalVelocity * criticalVelocity;
    for (var i = 0; i < _live; i++) {
      final v2 = _p.vx[i] * _p.vx[i] + _p.vy[i] * _p.vy[i];
      if (v2 <= maxV2) continue;
      final sc = math.sqrt(maxV2 / v2);
      _p.vx[i] *= sc;
      _p.vy[i] *= sc;
    }

    // SolveCollision. `b2PolygonShape::RayCast` returns false from inside, so
    // this only catches a particle crossing *into* the box this sub-step; an
    // already-embedded one is pushed back out by the pressure term alone.
    for (var i = 0; i < _live; i++) {
      if (_p.y[i] >= edge[i] || _p.vy[i] <= 0) continue;
      final travel = _p.vy[i] * dt;
      final frac = (edge[i] - _p.y[i]) / travel;
      if (frac < 0 || frac > 1) continue;
      final newX = _p.x[i] + frac * dt * _p.vx[i];
      final newY = edge[i] - slop;
      final oldVx = _p.vx[i];
      final oldVy = _p.vy[i];
      _p.vx[i] = invDt * (newX - _p.x[i]);
      _p.vy[i] = invDt * (newY - _p.y[i]);
      _p.fx[i] += invDt * _particleMass * (oldVx - _p.vx[i]);
      _p.fy[i] += invDt * _particleMass * (oldVy - _p.vy[i]);
      _hasForce = true;
    }

    // Integrate.
    for (var i = 0; i < _live; i++) {
      _p.x[i] += _p.vx[i] * dt;
      _p.y[i] += _p.vy[i] * dt;
    }
  }

  bool _hasForce = false;

  /// Per-iteration scratch, grown to the live population on demand — see the
  /// note at the top of [_solveIteration].
  Float32List _edgeScratch = Float32List(0);
  Float32List _weightScratch = Float32List(0);
  Float32List _bodyWScratch = Float32List(0);
  Float32List _accumScratch = Float32List(0);

  void _ensureScratch() {
    if (_edgeScratch.length >= _live) return;
    _edgeScratch = Float32List(_live);
    _weightScratch = Float32List(_live);
    _bodyWScratch = Float32List(_live);
    _accumScratch = Float32List(_live);
  }

  /// LiquidFun's b2Settings, and the derived particle mass.
  static const double _b2LinearSlop = 0.005;
  static const double _b2MinParticleWeight = 1.0;
  static const double _b2MaxParticlePressure = 0.25;
  static const double _density = 1.0;
  static const double _dampingStrength = 1.0;

  /// `GetParticleInvMass()` = 1/(density · particleStride²), stride = 0.75·d.
  static const double _particleInvMass =
      1.0 /
      (_density *
          _b2ParticleStride *
          2 *
          _particleRadius *
          _b2ParticleStride *
          2 *
          _particleRadius);
  static const double _particleMass = 1.0 / _particleInvMass;
  static const double _b2ParticleStride = 0.75;

  /// Contact pairs within one diameter, with their weights and normals, into
  /// [_pairA]…[_pairNy] and [_pairCount].
  ///
  /// Runs five times per 20 ms tick — 250 times a second while it rains — so
  /// nothing here may allocate. The previous version built a
  /// `Map<int, List<int>>` bucket index and one `_Contact` object per pair on
  /// every call; at the 200-drop cap that is on the order of a hundred
  /// thousand short-lived objects a second, which is young-generation
  /// collections landing inside frames rather than between them.
  ///
  /// The grid is the same uniform hash, expressed as an open-addressed slot
  /// table plus a per-cell singly linked list over the particle indices. Cells
  /// are filled by walking **i downwards** and pushing to the front, so each
  /// chain comes out in ascending i — the exact order `List.add` produced. The
  /// solver accumulates into velocities pair by pair and floating-point
  /// addition does not commute, so that ordering is part of the result, not an
  /// implementation detail.
  void _buildPairs(double diameter, Float32List weight) {
    _pairCount = 0;
    if (_live < 2) return;
    final d2Max = diameter * diameter;

    _ensureGrid();
    final cellX = _cellXScratch;
    final cellY = _cellYScratch;
    for (var i = 0; i < _live; i++) {
      cellX[i] = (_p.x[i] / diameter).floor();
      cellY[i] = (_p.y[i] / diameter).floor();
    }
    _clearGrid();
    for (var i = _live - 1; i >= 0; i--) {
      final slot = _slotFor(_key(cellX[i], cellY[i]));
      _nextInCell[i] = _cellHead[slot];
      _cellHead[slot] = i;
    }

    for (var i = 0; i < _live; i++) {
      final cx = cellX[i];
      final cy = cellY[i];
      for (var ox = -1; ox <= 1; ox++) {
        for (var oy = -1; oy <= 1; oy++) {
          final slot = _findSlot(_key(cx + ox, cy + oy));
          if (slot < 0) continue;
          for (var j = _cellHead[slot]; j >= 0; j = _nextInCell[j]) {
            if (j <= i) continue;
            final dx = _p.x[j] - _p.x[i];
            final dy = _p.y[j] - _p.y[i];
            final d2 = dx * dx + dy * dy;
            if (d2 >= d2Max || d2 < 1e-12) continue;
            final d = math.sqrt(d2);
            final w = 1.0 - d / diameter;
            weight[i] += w;
            weight[j] += w;
            final k = _pairCount;
            if (k == _pairA.length) _growPairs();
            _pairA[k] = i;
            _pairB[k] = j;
            _pairW[k] = w;
            _pairNx[k] = dx / d;
            _pairNy[k] = dy / d;
            _pairCount = k + 1;
          }
        }
      }
    }
  }

  // --- contact scratch (structure of arrays, grown, never per-call) --------
  Int32List _pairA = Int32List(0);
  Int32List _pairB = Int32List(0);
  // The solver reads these at full precision; Float32 would round the normals
  // and change the trajectory.
  Float64List _pairW = Float64List(0);
  Float64List _pairNx = Float64List(0);
  Float64List _pairNy = Float64List(0);
  int _pairCount = 0;

  void _growPairs() {
    final next = _pairA.isEmpty ? 256 : _pairA.length * 2;
    _pairA = Int32List(next)..setRange(0, _pairA.length, _pairA);
    _pairB = Int32List(next)..setRange(0, _pairB.length, _pairB);
    _pairW = Float64List(next)..setRange(0, _pairW.length, _pairW);
    _pairNx = Float64List(next)..setRange(0, _pairNx.length, _pairNx);
    _pairNy = Float64List(next)..setRange(0, _pairNy.length, _pairNy);
  }

  // --- neighbour grid -----------------------------------------------------
  Int32List _cellXScratch = Int32List(0);
  Int32List _cellYScratch = Int32List(0);
  Int32List _nextInCell = Int32List(0);

  /// Slot table: `_slotKey[s] + 1` (0 marks an empty slot) and the head of
  /// that cell's chain. Sized to the drop cap, so it is allocated once.
  Int32List _slotKey = Int32List(0);
  Int32List _cellHead = Int32List(0);

  /// The slots touched this call, so clearing costs O(live), not O(table).
  Int32List _usedSlots = Int32List(0);
  int _usedSlotCount = 0;
  int _slotMask = 0;

  void _ensureGrid() {
    if (_cellXScratch.length >= capacity && _slotMask != 0) return;
    _cellXScratch = Int32List(capacity);
    _cellYScratch = Int32List(capacity);
    _nextInCell = Int32List(capacity);
    _usedSlots = Int32List(capacity);
    // Power-of-two table at =< 50 % load, so the linear probe stays short.
    var size = 16;
    while (size < capacity * 2) {
      size <<= 1;
    }
    _slotKey = Int32List(size);
    _cellHead = Int32List(size);
    _slotMask = size - 1;
  }

  void _clearGrid() {
    for (var n = 0; n < _usedSlotCount; n++) {
      _slotKey[_usedSlots[n]] = 0;
    }
    _usedSlotCount = 0;
  }

  /// Fibonacci hash of a packed cell key, masked to the table.
  static int _hash(int key) => (key * 0x9E3779B1) & 0x3FFFFFFF;

  /// The slot holding [key], claiming a free one if it is not present yet.
  int _slotFor(int key) {
    final stored = key + 1;
    var s = _hash(key) & _slotMask;
    while (true) {
      final k = _slotKey[s];
      if (k == stored) return s;
      if (k == 0) {
        _slotKey[s] = stored;
        _cellHead[s] = -1;
        _usedSlots[_usedSlotCount++] = s;
        return s;
      }
      s = (s + 1) & _slotMask;
    }
  }

  /// The slot holding [key], or -1 when the cell is empty.
  int _findSlot(int key) {
    final stored = key + 1;
    var s = _hash(key) & _slotMask;
    while (true) {
      final k = _slotKey[s];
      if (k == stored) return s;
      if (k == 0) return -1;
      s = (s + 1) & _slotMask;
    }
  }

  /// the emitter's `particleSystem.setRadius(0.01)`, in world units.
  static const double _particleRadius = 0.01;

  /// What one drop's full contribution is scaled to in the 8-bit accumulation
  /// buffer (the 0x40 tint in [paintCoverage]). The composite threshold must
  /// be scaled by the same factor; the decoded normal is a ratio and is not
  /// affected.
  static const double accumulationScale = 0x40 / 0xFF;

  /// Packs a cell coordinate into one int. The offset keeps negatives (drops
  /// above the edge) on distinct keys.
  static int _key(int cx, int cy) => (cx + 4096) * 8192 + (cy + 4096);

  void _compact() {
    var write = 0;
    for (var i = 0; i < _live; i++) {
      // `destroyParticle` at lifetime expiry — abrupt, as the engine's is; the
      // metaball threshold is what hides the pop for pooled water, and the
      // per-group ±10% jitter keeps the deaths from beating in sync.
      if (_p.age[i] >= _p.life[i]) continue;
      if (write != i) _p.copy(i, write);
      write++;
    }
    _live = write;
  }

  /// One group, created the way `createParticleGroup` creates it.
  ///
  /// LiquidFun fills the group's `CircleShape` with particles on a
  /// **world-aligned grid** whose stride is `0.75 × particleDiameter`
  /// (`b2_particleStride`). The disc's random centre lands at a random phase
  /// of that grid, so the particle count varies — 1 to 5, averaging
  /// `πr²/stride²` ≈ 3 at the 0.015 radius, ≈ 2 at heavy's 0.012 — and with
  /// it the size of the falling blob. Fixing the count per group, as an
  /// earlier version did, made every falling drop identical.
  ///
  /// Per the emitter's caller, the **group** gets one lifetime jittered ±10%
  /// (`life · ((rand−0.5)·0.2 + 1)`), which staggers deaths between groups;
  /// and each **particle** gets its own tangential velocity — the spread is
  /// not shared across the group.
  void _emit(
    double width,
    double unit,
    CardWaterPreset preset,
    double topEdge,
    CardWaterSurface? surface,
  ) {
    double originX;
    double edgeAtOrigin;
    if (surface != null) {
      // A centre column with nothing solid under it has no finite height to
      // spawn *above*, so the pick is restricted to columns that do — the
      // group's own radius still lets it spill onto neighbouring empty
      // columns and fall through them, same as any other drop would.
      final x = surface.randomSolidX(_random);
      if (x == null) return; // nothing solid anywhere — no group this tick
      originX = x;
      edgeAtOrigin = surface.heightAt(x);
    } else {
      originX = _random.nextDouble() * width;
      edgeAtOrigin = topEdge;
    }
    final originY = edgeAtOrigin - spawnHeight * unit;
    final radius = preset.groupRadius * unit;
    final stride = 0.75 * 2 * _particleRadius * unit;
    if (stride <= 0) return;
    final groupLife = preset.life * ((_random.nextDouble() - 0.5) * 0.2 + 1.0);
    final vy = preset.fallSpeed * unit;

    final minGx = ((originX - radius) / stride).ceil();
    final maxGx = ((originX + radius) / stride).floor();
    final minGy = ((originY - radius) / stride).ceil();
    final maxGy = ((originY + radius) / stride).floor();
    for (var gy = minGy; gy <= maxGy; gy++) {
      for (var gx = minGx; gx <= maxGx; gx++) {
        final px = gx * stride;
        final py = gy * stride;
        final dx = px - originX;
        final dy = py - originY;
        if (dx * dx + dy * dy > radius * radius) continue;
        if (_live >= capacity) return;
        final j = _live++;
        _p.x[j] = px;
        _p.y[j] = py;
        _p.vx[j] = (_random.nextDouble() - 0.5) * preset.xSpread * unit;
        _p.vy[j] = vy;
        _p.age[j] = 0;
        _p.life[j] = groupLife;
        _p.seed[j] = _random.nextDouble();
      }
    }
  }

  /// Accumulates one half of each drop's contribution additively — the reference's
  /// particle pass, run once with
  /// [spritePos] and once with [spriteNeg] into separate buffers.
  ///
  /// Every drop draws at the same [dropSize] with no tint, fade, or size
  /// jitter: the engine's `uPointSize` is one constant per grade and
  /// The reference shader has no per-particle variation of any kind. The colour
  /// multiplies in [CardWaterField.accumulationScale] so the 8-bit sum has
  /// headroom for the stacked pool.
  void paintCoverage(
    Canvas canvas, {
    required double dropSize,
    required bool negative,
  }) {
    if (_live == 0) return;
    final sprite = negative ? spriteNeg : spritePos;

    final transforms = Float32List(_live * 4);
    final rects = Float32List(_live * 4);
    final colors = Int32List(_live);

    final w = sprite.width.toDouble();
    final h = sprite.height.toDouble();
    final scale = dropSize / w;

    for (var i = 0; i < _live; i++) {
      final o = i * 4;
      transforms[o] = scale;
      transforms[o + 1] = 0;
      transforms[o + 2] = _p.x[i] - w * scale / 2;
      transforms[o + 3] = _p.y[i] - h * scale / 2;

      rects[o] = 0;
      rects[o + 1] = 0;
      rects[o + 2] = w;
      rects[o + 3] = h;

      // 0x40FFFFFF premultiplies to ×0.251 on *every* channel — exactly the
      // accumulation scale. (An rgb of 0x40 here would premultiply twice.)
      colors[i] = 0x40FFFFFF;
    }

    canvas.drawRawAtlas(
      sprite,
      transforms,
      rects,
      colors,
      BlendMode.modulate,
      null,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.plus,
    );
  }

  /// Empties the field.
  void clear() {
    _live = 0;
    _stepCarry = 0;
    _stepIndex = 0;
  }
}

/// One of the reference's panel rain grades.
///
/// The reference maps weather type 5/13 → 0, 6 → 1, 7 → 2, 8 → 3, i.e. light /
/// moderate / heavy / storm; 2 and 3 share a setting. Every value below is that
/// table, in world units.
@immutable
class CardWaterPreset {
  const CardWaterPreset({
    required this.life,
    required this.fallSpeed,
    required this.gravity,
    required this.xSpread,
    required this.groupRadius,
    required this.interval,
    required this.pressure,
  });

  /// Seconds a drop lives.
  final double life;

  /// Downward launch speed, world units/s.
  final double fallSpeed;

  /// World gravity, units/s².
  final double gravity;

  /// Horizontal jitter, world units/s.
  final double xSpread;

  /// Group disc radius, world units.
  final double groupRadius;

  /// Steps between groups: 8 light, 3 moderate, 1 heavy.
  final int interval;

  /// LiquidFun's pressure strength for this grade.
  final double pressure;

  /// Weather 5/13 — light rain.
  static const CardWaterPreset light = CardWaterPreset(
    life: 0.5,
    fallSpeed: 8.0,
    gravity: 4.5,
    xSpread: 1.5,
    groupRadius: 0.015,
    interval: 8,
    pressure: 0.024,
  );

  /// `x(1)` — weather 6, moderate rain.
  static const CardWaterPreset moderate = CardWaterPreset(
    life: 0.38,
    fallSpeed: 8.0,
    gravity: 4.25,
    xSpread: 1.3,
    groupRadius: 0.015,
    interval: 3,
    pressure: 0.024,
  );

  /// `x(2)`/`x(3)` — weather 7/8, heavy rain and storm. The engine runs two
  /// worlds with *different* settings at this grade and draws both into the
  /// same buffer; this is world 0, the slow fat drops.
  static const CardWaterPreset heavy = CardWaterPreset(
    life: 0.56,
    fallSpeed: 2.0,
    gravity: 12.0,
    xSpread: 0.9,
    groupRadius: 0.012,
    interval: 1,
    pressure: 0.025,
  );

  /// World 1 of the heavy grade: fast, short-lived, nearly vertical. Layered
  /// over [heavy] it is what makes a storm read as driving rain rather than
  /// more of the same drops.
  static const CardWaterPreset heavySecondary = CardWaterPreset(
    life: 0.25,
    fallSpeed: 6.0,
    gravity: 9.0,
    xSpread: 0.1,
    groupRadius: 0.015,
    interval: 1,
    pressure: 0.025,
  );
}

/// A per-column collision surface: the topmost solid pixel's y in [heights],
/// one entry every [columnWidth] logical pixels starting at the field's own
/// x=0. In [CardWaterField.update], a drop at local x lands at
/// `heightAt(x)` instead of the flat `topEdge`.
///
/// Columns are held flat between samples, not interpolated — a glyph's edge
/// is already jagged at the pixel level, and smoothing it into a slope no
/// letterform actually has would read as a rendering bug, not as water.
///
/// [heightAt] answers `double.infinity` for a column with nothing solid in
/// it (the gap between two letters, say) as well as for any x outside
/// [heights]' own span. That is not a missing case to patch — it is the
/// correct physical answer, and every consumer below leans on it rather than
/// special-casing it: `double.infinity` compares false against every finite
/// y, so a drop over an empty column simply never triggers a contact and
/// keeps falling until its lifetime ends, exactly as it should.
@immutable
class CardWaterSurface {
  CardWaterSurface({required this.heights, required this.columnWidth})
    : _solidColumns = [
        for (var i = 0; i < heights.length; i++)
          if (heights[i].isFinite) i,
      ];

  /// Per-column height, card-local y. `double.infinity` — nothing solid.
  final List<double> heights;

  /// Sample spacing, logical pixels.
  final double columnWidth;

  /// Indices into [heights] that are actually solid — precomputed once so
  /// [randomSolidX] does not rescan the whole field on every emission.
  final List<int> _solidColumns;

  /// The surface height at local x.
  double heightAt(double x) {
    if (columnWidth <= 0 || heights.isEmpty) return double.infinity;
    final i = (x / columnWidth).floor();
    if (i < 0 || i >= heights.length) return double.infinity;
    return heights[i];
  }

  /// A uniformly random x with something solid under it, or null if
  /// [heights] has no solid column at all — nothing was rasterised, or
  /// everything sampled came back empty.
  ///
  /// Emission needs this rather than a plain `random() * width`: the group's
  /// own spawn height is read from its centre column, and a centre with
  /// nothing under it has no finite height to spawn *above*.
  double? randomSolidX(math.Random random) {
    if (_solidColumns.isEmpty) return null;
    final i = _solidColumns[random.nextInt(_solidColumns.length)];
    return (i + 0.5) * columnWidth;
  }
}

/// Builds a [CardWaterSurface] from a rendered image's own alpha channel —
/// what turns "drops fall from above, caught by whatever they hit first"
/// into a surface that follows real text and icons instead of a hand-placed
/// shape. For each sampled column, the topmost pixel whose alpha crosses
/// [threshold] is that column's height; a column with nothing above
/// [threshold] anywhere in it is left at `double.infinity` — an empty gap
/// between two letters, honestly reported as nothing to land on, the same
/// answer [CardWaterSurface.heightAt] already gives past the edge of a
/// narrower field.
///
/// [image] must be captured **1:1 with the widget's own logical pixels**
/// (`RenderRepaintBoundary.toImage(pixelRatio: 1.0)`) — a returned height is
/// used directly as a card-local y, with no separate scale factor carried
/// through the physics, and a mismatched capture scale would silently shift
/// the whole surface.
///
/// Synchronous despite taking an already-decoded [ui.Image]: the one actually
/// async step, capturing the image itself, is the caller's concern — this
/// only reads pixels already sitting in memory, which is squarely a
/// same-frame operation and does not need `async` to say so.
CardWaterSurface silhouetteSurface(
  ByteData pixels,
  int width,
  int height, {
  double columnWidth = 3,
  double threshold = 0.35,
}) {
  final px = pixels.buffer.asUint8List();
  final columns = (width / columnWidth).ceil();
  final heights = List<double>.filled(columns, double.infinity);
  final cut = (threshold.clamp(0.0, 1.0) * 255).round();
  for (var col = 0; col < columns; col++) {
    final xStart = (col * columnWidth).floor().clamp(0, width - 1);
    final xEnd = ((col + 1) * columnWidth).ceil().clamp(xStart + 1, width);
    for (var y = 0; y < height; y++) {
      final row = y * width;
      var hit = false;
      for (var x = xStart; x < xEnd; x++) {
        if (px[(row + x) * 4 + 3] >= cut) {
          hit = true;
          break;
        }
      }
      if (hit) {
        heights[col] = y.toDouble();
        break;
      }
    }
  }
  return CardWaterSurface(heights: heights, columnWidth: columnWidth);
}

class _Drops {
  _Drops(int capacity)
    : x = Float32List(capacity),
      y = Float32List(capacity),
      vx = Float32List(capacity),
      vy = Float32List(capacity),
      age = Float32List(capacity),
      life = Float32List(capacity),
      seed = Float32List(capacity),
      fx = Float32List(capacity),
      fy = Float32List(capacity);

  final Float32List x;
  final Float32List y;
  final Float32List vx;
  final Float32List vy;
  final Float32List age;
  final Float32List life;
  final Float32List seed;

  /// Reaction force SolveCollision stores for the next iteration's SolveForce.
  final Float32List fx;
  final Float32List fy;

  void copy(int from, int to) {
    x[to] = x[from];
    y[to] = y[from];
    vx[to] = vx[from];
    vy[to] = vy[from];
    age[to] = age[from];
    life[to] = life[from];
    seed[to] = seed[from];
    fx[to] = fx[from];
    fy[to] = fy[from];
  }
}

/// Bakes the per-drop sprite pair from the two source textures.
///
/// [kernel] is `particle_blurred` (64×64, alpha = coverage) and [normalMap] is
/// `drop_normal` (128×128, a hemisphere normal encoded `n·0.5+0.5`) — both
/// generated by `tool/gen/particle_sprites.py`. The reference samples each at
/// `gl_PointCoord` over the same point quad and writes the **signed** normal
/// with the kernel's alpha; the sign cannot survive an 8-bit unsigned surface,
/// so the pair splits it:
///
///   pos = (max(nx,0), max(ny,0), nz)          — alpha 255
///   neg = (max(−nx,0), max(−ny,0), kernel·0.784) — alpha 255
///
/// and the composite reassembles `Σn = (pos.rg − neg.rg, pos.b)`, with the
/// coverage in neg's blue channel. Alpha stays opaque in both: canvas
/// surfaces premultiply, and a data channel scaled by a varying alpha is how
/// the earlier single-sprite encoding got polluted.
Future<(ui.Image, ui.Image)> bakeParticleSprites({
  required ui.Image kernel,
  required ui.Image normalMap,
  int size = 64,
}) async {
  final kernelBytes = await _rasterize(kernel, size);
  final normalBytes = await _rasterize(normalMap, size);

  final pos = Uint8List(size * size * 4);
  final neg = Uint8List(size * size * 4);
  for (var i = 0; i < size * size; i++) {
    final o = i * 4;
    final nx = normalBytes[o] / 255.0 * 2.0 - 1.0;
    final ny = normalBytes[o + 1] / 255.0 * 2.0 - 1.0;
    final nz = (normalBytes[o + 2] / 255.0 * 2.0 - 1.0).clamp(0.0, 1.0);
    final a = kernelBytes[o + 3] / 255.0 * 0.784;

    pos[o] = (nx.clamp(0.0, 1.0) * 255).round();
    pos[o + 1] = (ny.clamp(0.0, 1.0) * 255).round();
    pos[o + 2] = (nz * 255).round();
    pos[o + 3] = 255;
    neg[o] = ((-nx).clamp(0.0, 1.0) * 255).round();
    neg[o + 1] = ((-ny).clamp(0.0, 1.0) * 255).round();
    neg[o + 2] = (a * 255).round();
    neg[o + 3] = 255;
  }
  return (await _imageFromRgba(pos, size), await _imageFromRgba(neg, size));
}

/// Draws [source] scaled to [size]² and reads the pixels back.
Future<Uint8List> _rasterize(ui.Image source, int size) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    source,
    Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..filterQuality = FilterQuality.medium,
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(size, size);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<ui.Image> _imageFromRgba(Uint8List rgba, int size) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    size,
    size,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

/// Procedural stand-ins for [bakeParticleSprites], matching the generated
/// textures — used until the real assets finish decoding, and in tests.
///
/// The two functions they stand in for:
///  * `particle_blurred`: alpha flat 1.0 to half the radius, then
///    `cos((r−0.5)/0.5 · π/2)` — within ~3% of every sampled point.
///  * `normal`: a standard unit hemisphere, linear in x/y with
///    `z = √(1−x²−y²)`, encoded `n·0.5+0.5`.
(ui.Image, ui.Image) buildParticleSprites({int size = 16}) {
  ui.Image build(bool negative) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    final half = (size - 1) / 2.0;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final u = (x - half) / (size / 2);
        final v = (half - y) / (size / 2);
        final r = math.sqrt(u * u + v * v);
        final profile = r <= 0.5
            ? 1.0
            : (r >= 1.0 ? 0.0 : math.cos((r - 0.5) / 0.5 * math.pi / 2));
        final a = profile * 0.784;
        final nx = negative ? (-u).clamp(0.0, 1.0) : u.clamp(0.0, 1.0);
        final ny = negative ? (-v).clamp(0.0, 1.0) : v.clamp(0.0, 1.0);
        final b = negative ? a : math.sqrt(math.max(0.0, 1.0 - u * u - v * v));
        paint.color = Color.fromARGB(
          255,
          (nx * 255).round(),
          (ny * 255).round(),
          (b * 255).round(),
        );
        canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
      }
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(size, size);
    picture.dispose();
    return image;
  }

  return (build(false), build(true));
}

/// One particle-particle contact: indices, weight and the A→B unit normal.
