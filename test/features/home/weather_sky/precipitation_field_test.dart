import 'dart:ui' as ui;

import 'package:dpip/features/home/presentation/widgets/weather_sky/precipitation_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The particle field reproduces the reference's emitter and compute shader, so the
/// properties that define its look are pinned here — most importantly that
/// precipitation falls *down*, which a still frame cannot show and which a
/// sign slip silently inverted once already.
void main() {
  const size = Size(360, 620);

  PrecipitationField field({int capacity = 400, bool tumble = false}) =>
      PrecipitationField(
        atlas: _stubAtlas(),
        capacity: capacity,
        variants: 4,
        cell: const Size(32, 68),
        tumble: tumble,
        seed: 3,
      );

  /// Runs the field and returns the mean y translation of its sprites.
  double meanY(
    PrecipitationField f, {
    required int frames,
    double intensity = 1.0,
    double wind = 0.0,
  }) {
    var last = 0.0;
    for (var i = 0; i < frames; i++) {
      final batch = f.step(
        size: size,
        dt: 1 / 60,
        intensity: intensity,
        fallSpeed: 1.0,
        wind: wind,
        opacity: 1.0,
        tint: const Color(0xFFFFFFFF),
        sizeMin: 0.013,
        sizeMax: 0.042,
        // Far longer than the run, so respawning cannot confound the
        // measurement — the real field uses the reference's constant 3.0 s.
        life: 500,
      );
      var sum = 0.0;
      for (var p = 0; p < batch.count; p++) {
        sum += batch.transforms[p * 4 + 3];
      }
      last = batch.count == 0 ? 0.0 : sum / batch.count;
    }
    return last;
  }

  test('particles fall downward', () {
    final f = field();
    final before = meanY(f, frames: 2);
    final after = meanY(f, frames: 30);
    expect(
      after,
      greaterThan(before),
      reason: 'mean y went $before → $after; it must increase (downward)',
    );
  });

  test('wind carries particles sideways in its own direction', () {
    double meanX(double wind) {
      final f = field();
      var last = 0.0;
      for (var i = 0; i < 30; i++) {
        final batch = f.step(
          size: size,
          dt: 1 / 60,
          intensity: 1.0,
          fallSpeed: 1.0,
          wind: wind,
          opacity: 1.0,
          tint: const Color(0xFFFFFFFF),
          sizeMin: 0.013,
          sizeMax: 0.042,
          life: 500,
        );
        var sum = 0.0;
        for (var p = 0; p < batch.count; p++) {
          sum += batch.transforms[p * 4 + 2];
        }
        last = batch.count == 0 ? 0.0 : sum / batch.count;
      }
      return last;
    }

    expect(meanX(0.8), greaterThan(meanX(-0.8)));
  });

  test('intensity scales how many particles are live', () {
    final f = field(capacity: 400);
    int countAt(double intensity) => f
        .step(
          size: size,
          dt: 1 / 60,
          intensity: intensity,
          fallSpeed: 1.0,
          wind: 0.0,
          opacity: 1.0,
          tint: const Color(0xFFFFFFFF),
          sizeMin: 0.013,
          sizeMax: 0.042,
          life: 3.0,
        )
        .count;

    expect(countAt(0.25), lessThan(countAt(1.0)));
  });

  test(
    'depth is biased toward distant particles, as the reference weights it',
    () {
      // The reference's spawn uses `easeInCubic(0,1,rand)`, which is `rand⁴` — so most
      // particles are far and only a few are close. That shows up as most
      // sprites being small: the near ones are rare by construction.
      final f = field(capacity: 2000);
      final batch = f.step(
        size: size,
        dt: 1 / 60,
        intensity: 1.0,
        fallSpeed: 1.0,
        wind: 0.0,
        opacity: 1.0,
        tint: const Color(0xFFFFFFFF),
        sizeMin: 0.0,
        sizeMax: 1.0, // so the transform's scale reads back as depth directly
        life: 3.0,
      );

      var small = 0;
      for (var p = 0; p < batch.count; p++) {
        // scos = transforms[0] is the uniform scale at zero rotation.
        final scale = batch.transforms[p * 4];
        // depth < 0.5 maps to scale < 0.5 * size.height / cell.height.
        if (scale < 0.5 * size.height / 68) small++;
      }
      // rand⁴ < 0.5 for rand < 0.84, so ~84% should be in the far half.
      expect(small / batch.count, greaterThan(0.75));
    },
  );

  test('a long stall does not teleport the field', () {
    // The widget clamps dt, but the field must also behave if handed a large
    // step — particles should stay finite and on a sane scale.
    final f = field();
    final batch = f.step(
      size: size,
      dt: 5.0,
      intensity: 1.0,
      fallSpeed: 1.0,
      wind: 0.0,
      opacity: 1.0,
      tint: const Color(0xFFFFFFFF),
      sizeMin: 0.013,
      sizeMax: 0.042,
      life: 3.0,
    );
    for (var p = 0; p < batch.count; p++) {
      expect(batch.transforms[p * 4 + 3].isFinite, isTrue);
    }
  });
}

/// A 4-cell stand-in for the rain atlas; content is irrelevant to the maths.
ui.Image _stubAtlas() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 128, 68),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  return recorder.endRecording().toImageSync(128, 68);
}
