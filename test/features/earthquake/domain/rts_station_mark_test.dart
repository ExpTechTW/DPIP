/// Which stations the 強震監視器 draws, and how — TREM-Lite's rules.
///
/// The failure this pins is the one that looks deliberate: hiding calm
/// stations whenever an event lights a box. Without an EEW that empties the
/// map of the very network that is still reporting, and the monitor looks as
/// if half its stations went down. Only an EEW earns the declutter.
library;

import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_station_mark.dart';
import 'package:flutter_test/flutter_test.dart';

RtsStationMark? _mark(
  RtsStation reading, {
  bool eventLit = false,
  bool eewActive = false,
}) => rtsStationMark(reading, eventLit: eventLit, eewActive: eewActive);

void main() {
  const calm = RtsStation(intensity: 0.4);
  const shaking = RtsStation(intensity: 4.6, alert: true);
  const alertingThreshold = RtsStation(intensity: 0.2, alert: true);

  test('without an EEW every station is drawn, calm ones by their reading', () {
    for (final lit in [false, true]) {
      final mark = _mark(calm, eventLit: lit);
      expect(mark?.kind, RtsStationMarkKind.dot, reason: 'eventLit: $lit');
      expect(mark?.colorValue, 0.4);
    }
  });

  test('with an EEW out, a station outside the lit event is not drawn', () {
    expect(_mark(calm, eewActive: true), isNull);
    expect(_mark(calm, eventLit: true, eewActive: true), isNull);
    expect(
      _mark(shaking, eewActive: true),
      isNull,
      reason: 'alerting, but no box is lit',
    );
  });

  test('an alerting station in a lit event wears its badge, EEW or not', () {
    for (final eew in [false, true]) {
      final mark = _mark(shaking, eventLit: true, eewActive: eew);
      expect(mark?.kind, RtsStationMarkKind.badge);
      expect(mark?.level, 5, reason: '4.6 is 5弱');
    }
  });

  test('only an EEW reading at least 0.2 becomes a grey dot', () {
    expect(
      _mark(alertingThreshold, eventLit: true)?.kind,
      RtsStationMarkKind.dot,
    );
    expect(
      _mark(alertingThreshold, eventLit: true, eewActive: true)?.kind,
      RtsStationMarkKind.grey,
    );

    for (final intensity in [0.19, 0.0, -0.1]) {
      expect(
        _mark(
          RtsStation(intensity: intensity, alert: true),
          eventLit: true,
          eewActive: true,
        )?.kind,
        RtsStationMarkKind.dot,
        reason: 'intensity: $intensity',
      );
    }
  });

  test('an alerting station outside any lit box is an ordinary dot', () {
    final mark = _mark(shaking);
    expect(mark?.kind, RtsStationMarkKind.dot);
    expect(mark?.colorValue, 4.6);
  });
}
