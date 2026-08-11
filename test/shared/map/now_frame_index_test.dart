import 'package:dpip/shared/map/map_layer.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 8, 11, 11, 0);

/// Frames every [stepHours] hours, from [fromHours] before now to [toHours]
/// after — negative for history, positive for forecast steps.
List<MapFrame> _span(int fromHours, int toHours, {int stepHours = 1}) => [
  for (var h = fromHours; h <= toHours; h += stepHours)
    MapFrame(id: '$h', time: _now.add(Duration(hours: h))),
];

void main() {
  test('observed frames: the present is the newest one', () {
    // Radar and satellite stop at the present, so nothing changes for them.
    final frames = _span(-24, 0, stepHours: 1);
    expect(nowFrameIndex(frames, now: _now), frames.length - 1);
  });

  test('a forecast puts the present in the middle of its own range', () {
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

  test('picks the nearest step when none lands exactly on now', () {
    // Three-hourly ECMWF steps straddling a present that falls between two.
    final frames = [
      MapFrame(id: 'a', time: _now.subtract(const Duration(hours: 2))),
      MapFrame(id: 'b', time: _now.add(const Duration(hours: 1))),
      MapFrame(id: 'c', time: _now.add(const Duration(hours: 4))),
    ];
    expect(nowFrameIndex(frames, now: _now), 1);
  });

  test('an entirely future set answers with its first step', () {
    expect(nowFrameIndex(_span(6, 48, stepHours: 6), now: _now), 0);
  });

  test('an empty set answers 0 rather than throwing', () {
    expect(nowFrameIndex(const [], now: _now), 0);
  });
}
