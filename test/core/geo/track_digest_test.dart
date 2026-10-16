/// The digest is what keeps the track layer cheap on a cheap phone: whatever
/// the history holds, the map is handed a bounded number of strokes, and a
/// recording gap is never drawn as a road.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:dpip/core/geo/location_track.dart';
import 'package:dpip/core/geo/track_digest.dart';
import 'package:flutter_test/flutter_test.dart';

import 'location_track_fixture.dart';

/// Base time for synthetic fixes: 2026-01-01T00:00Z.
const _t0 = 1767225600;

TrackDigest _digest(
  List<(int, int, int)> fixes, {
  int budget = TrackDigestBuilder.defaultBudget,
}) {
  final builder = TrackDigestBuilder(budget: budget);
  for (final (t, lat, lng) in fixes) {
    builder.add(t, lat, lng);
  }
  return builder.build();
}

/// A straight walk of [count] fixes a minute apart, each [step] stored units
/// (1e-4°) north-east of the last.
List<(int, int, int)> _walk(
  int count, {
  int from = _t0,
  int lat = 250330,
  int lng = 1215654,
  int step = 3,
  int every = 60,
}) => [
  for (var i = 0; i < count; i++)
    (from + i * every, lat + i * step, lng + i * step),
];

void main() {
  test('nothing in, nothing to draw', () {
    final digest = _digest(const []);
    expect(digest.isEmpty, isTrue);
    expect(digest.segments, isEmpty);
    expect(digest.dots, isEmpty);
    expect(digest.latest, isNull);
    expect(digest.bounds, isNull);
  });

  test('a short window is drawn exactly as recorded', () {
    final fixes = _walk(50);
    final digest = _digest(fixes);
    expect(digest.cellE4, 1, reason: 'nothing needed merging');
    expect(digest.fixes, 50);
    expect(digest.segments, hasLength(49));
    expect(digest.dots, isEmpty);
    // The endpoints are the recorded fixes, never a cell's stand-in.
    expect(digest.first!.latitude, closeTo(25.0330, 1e-9));
    expect(digest.latest!.latitude, closeTo(25.0330 + 49 * 3e-4, 1e-9));
    expect(digest.latest!.time.millisecondsSinceEpoch ~/ 1000, _t0 + 49 * 60);
    final bounds = digest.bounds!;
    expect(bounds.south, closeTo(25.0330, 1e-9));
    expect(bounds.north, closeTo(25.0330 + 49 * 3e-4, 1e-9));
    expect(bounds.west, closeTo(121.5654, 1e-9));
    expect(bounds.east, closeTo(121.5654 + 49 * 3e-4, 1e-9));
  });

  group('gaps', () {
    test('fixes more than two hours apart are not joined', () {
      // Home in the evening, then the first fix two towns away the next
      // morning: a straight line between them is a road nobody drove.
      final evening = _walk(5);
      final morning = _walk(5, from: _t0 + 10 * 3600, lat: 240000);
      final digest = _digest([...evening, ...morning]);
      expect(digest.segments, hasLength(8));
      for (final segment in digest.segments) {
        final crosses =
            (segment.fromLatitude < 24.5) != (segment.toLatitude < 24.5);
        expect(crosses, isFalse, reason: 'a stroke spans the gap');
      }
    });

    test('exactly two hours apart is still one movement', () {
      final digest = _digest([
        (_t0, 250000, 1210000),
        (_t0 + 2 * 3600, 250100, 1210100),
      ]);
      expect(digest.segments, hasLength(1));
    });

    test('a lone fix between two silences is kept as a dot', () {
      final digest = _digest([
        ..._walk(3),
        (_t0 + 6 * 3600, 240000, 1200000),
        ..._walk(3, from: _t0 + 12 * 3600, lat: 230000),
      ]);
      expect(digest.segments, hasLength(4));
      expect(digest.dots, hasLength(1));
      expect(digest.dots.single.latitude, closeTo(24.0, 1e-9));
      expect(digest.dots.single.longitude, closeTo(120.0, 1e-9));
    });

    test('a clock set backwards is a step, not a gap', () {
      final digest = _digest([
        (_t0, 250000, 1210000),
        (_t0 - 60, 250010, 1210010),
      ]);
      expect(digest.segments, hasLength(1));
    });
  });

  test('a repeated route costs what it costs once, and is as new as today', () {
    // A hundred days of the same commute is the shape of a long history, and
    // the reason the digest keeps distinct strokes rather than every pass.
    final once = _digest(_walk(40));
    final daily = _digest([
      for (var day = 0; day < 100; day++) ..._walk(40, from: _t0 + day * 86400),
    ]);
    expect(daily.fixes, 4000);
    expect(daily.segments, hasLength(once.segments.length));
    expect(daily.cellE4, 1);
    final newest = daily.segments
        .map((segment) => segment.time.millisecondsSinceEpoch ~/ 1000)
        .reduce(math.max);
    expect(newest, _t0 + 99 * 86400 + 39 * 60);
  });

  group('the budget', () {
    test('holds however long the history is', () {
      // Two hundred thousand fixes wandering over the whole island — far more
      // distinct places than the budget, so the grid has to coarsen.
      final random = math.Random(7);
      var lat = 240000;
      var lng = 1210000;
      final fixes = <(int, int, int)>[];
      for (var i = 0; i < 200000; i++) {
        lat = (lat + random.nextInt(201) - 100).clamp(219000, 253000);
        lng = (lng + random.nextInt(201) - 100).clamp(1200000, 1220000);
        fixes.add((_t0 + i * 120, lat, lng));
      }
      const budget = 600;
      final digest = _digest(fixes, budget: budget);
      expect(digest.fixes, fixes.length);
      expect(digest.cellE4, greaterThan(1));
      expect(
        digest.segments.length + digest.dots.length,
        lessThanOrEqualTo(budget),
      );
      // The exact ends survive the thinning.
      expect(digest.latest!.latitude, closeTo(fixes.last.$2 / 10000, 1e-9));
      expect(digest.first!.longitude, closeTo(fixes.first.$3 / 10000, 1e-9));
      for (final segment in digest.segments) {
        expect(
          segment.fromLatitude == segment.toLatitude &&
              segment.fromLongitude == segment.toLongitude,
          isFalse,
          reason: 'a stroke that goes nowhere draws nothing',
        );
      }
    });

    test('coarsening never joins across a gap', () {
      // Two dense clusters with a long silence between them: however coarse the
      // grid gets, no stroke may connect them.
      final north = _walk(3000, lat: 250000, step: 2);
      final south = _walk(
        3000,
        from: _t0 + 3000 * 60 + 5 * 3600,
        lat: 220000,
        step: 2,
      );
      final digest = _digest([...north, ...south], budget: 100);
      expect(digest.cellE4, greaterThan(1));
      for (final segment in digest.segments) {
        final crosses =
            (segment.fromLatitude < 23.5) != (segment.toLatitude < 23.5);
        expect(crosses, isFalse);
      }
    });

    test('cells nest across the equator and the antimeridian', () {
      // `>>` floors, so a negative coordinate snaps to the cell below zero —
      // the property the exact re-snap relies on.
      final digest = _digest([
        for (var i = 0; i < 2000; i++)
          (_t0 + i * 60, -1000 + i * 3, -1799000 + i * 5),
      ], budget: 64);
      expect(digest.fixes, 2000);
      expect(
        digest.segments.length + digest.dots.length,
        lessThanOrEqualTo(64),
      );
      expect(digest.bounds!.south, closeTo(-0.1, 1e-9));
      expect(digest.bounds!.west, closeTo(-179.9, 1e-9));
    });
  });

  group('read', () {
    late Directory dir;
    late String path;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('track_digest_test');
      path = '${dir.path}/location_track.db';
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('summarises only the window, off the calling isolate', () async {
      final fixes = [
        for (final (t, lat, lng) in _walk(300)) (t, lat / 10000, lng / 10000),
      ];
      writeTrackFixture(path, fixes);
      final track = LocationTrack.at(path)!;
      addTearDown(track.close);

      final from = DateTime.fromMillisecondsSinceEpoch(
        (_t0 + 200 * 60) * 1000,
        isUtc: true,
      );
      final digest = await TrackDigest.read(track, from);
      expect(digest.fixes, (await track.since(from)).length);
      expect(digest.fixes, 100);
      expect(digest.first!.time, from);
      expect(digest.segments, hasLength(99));
    });
  });
}
