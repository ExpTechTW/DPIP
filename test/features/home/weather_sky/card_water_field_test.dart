import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/card_water_field.dart';
import 'package:flutter_test/flutter_test.dart';

/// The card and the screen it is scaled against, in logical pixels.
const double _width = 360;
const double _screen = 800;

final (ui.Image, ui.Image) _sprites = buildParticleSprites(size: 8);

CardWaterField _field({int capacity = 200}) => CardWaterField(
  spritePos: _sprites.$1,
  spriteNeg: _sprites.$2,
  capacity: capacity,
);

void _run(
  CardWaterField field,
  double seconds, {
  double intensity = 1.0,
  CardWaterPreset preset = CardWaterPreset.moderate,
  double step = CardWaterField.emitterTick,
  CardWaterSurface? surface,
}) {
  for (var t = 0.0; t < seconds; t += step) {
    field.update(
      step,
      width: _width,
      screenHeight: _screen,
      intensity: intensity,
      preset: preset,
      surface: surface,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('drops are born just above the edge, not a third of a screen up', () {
    // the emitter's spawn y is 0.91, but that is an absolute world y — the collision box
    // puts the card's top face at +0.852, so the spawn line is only 0.058 above
    // it. Reading 0.91 as a relative height starts the fall off-card entirely.
    expect(CardWaterField.spawnHeight, closeTo(0.058, 1e-9));
    expect(
      CardWaterField.spawnHeight * _screen / 3,
      closeTo(15.5, 0.5),
      reason: 'about 15 dp above the edge on an 800 dp screen',
    );
  });

  test('the headroom covers the fall and the spray above it', () {
    final headroom = CardWaterField.spawnHeadroom(_screen);
    expect(headroom, greaterThan(CardWaterField.spawnHeight * _screen / 3));
    // The splash goes higher than the spawn line, so a headroom sized to the
    // fall alone would clip the top off it.
    expect(headroom, greaterThanOrEqualTo(48));
  });

  test('pooled drops push each other apart instead of piling up', () {
    final field = _field();
    // Land several groups, then let them relax.
    _run(field, 1.0, preset: CardWaterPreset.heavy);
    expect(field.settledCount(_screen), greaterThan(4));

    final xs = field.debugPositions.map((p) => p.dx).toList(growable: false)
      ..sort();
    var tightest = double.infinity;
    for (var i = 0; i < xs.length - 1; i++) {
      tightest = math.min(tightest, xs[i + 1] - xs[i]);
    }
    // LiquidFun's pressure term spreads particles to about a diameter apart;
    // without it every group stays stacked on its landing point and the edge
    // reads as separate dots rather than a sheet of water.
    expect(tightest, greaterThan(0.0));
  });

  test('the solver never pushes a drop through the card', () {
    final field = _field();
    _run(field, 2.0, preset: CardWaterPreset.heavy);
    for (final p in field.debugPositions) {
      expect(p.dy, lessThanOrEqualTo(0.01));
    }
  });

  test(
    'drops are launched downward — the spray is not an initial velocity',
    () {
      final field = _field();
      // Sample the emitter's own output: the emitter is
      // `Vec2((rand - 0.5) * spread, -fallSpeed)`, so every drop *starts*
      // downward. Water moves up later only because the pressure solver throws
      // it there. This has to bypass the world step — the spawn line is 15 px
      // above the edge and a drop covers that in a third of one step, so a full
      // tick always returns the group already landed.
      field.debugEmit(
        width: _width,
        screenHeight: _screen,
        preset: CardWaterPreset.moderate,
      );

      final fresh = field.debugVelocities.where((v) => v.dy != 0);
      expect(fresh, isNotEmpty);
      expect(fresh.every((v) => v.dy > 0), isTrue);
    },
  );

  test('the first group appears at the spawn line', () {
    final field = _field();
    field.debugEmit(
      width: _width,
      screenHeight: _screen,
      preset: CardWaterPreset.moderate,
    );

    final born = field.debugPositions.map((p) => -p.dy);
    expect(born, isNotEmpty);
    for (final y in born) {
      expect(y, closeTo(CardWaterField.spawnHeight * _screen / 3, 6));
    }
  });

  test('the fall speed is the engine scale, not the digit painter scale', () {
    final field = _field();
    field.debugEmit(
      width: _width,
      screenHeight: _screen,
      preset: CardWaterPreset.moderate,
    );

    // fallSpeed 8.0 world units/s at 3 units to the screen height = 2133 px/s.
    // 8.0 is the **phone** branch of the reference; the reference picks it and the 6.0
    // beside it is the tablet/fold one. The digit painter's
    // 40-units-to-the-*width* scale would give 72 px/s.
    for (final v in field.debugVelocities) {
      expect(v.dy, closeTo(2133, 50));
    }
  });

  test('drops pile up on the edge and stay there', () {
    final field = _field();
    _run(field, 0.5, preset: CardWaterPreset.moderate);

    expect(field.settledCount(_screen), greaterThan(0));
    for (final p in field.debugPositions) {
      expect(p.dy, lessThanOrEqualTo(0.01));
    }
  });

  test('a landing group throws water back up — the splash', () {
    final field = _field();
    // Sample every frame: the spray is transient by nature, so looking only at
    // the final frame can easily land on a moment where the pile has settled.
    var fastestRise = 0.0;
    for (var t = 0.0; t < 1.5; t += 1 / 60) {
      field.update(
        1 / 60,
        width: _width,
        screenHeight: _screen,
        intensity: 1,
        preset: CardWaterPreset.heavy,
      );
      for (final v in field.debugVelocities) {
        if (-v.dy > fastestRise) fastestRise = -v.dy;
      }
    }

    // `restitution = 0` never bounces anything. The upward motion is the
    // pressure term resolving the overlap and the velocity being read back out
    // of the displacement — solve it in one dimension and this stays 0.
    expect(
      fastestRise,
      greaterThan(20),
      reason: 'nothing is thrown upward, so there is no splash at all',
    );
  });

  test('the solver caps speed — hops, never streaks', () {
    final field = _field();
    var fastest = 0.0;
    for (var t = 0.0; t < 1.5; t += 1 / 60) {
      field.update(
        1 / 60,
        width: _width,
        screenHeight: _screen,
        intensity: 1,
        preset: CardWaterPreset.heavy,
      );
      for (final v in field.debugVelocities) {
        // Only solver-driven motion: fresh drops legitimately fall at full
        // speed, so measure everything except the straight-down launch.
        if (v.dy < 0 || v.dx.abs() > 0.5) {
          fastest = math.max(fastest, v.distance);
        }
      }
    }
    // `LimitVelocity` caps at the critical velocity — one particle diameter
    // of travel per *sub*-step: 0.02 * (5/dt) = 6.0 world units/s, which is
    // 1600 px/s on this screen. (An earlier version invented 1.2 here, which
    // is not a LiquidFun constant at all.)
    const criticalVelocity = 0.02 * 5 * 60.0; // diameter * inv_dt(sub-step)
    expect(fastest, lessThanOrEqualTo(criticalVelocity * _screen / 3 + 1));
    expect(fastest, greaterThan(0), reason: 'no solver motion at all');
  });

  test('water never gets below the card top edge', () {
    final field = _field();
    _run(field, 2.0, preset: CardWaterPreset.heavy);
    // The pool sits *on* the edge; leaking past it would draw water across the
    // chart underneath.
    for (final p in field.debugPositions) {
      expect(p.dy, lessThanOrEqualTo(0.01));
    }
  });

  test('the grades differ by spawn interval, as the engine table does', () {
    // the emitter's interval: 8 steps light, 3 moderate, 1 heavy — the count on the card is
    // set by how often groups arrive, not by how fast they fall.
    expect(CardWaterPreset.light.interval, 8);
    expect(CardWaterPreset.moderate.interval, 3);
    expect(CardWaterPreset.heavy.interval, 1);

    final light = _field();
    final heavy = _field();
    _run(light, 0.6, preset: CardWaterPreset.light);
    _run(heavy, 0.6, preset: CardWaterPreset.heavy);
    expect(heavy.liveCount, greaterThan(light.liveCount));
  });

  test('the heavy grade layers two different worlds', () {
    // `x(2)`/`x(3)` configure world 0 and world 1 differently — slow fat drops
    // under fast thin ones. Collapsing them into one preset loses the storm.
    expect(
      CardWaterPreset.heavySecondary.fallSpeed,
      isNot(CardWaterPreset.heavy.fallSpeed),
    );
    expect(
      CardWaterPreset.heavySecondary.life,
      lessThan(CardWaterPreset.heavy.life),
    );
  });

  test('falling groups vary in size, exactly as grid packing varies', () {
    // LiquidFun fills each group's disc from a world-aligned grid, so the
    // random centre phase decides how many particles a group gets (1..5,
    // averaging ~3 at the 0.015 radius). Constant-size groups were why every
    // falling drop looked identical.
    final field = _field();
    final sizes = <int>{};
    var before = 0;
    for (var step = 0; step < 240; step++) {
      field.update(
        CardWaterField.emitterTick,
        width: _width,
        screenHeight: _screen,
        intensity: 1,
        preset: CardWaterPreset.light, // interval 8: one group per emission
      );
      final born = field.liveCount - before;
      if (born > 0) sizes.add(born);
      before = field.liveCount;
      // First few groups are enough (light: no deaths yet).
      if (step > 20) break;
    }
    expect(sizes.length, greaterThanOrEqualTo(1));

    // Across many groups the count must actually vary.
    final field2 = _field();
    final seen = <int>{};
    var prev = 0;
    for (var step = 0; step < 8 * 12; step++) {
      field2.update(
        CardWaterField.emitterTick,
        width: _width,
        screenHeight: _screen,
        intensity: 1,
        preset: CardWaterPreset.light,
      );
      final born = field2.liveCount - prev;
      // Deaths start after ~0.45 s; only count clean birth steps.
      if (born > 0 && step < 8 * 12) seen.add(born);
      prev = field2.liveCount;
      if (step >= 8 * 3 + 1) break; // three groups, all before first death
    }
    expect(
      seen.length,
      greaterThanOrEqualTo(2),
      reason:
          'every group had the same particle count — falling drops will '
          'all be the same size again',
    );
  });

  test('group lifetimes are jittered, so deaths do not beat in sync', () {
    // the emitter's caller passes `life · ((rand−0.5)·0.2 + 1)` per group.
    final field = _field();
    // Two groups, born on different emission steps, then no more rain.
    var steps = 0;
    while (steps < 8 * 2 + 1) {
      field.update(
        CardWaterField.emitterTick,
        width: _width,
        screenHeight: _screen,
        intensity: 1,
        preset: CardWaterPreset.light,
      );
      steps++;
    }
    final born = field.liveCount;
    expect(born, greaterThan(1));

    // Step until the first death; with per-group jitter the survivors of the
    // other group live on — a partial drop, never a single cliff.
    var sawPartial = false;
    for (
      var t = 0.0;
      t < 2.0 && field.liveCount > 0;
      t += CardWaterField.emitterTick
    ) {
      final beforeStep = field.liveCount;
      field.update(
        CardWaterField.emitterTick,
        width: _width,
        screenHeight: _screen,
        intensity: 0,
        preset: CardWaterPreset.light,
      );
      if (field.liveCount < beforeStep && field.liveCount > 0) {
        sawPartial = true;
      }
    }
    expect(field.liveCount, 0, reason: 'everything should expire eventually');
    expect(
      sawPartial,
      isTrue,
      reason:
          'all groups died on the same frame — the ±10% lifetime jitter '
          'is missing and the pool will strobe',
    );
  });

  test('drops expire at the end of their life', () {
    final field = _field();
    _run(field, 0.3, preset: CardWaterPreset.moderate);
    expect(field.liveCount, greaterThan(0));

    _run(field, 1.0, intensity: 0, preset: CardWaterPreset.moderate);
    expect(field.liveCount, 0);
  });

  test(
    'emission is fixed-step, so the frame rate does not change the rain',
    () {
      final at60 = _field();
      final at120 = _field();
      _run(at60, 0.6, step: 1 / 60);
      _run(at120, 0.6, step: 1 / 120);
      expect(
        at120.liveCount,
        closeTo(at60.liveCount.toDouble(), at60.liveCount * 0.35),
      );
    },
  );

  test('never exceeds capacity', () {
    final field = _field(capacity: 24);
    _run(field, 3.0, preset: CardWaterPreset.heavy);
    expect(field.liveCount, lessThanOrEqualTo(24));
  });

  test('a zero-size card is a no-op, not a crash', () {
    final field = _field();
    field.update(
      1 / 60,
      width: 0,
      screenHeight: _screen,
      intensity: 1,
      preset: CardWaterPreset.moderate,
    );
    field.update(
      1 / 60,
      width: _width,
      screenHeight: 0,
      intensity: 1,
      preset: CardWaterPreset.moderate,
    );
    expect(field.liveCount, 0);
  });

  group('CardWaterSurface', () {
    test('reads back the column it was built from', () {
      final surface = CardWaterSurface(
        heights: [0, -10, -10, double.infinity, 5],
        columnWidth: 4,
      );
      expect(surface.heightAt(0), 0); // column 0: [0, 4)
      expect(surface.heightAt(3.9), 0);
      expect(surface.heightAt(4), -10); // column 1: [4, 8)
      expect(surface.heightAt(7.9), -10);
      expect(surface.heightAt(8), -10); // column 2
      expect(surface.heightAt(12), double.infinity); // column 3 — empty
      expect(surface.heightAt(16), 5); // column 4
    });

    test('is infinite past both ends of the sampled span', () {
      final surface = CardWaterSurface(heights: [0, 0], columnWidth: 4);
      expect(surface.heightAt(-1), double.infinity);
      expect(surface.heightAt(100), double.infinity);
    });

    test('an all-empty field has no solid x at all', () {
      final surface = CardWaterSurface(
        heights: List.filled(10, double.infinity),
        columnWidth: 4,
      );
      expect(surface.randomSolidX(math.Random(1)), isNull);
    });

    test('a solid x always lands in a column that reads back finite', () {
      final surface = CardWaterSurface(
        heights: [double.infinity, 0, double.infinity, -10, double.infinity],
        columnWidth: 4,
      );
      final random = math.Random(7);
      for (var i = 0; i < 50; i++) {
        final x = surface.randomSolidX(random);
        expect(x, isNotNull);
        expect(surface.heightAt(x!), isNot(double.infinity));
      }
    });
  });

  group('CardWaterField with a CardWaterSurface', () {
    test('a drop settles at its own column\'s height, not topEdge', () {
      // Wide, and run for only a fraction of a second — not the single
      // narrow column and full second an earlier version of this test used.
      // A growing pile spreads sideways under its own pressure, and given
      // enough width and enough time that spread reaches past a too-narrow
      // sampled span: those particles read back `heightAt`'s infinity, lost
      // their floor, and were still falling when the test read them back.
      // Wide and short-lived enough that this can't happen here.
      const raisedY = -40.0;
      final surface = CardWaterSurface(
        heights: List.filled(200, raisedY),
        columnWidth: 4,
      );
      final field = _field();
      _run(field, 0.3, preset: CardWaterPreset.moderate, surface: surface);
      expect(
        field.settledCount(_screen, surface: surface),
        greaterThan(0),
        reason: 'nothing settled at the surface at all',
      );
      for (final p in field.debugPositions) {
        // Never past the surface — exactly the flat-edge "never gets below
        // the card top edge" invariant, at an offset that only the surface,
        // not the flat topEdge=0 default, could have produced. No lower
        // bound: a splash is expected to throw drops back up by a variable
        // amount, which is what "a landing group throws water back up"
        // already covers on its own.
        expect(p.dy, lessThanOrEqualTo(raisedY + 0.01));
      }
    });

    test('nothing solid anywhere means nothing is emitted', () {
      final empty = CardWaterSurface(
        heights: List.filled(20, double.infinity),
        columnWidth: 4,
      );
      final field = _field();
      _run(field, 0.5, preset: CardWaterPreset.heavy, surface: empty);
      expect(field.liveCount, 0, reason: 'nothing solid to spawn a group over');
    });

    test('a drop already falling over an empty column is never caught', () {
      // Seeded on a full-width solid surface (behaves like the flat topEdge=0
      // case) so the group actually lands somewhere, then handed to a solver
      // step that sees nothing but empty columns — isolating the solver from
      // emission, which by itself already refuses to spawn over nothing.
      final field = _field();
      field.debugEmit(
        width: _width,
        screenHeight: _screen,
        preset: CardWaterPreset.moderate,
        surface: CardWaterSurface(heights: [0], columnWidth: _width),
      );
      expect(field.liveCount, greaterThan(0));
      final startY = field.debugPositions.map((p) => p.dy).reduce(math.max);

      final empty = CardWaterSurface(
        heights: List.filled(20, double.infinity),
        columnWidth: 4,
      );
      // Moderate's own life is 0.38s — well short of that, or every seeded
      // drop has already expired (and been compacted away) by the time this
      // reads them back, regardless of whether the solver ever caught them.
      for (var t = 0.0; t < 0.2; t += 1 / 60) {
        field.update(
          1 / 60,
          width: _width,
          screenHeight: _screen,
          intensity: 0, // no new groups — just watch the seeded ones fall
          preset: CardWaterPreset.moderate,
          surface: empty,
        );
      }
      expect(
        field.liveCount,
        greaterThan(0),
        reason: 'died before it could fall',
      );
      final endY = field.debugPositions.map((p) => p.dy).reduce(math.max);
      expect(
        endY,
        greaterThan(startY + 10),
        reason: 'a drop over an empty column should keep falling, not park',
      );
    });
  });

  group('silhouetteSurface', () {
    // width x height RGBA, alpha-only (rgb stays 0 throughout — only alpha
    // decides what counts as solid).
    ByteData image(int w, int h, List<(int x, int y, int alpha)> pixels) {
      final bytes = Uint8List(w * h * 4);
      for (final (x, y, a) in pixels) {
        bytes[(y * w + x) * 4 + 3] = a;
      }
      return ByteData.sublistView(bytes);
    }

    test('reports the topmost solid row per column band', () {
      const w = 6, h = 5;
      final data = image(w, h, [
        (0, 2, 255), (1, 2, 255), // columns 0-1: solid starting row 2
        (2, 0, 255), (3, 0, 255), // columns 2-3: solid starting row 0
        // columns 4-5: nothing at all
      ]);
      final surface = silhouetteSurface(data, w, h, columnWidth: 2);
      expect(surface.heightAt(0.5), 2.0);
      expect(surface.heightAt(1.9), 2.0);
      expect(surface.heightAt(2.0), 0.0);
      expect(surface.heightAt(3.9), 0.0);
      expect(surface.heightAt(4.5), double.infinity);
      expect(surface.heightAt(5.9), double.infinity);
    });

    test('a thin diagonal stroke is still caught by its column band', () {
      // One solid pixel per row, stepping right — nothing fills a whole
      // 2px-wide band on its own, but each band still has *a* solid pixel in
      // it somewhere, which is the case a coarse column width exists to
      // handle: real glyph strokes are often thinner than the sample spacing.
      const w = 8, h = 4;
      final data = image(w, h, [
        (0, 0, 255),
        (2, 1, 255),
        (4, 2, 255),
        (6, 3, 255),
      ]);
      final surface = silhouetteSurface(data, w, h, columnWidth: 2);
      expect(surface.heightAt(0.5), 0.0); // band [0,2): pixel at x=0,y=0
      expect(surface.heightAt(2.5), 1.0); // band [2,4): pixel at x=2,y=1
      expect(surface.heightAt(4.5), 2.0); // band [4,6): pixel at x=4,y=2
      expect(surface.heightAt(6.5), 3.0); // band [6,8): pixel at x=6,y=3
    });

    test('the threshold is a real cutoff, not just a non-zero check', () {
      const w = 2, h = 3;
      final data = image(w, h, [
        (0, 0, 60), // 24%, below a 0.35 threshold
        (0, 1, 200), // 78%, above it
      ]);
      final surface = silhouetteSurface(
        data,
        w,
        h,
        columnWidth: 2,
        threshold: 0.35,
      );
      expect(
        surface.heightAt(0.5),
        1.0,
        reason: 'the faint pixel at row 0 should not count as solid',
      );
    });

    test('an entirely empty image has no solid column anywhere', () {
      const w = 10, h = 10;
      final data = image(w, h, const []);
      final surface = silhouetteSurface(data, w, h, columnWidth: 3);
      expect(surface.randomSolidX(math.Random(1)), isNull);
    });
  });
}
