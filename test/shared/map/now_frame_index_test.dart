import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 8, 11, 11, 0);

/// Frames every [stepHours] hours, from [fromHours] before now to [toHours]
/// after — negative for history, positive for forecast steps.
List<MapFrame> _span(int fromHours, int toHours, {int stepHours = 1}) => [
  for (var h = fromHours; h <= toHours; h += stepHours)
    MapFrame(
      id: '$h',
      time: _now.add(Duration(hours: h)),
    ),
];

void main() {
  test('a versioned frame id keeps its valid time', () {
    final plain = parseFrameTime('1783360200');
    final versioned = parseFrameTime('1783360200@1783339200');
    expect(versioned, plain);
  });

  test('observed frames: the present is the newest one', () {
    // Radar and satellite stop at the present, so nothing changes for them.
    final frames = _span(-24, 0, stepHours: 1);
    expect(nowFrameIndex(frames, now: _now), frames.length - 1);
  });

  test('a forecast puts the present on the newest step that has arrived', () {
    // GFS as served: two days back, sixteen days forward.
    final frames = _span(-48, 384, stepHours: 3);
    final i = nowFrameIndex(frames, now: _now);
    expect(frames[i].time, _now);
    expect(i, greaterThan(0), reason: 'history sits to the left');
    expect(
      i,
      lessThan(frames.length - 1),
      reason: 'the forecast must remain to the right, or there is none to see',
    );
  });

  test('a forecast step in the future is never the present', () {
    // 21:43 with 3-hourly steps on 20:00 / 23:00: the present is the already-
    // due 20:00, not the nearer-in-absolute-terms 23:00 — a prediction must
    // not read as current before it has happened.
    final now = DateTime(2026, 8, 11, 21, 43);
    final frames = [
      MapFrame(id: 'a', time: DateTime(2026, 8, 11, 20, 0)),
      MapFrame(id: 'b', time: DateTime(2026, 8, 11, 23, 0)),
    ];
    expect(nowFrameIndex(frames, now: now), 0);
  });

  test('picks the newest frame at or before now', () {
    // Nearest in absolute terms is b (+1 h), but the present is the newest
    // frame that has actually arrived — a (−2 h).
    final frames = [
      MapFrame(id: 'a', time: _now.subtract(const Duration(hours: 2))),
      MapFrame(id: 'b', time: _now.add(const Duration(hours: 1))),
      MapFrame(id: 'c', time: _now.add(const Duration(hours: 4))),
    ];
    expect(nowFrameIndex(frames, now: _now), 0);
  });

  test('an entirely future set answers with its first step', () {
    expect(nowFrameIndex(_span(6, 48, stepHours: 6), now: _now), 0);
  });

  test('an empty set answers 0 rather than throwing', () {
    expect(nowFrameIndex(const [], now: _now), 0);
  });
}
