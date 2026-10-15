/// Pins the EEW feed reducer: a report never regresses, an event the server
/// drops leaves at once, and one a lagging server brings back returns at its
/// newest report.
library;

import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_feed.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 16, 3);

Eew _report(
  int serial, {
  String id = 'e1',
  String agency = 'cwa',
  int status = 0,
  double magnitude = 5.0,
}) => Eew(
  agency: agency,
  id: id,
  serial: serial,
  status: status,
  isFinal: false,
  info: EewInfo(
    time: _t0.millisecondsSinceEpoch,
    longitude: 121.5,
    latitude: 23.8,
    depth: 10,
    magnitude: magnitude,
    location: '花蓮縣',
    max: 4,
  ),
);

/// Folds [frames] one second apart, returning the final state.
EewFeedState _fold(List<List<Eew>> frames, {DateTime? start}) {
  var state = EewFeedState.initial;
  var now = start ?? _t0;
  for (final frame in frames) {
    state = reduceEewFeed(state, frame, now);
    now = now.add(const Duration(seconds: 1));
  }
  return state;
}

void main() {
  test('the first snapshot is shown as it came', () {
    final state = _fold([
      [_report(1), _report(1, id: 'e2')],
    ]);
    expect(state.visible, [_report(1), _report(1, id: 'e2')]);
  });

  test('a newer serial replaces the card', () {
    final state = _fold([
      [_report(1)],
      [_report(2, magnitude: 5.4)],
    ]);
    expect(state.visible, [_report(2, magnitude: 5.4)]);
  });

  test('a lagging server cannot take a card back a serial', () {
    final state = _fold([
      [_report(3, magnitude: 6.1)],
      // Failover: the new region is a report behind.
      [_report(2, magnitude: 5.7)],
    ]);
    expect(state.visible.single.serial, 3);
    expect(state.visible.single.info.magnitude, 6.1);
  });

  test('it catches up the moment the lagging server does', () {
    final state = _fold([
      [_report(3)],
      [_report(2)],
      [_report(4)],
    ]);
    expect(state.visible.single.serial, 4);
  });

  test('an event the server drops leaves at once', () {
    final state = _fold([
      [_report(2), _report(1, id: 'e2')],
      [_report(1, id: 'e2')],
    ]);
    expect(state.visible, [_report(1, id: 'e2')]);
    expect(
      _fold([
        [_report(2)],
        [],
      ]).visible,
      isEmpty,
    );
  });

  test(
    'an event a lagging server brings back returns at its newest report',
    () {
      final state = _fold([
        [_report(3)],
        [],
        [_report(2)],
      ]);
      expect(state.visible.single.serial, 3);
    },
  );

  test('a lagging copy of the same serial cannot un-cancel an event', () {
    final state = _fold([
      [_report(4, status: 3)],
      [_report(4)],
      [_report(3)],
    ]);
    expect(state.visible.single.isCancelled, isTrue);
  });

  test('a cancel carried on an equal serial is taken', () {
    final state = _fold([
      [_report(4)],
      [_report(4, status: 3)],
    ]);
    expect(state.visible.single.isCancelled, isTrue);
  });

  test('two agencies numbering an event alike are two events', () {
    final state = _fold([
      [_report(5), _report(1, agency: 'nied')],
      [_report(4), _report(2, agency: 'nied')],
    ]);
    expect(state.visible.map((e) => (e.agency, e.serial)), [
      ('cwa', 5),
      ('nied', 2),
    ]);
  });

  test(
    'the server order is kept and a doubled event collapses to its newest',
    () {
      final state = _fold([
        [_report(1, id: 'b'), _report(2, id: 'a'), _report(3, id: 'b')],
      ]);
      expect(state.visible.map((e) => (e.id, e.serial)), [('b', 3), ('a', 2)]);
    },
  );

  test('an unchanged frame folds to an equal list', () {
    final once = _fold([
      [_report(2), _report(1, id: 'e2')],
    ]);
    final twice = reduceEewFeed(once, [_report(2), _report(1, id: 'e2')], _t0);
    expect(twice.visible, once.visible);
  });

  group('memory', () {
    test('an unlisted event is forgotten after the memory window', () {
      var state = reduceEewFeed(EewFeedState.initial, [_report(3)], _t0);
      state = reduceEewFeed(state, const [], _t0.add(EewFeedState.memory));
      expect(state.trackOf(_report(3).eventKey), isNull);
      // Nothing left to hold it back: a later listing is taken as it comes.
      state = reduceEewFeed(state, [
        _report(2),
      ], _t0.add(EewFeedState.memory + const Duration(seconds: 1)));
      expect(state.visible.single.serial, 2);
    });

    test('a listed event keeps its first sighting however long it stays', () {
      var state = reduceEewFeed(EewFeedState.initial, [_report(1)], _t0);
      final later = _t0.add(EewFeedState.memory * 2);
      state = reduceEewFeed(state, [_report(2)], later);
      expect(state.trackOf(_report(1).eventKey)!.firstSeen, _t0);
    });
  });
}
