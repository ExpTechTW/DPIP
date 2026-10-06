/// One monitor surface's view of the RTS frames: what is lit now, and the
/// minute-long ranking.
///
/// Its job is the order-of-arrival problems a surface cannot see. The frame
/// is often in hand before the station directory or the box grid has loaded,
/// and that frame must still count once they do. A stale or offline frame
/// must light nothing — it is not the ground's shaking now. And a status
/// recompute that re-delivers the same frame must not count it twice.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_alert_tracker.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:flutter_test/flutter_test.dart';

const _grid = RtsBoxGrid({
  1: [
    [121.4, 23.4],
    [121.6, 23.4],
    [121.6, 23.6],
    [121.4, 23.6],
    [121.4, 23.4],
  ],
});

const _stations = {
  'A': SeismicStation(
    id: 'A',
    latitude: 23.5,
    longitude: 121.5,
    townCode: '970',
  ),
};

const _town = Town(
  code: '970',
  city: '花蓮',
  town: '花蓮',
  lat: 23.5,
  lng: 121.5,
  cityLevel: '縣',
  townLevel: '市',
);

RealtimeState<Rts> _state(
  Rts frame, {
  RealtimeStatus status = RealtimeStatus.live,
}) => RealtimeState<Rts>(data: frame, status: status);

Rts _alerting(double intensity, int time) => Rts(
  time: time,
  stations: {'A': RtsStation(intensity: intensity, alert: true)},
);

Town? _townOf(String code) => code == '970' ? _town : null;

void main() {
  test(
    'a frame that arrived before the directory counts once it is placed',
    () {
      final tracker = RtsAlertTracker()..track(_state(_alerting(4.0, 1000)));
      expect(tracker.alerting, isFalse, reason: 'nowhere to put the station');

      tracker.place(stations: _stations, grid: _grid);

      expect(tracker.areas.boxes, {1: 4});
      expect(tracker.ranking(_townOf).single.level, 4);
    },
  );

  test('a stale frame lights nothing, and lights again once live', () {
    final frame = _alerting(4.0, 1000);
    final tracker = RtsAlertTracker()
      ..place(stations: _stations, grid: _grid)
      ..track(_state(frame, status: RealtimeStatus.stale));
    expect(tracker.alerting, isFalse);

    tracker.track(_state(frame));
    expect(tracker.alerting, isTrue);
  });

  test('the ranking outlives the alert, then ages out', () {
    final tracker = RtsAlertTracker()
      ..place(stations: _stations, grid: _grid)
      ..track(_state(_alerting(5.2, 0)))
      ..track(_state(const Rts(time: 30000)));

    expect(tracker.alerting, isFalse, reason: 'the frame has calmed');
    expect(tracker.ranking(_townOf).single.level, 6, reason: '5.2 is 5強');

    tracker.track(_state(const Rts(time: 60000)));
    expect(tracker.ranking(_townOf), isEmpty);
  });

  test('the same live frame is lit again without counting twice', () {
    final frame = _alerting(4.0, 1000);
    final tracker = RtsAlertTracker()
      ..place(stations: _stations, grid: _grid)
      ..track(_state(frame));
    expect(tracker.stations, _stations);

    tracker.place();
    tracker.track(_state(frame));

    expect(tracker.areas.boxes, {1: 4});
    expect(tracker.ranking(_townOf), hasLength(1));
  });

  test('reset forgets the window', () {
    final tracker = RtsAlertTracker()
      ..place(stations: _stations, grid: _grid)
      ..track(_state(_alerting(3.0, 0)))
      ..reset();

    expect(tracker.ranking(_townOf), isEmpty);
    expect(tracker.alerting, isFalse);
  });
}
