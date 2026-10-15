/// Pins which of several simultaneous alerts the Home card shows and the
/// monitor speaks: in progress before cancelled, still-to-arrive before
/// arrived, stronger before weaker, newer before older.
library;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_priority.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime.utc(2026, 10, 16, 3);

/// Taipei — about 125 km from the Hualien epicentre below.
const LatLng _taipei = LatLng(25.03, 121.52);

Eew _alert(
  String id, {
  LatLng epicentre = const LatLng(23.9, 121.6),
  Duration age = Duration.zero,
  double magnitude = 6.0,
  int max = 5,
  int status = 0,
  int? reportTime,
}) => Eew(
  agency: 'cwa',
  id: id,
  serial: 1,
  status: status,
  isFinal: false,
  reportTime: reportTime,
  info: EewInfo(
    time: _now.subtract(age).millisecondsSinceEpoch,
    longitude: epicentre.longitude,
    latitude: epicentre.latitude,
    depth: 10,
    magnitude: magnitude,
    location: id,
    max: max,
  ),
);

List<String> _ids(List<RankedEew> ranked) => [
  for (final entry in ranked) entry.alert.id,
];

void main() {
  test('nothing ranks to nothing', () {
    expect(rankEews(const [], now: _now), isEmpty);
    expect(primaryEew(const [], now: _now), isNull);
  });

  test('a cancelled alert ranks after every alert still in progress, however '
      'strong it was', () {
    final ranked = rankEews([
      _alert('cancelled', max: 7, magnitude: 7, status: 3),
      _alert('weak', max: 2, magnitude: 4),
    ], now: _now);
    expect(_ids(ranked), ['weak', 'cancelled']);
    expect(ranked.last.estimate, isNull);
  });

  test('a cancelled alert has no estimate even with an observer', () {
    final ranked = rankEews(
      [_alert('gone', status: 2)],
      now: _now,
      observer: _taipei,
    );
    expect(ranked.single.estimate, isNull);
    expect(ranked.single.arrival, isNull);
  });

  test('with an observer, an S wave still on its way outranks a stronger one '
      'that has already arrived', () {
    final arrived = _alert(
      'arrived',
      epicentre: const LatLng(25.0, 121.5), // under Taipei
      age: const Duration(seconds: 60),
      magnitude: 6.5,
    );
    final coming = _alert('coming', magnitude: 5.0); // Hualien, just now
    final ranked = rankEews([arrived, coming], now: _now, observer: _taipei);
    expect(_ids(ranked), ['coming', 'arrived']);
    expect(ranked.first.arrivedAt(_now), isFalse);
    expect(ranked.last.arrivedAt(_now), isTrue);
    expect(
      ranked.last.estimate!.intensity,
      greaterThan(ranked.first.estimate!.intensity),
      reason: 'the arrived one really was the stronger here',
    );
  });

  test('among alerts still to arrive, the stronger shaking at the observer '
      'comes first', () {
    final near = _alert('near', epicentre: const LatLng(24.9, 121.6));
    final far = _alert('far', epicentre: const LatLng(22.0, 120.8));
    expect(_ids(rankEews([far, near], now: _now, observer: _taipei)), [
      'near',
      'far',
    ]);
  });

  test('without an observer, the agency maximum intensity decides', () {
    expect(_ids(rankEews([_alert('four', max: 4), _alert('six', max: 6)])), [
      'six',
      'four',
    ]);
  });

  test('an equal tie goes to the newer report, then keeps feed order', () {
    final older = _alert('older', reportTime: 1000);
    final newer = _alert('newer', reportTime: 2000);
    expect(_ids(rankEews([older, newer], now: _now)), ['newer', 'older']);
    // No report time: the newer origin stands in for it.
    final early = _alert('early', age: const Duration(seconds: 20));
    final late = _alert('late', age: const Duration(seconds: 5));
    expect(_ids(rankEews([early, late], now: _now)), ['late', 'early']);
    // Identical in every respect: the feed's order.
    expect(_ids(rankEews([_alert('a'), _alert('b'), _alert('c')], now: _now)), [
      'a',
      'b',
      'c',
    ]);
  });

  test('without a clock, arrival is not weighed', () {
    final arrived = _alert(
      'arrived',
      epicentre: const LatLng(25.0, 121.5),
      age: const Duration(seconds: 60),
    );
    final coming = _alert('coming', magnitude: 5.0);
    expect(_ids(rankEews([coming, arrived], observer: _taipei)), [
      'arrived',
      'coming',
    ]);
  });

  test('primaryEew is the head of the ranking', () {
    expect(
      primaryEew([
        _alert('cancelled', status: 3),
        _alert('live'),
      ], now: _now)!.id,
      'live',
    );
    expect(primaryEew([_alert('only', status: 3)])!.id, 'only');
  });
}
