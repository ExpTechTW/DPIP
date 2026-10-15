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
  double depth = 10,
  DateTime? origin,
}) => Eew(
  agency: agency,
  id: id,
  serial: serial,
  status: status,
  isFinal: false,
  info: EewInfo(
    time: (origin ?? _t0).millisecondsSinceEpoch,
    longitude: 121.5,
    latitude: 23.8,
    depth: depth,
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
      final later = _t0.add(EewFeedState.memory + const Duration(seconds: 1));
      state = reduceEewFeed(state, [_report(2, origin: later)], later);
      expect(state.visible.single.serial, 2);
    });

    test('a listed event keeps its first sighting however long it stays', () {
      var state = reduceEewFeed(EewFeedState.initial, [_report(1)], _t0);
      final later = _t0.add(EewFeedState.memory * 2);
      state = reduceEewFeed(state, [_report(2)], later);
      expect(state.trackOf(_report(1).eventKey)!.firstSeen, _t0);
    });
  });

  group('expiry backstop', () {
    /// Lists [report] continuously from its origin and reports whether it is
    /// still shown at [after] — the server never drops it, which is the case
    /// the backstop exists for.
    bool shownAt(Eew report, Duration after) {
      final origin = DateTime.fromMillisecondsSinceEpoch(
        report.info.time,
        isUtc: true,
      );
      var state = reduceEewFeed(EewFeedState.initial, [report], origin);
      state = reduceEewFeed(state, [report], origin.add(after));
      return state.visible.isNotEmpty;
    }

    test('an ordinary event goes 250 s after its origin', () {
      final report = _report(1);
      expect(shownAt(report, const Duration(seconds: 249)), isTrue);
      expect(shownAt(report, const Duration(seconds: 250)), isFalse);
      expect(EewExpiry.lifetimeOf(report), EewExpiry.standard);
    });

    test('a deep, a large and a 警報 event each get 400 s', () {
      for (final report in [
        _report(1, depth: 150),
        _report(1, magnitude: 6.0),
        _report(1, status: 1),
      ]) {
        expect(EewExpiry.lifetimeOf(report), EewExpiry.extended);
        expect(shownAt(report, const Duration(seconds: 399)), isTrue);
        expect(shownAt(report, const Duration(seconds: 400)), isFalse);
      }
      expect(
        EewExpiry.lifetimeOf(_report(1, depth: 149.9)),
        EewExpiry.standard,
      );
      expect(
        EewExpiry.lifetimeOf(_report(1, magnitude: 5.9)),
        EewExpiry.standard,
      );
    });

    test('expiry is measured from the origin, not from arrival', () {
      // An event first heard of 200 s after its origin still goes at 250 s.
      final report = _report(1);
      var state = reduceEewFeed(EewFeedState.initial, [
        report,
      ], _t0.add(const Duration(seconds: 200)));
      expect(state.visible, [report]);
      state = reduceEewFeed(state, [
        report,
      ], _t0.add(const Duration(seconds: 250)));
      expect(state.visible, isEmpty);
    });

    test('a cancel stays up 180 s from when it was first seen, however often '
        'the same frame repeats', () {
      final live = _report(1);
      final cancel = _report(2, status: 3);
      var state = reduceEewFeed(EewFeedState.initial, [live], _t0);
      final seen = _t0.add(const Duration(seconds: 20));
      state = reduceEewFeed(state, [cancel], seen);
      for (var s = 1; s < 180; s++) {
        state = reduceEewFeed(state, [cancel], seen.add(Duration(seconds: s)));
        expect(state.visible, [cancel], reason: 'still up at +$s s');
      }
      state = reduceEewFeed(state, [
        cancel,
      ], seen.add(const Duration(seconds: 180)));
      expect(state.visible, isEmpty);
      expect(state.trackOf(cancel.eventKey)!.cancelledSince, seen);
    });

    test('an event first heard of already cancelled gets the same window', () {
      final cancel = _report(2, status: 3);
      var state = reduceEewFeed(EewFeedState.initial, [cancel], _t0);
      state = reduceEewFeed(state, [
        cancel,
      ], _t0.add(const Duration(seconds: 179)));
      expect(state.visible, [cancel]);
      state = reduceEewFeed(state, [
        cancel,
      ], _t0.add(const Duration(seconds: 180)));
      expect(state.visible, isEmpty);
    });

    test('an origin far in the future cannot hold an event past an hour', () {
      final report = _report(1, origin: _t0.add(const Duration(days: 1)));
      var state = reduceEewFeed(EewFeedState.initial, [report], _t0);
      state = reduceEewFeed(state, [
        report,
      ], _t0.add(const Duration(minutes: 59)));
      expect(state.visible, [report]);
      state = reduceEewFeed(state, [report], _t0.add(EewExpiry.hardCap));
      expect(state.visible, isEmpty);
    });

    test('an expired event stays remembered while it is listed, so the cap '
        'is not re-armed by forgetting it', () {
      final report = _report(1, origin: _t0.add(const Duration(days: 1)));
      var state = reduceEewFeed(EewFeedState.initial, [report], _t0);
      state = reduceEewFeed(state, [report], _t0.add(EewExpiry.hardCap * 3));
      expect(state.visible, isEmpty);
      expect(state.trackOf(report.eventKey)!.firstSeen, _t0);
    });

    test('a newer serial cannot bring an expired event back', () {
      var state = reduceEewFeed(EewFeedState.initial, [_report(1)], _t0);
      state = reduceEewFeed(state, [
        _report(9),
      ], _t0.add(const Duration(seconds: 300)));
      expect(state.visible, isEmpty);
    });
  });
}
