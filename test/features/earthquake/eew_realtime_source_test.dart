import 'dart:convert';

import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/features/earthquake/data/eew_realtime_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:flutter_test/flutter_test.dart';

/// A source with a never-emitting connection: these tests exercise the pure
/// mapping ([EewRealtimeSource.decode]) and freshness overrides, not the
/// transport (covered by `test/core/realtime/sse_realtime_source_test.dart`).
EewRealtimeSource _source({bool cwaOnly = false}) => EewRealtimeSource(
  () => const Stream<SseEvent>.empty(),
  cwaOnly: () => cwaOnly,
);

Eew _eew({int serial = 1}) => Eew(
  agency: 'cwa',
  id: '113000',
  serial: serial,
  status: 0,
  isFinal: false,
  info: const EewInfo(
    time: 1700000000000,
    longitude: 121.5,
    latitude: 23.5,
    depth: 10,
    magnitude: 6.0,
    location: 'Test',
    max: 4,
  ),
);

void main() {
  test('decode parses the SSE data: payload — same JSON as the GET', () {
    final source = _source();
    expect(source.decode('[]'), isEmpty);

    // The exact wire shape the endpoint streams (author/eq/final wire names).
    final payload = jsonEncode([
      {
        'author': 'cwa',
        'id': '113000',
        'serial': 3,
        'status': 1,
        'final': 0,
        'eq': {
          'time': 1700000000000,
          'lon': 121.5,
          'lat': 24.0,
          'depth': 10.0,
          'mag': 5.2,
          'loc': '花蓮縣',
          'max': 4,
        },
      },
    ]);
    final eews = source.decode(payload);
    expect(eews, hasLength(1));
    expect(eews.single.agency, 'cwa');
    expect(eews.single.serial, 3);
    expect(eews.single.isFinal, isFalse); // final: 0 -> false
    expect(eews.single.info.location, '花蓮縣');
  });

  test('JMA is dropped unconditionally, and cwaOnly drops every other '
      'non-CWA alert, case-insensitively, reading fresh each decode', () {
    final payload = jsonEncode([
      {
        'author': 'cwa',
        'id': 'a',
        'serial': 1,
        'status': 0,
        'final': 0,
        'eq': {
          'time': 1700000000000,
          'lon': 121.5,
          'lat': 24.0,
          'depth': 10.0,
          'mag': 5.0,
          'loc': 'CWA event',
          'max': 4,
        },
      },
      {
        // Mixed case on purpose — the wire value is lowercase in practice,
        // but the filter must not silently miss a differently-cased one.
        'author': 'CWA',
        'id': 'b',
        'serial': 1,
        'status': 0,
        'final': 0,
        'eq': {
          'time': 1700000000000,
          'lon': 121.5,
          'lat': 24.0,
          'depth': 10.0,
          'mag': 5.0,
          'loc': 'CWA event, mixed case',
          'max': 4,
        },
      },
      {
        'author': 'jma',
        'id': 'c',
        'serial': 1,
        'status': 0,
        'final': 0,
        'eq': {
          'time': 1700000000000,
          'lon': 121.5,
          'lat': 24.0,
          'depth': 10.0,
          'mag': 5.0,
          'loc': 'JMA event',
          'max': 4,
        },
      },
    ]);

    final unfiltered = _source().decode(payload);
    expect(
      unfiltered.map((e) => e.id),
      unorderedEquals(['a', 'b']),
      reason: 'cwaOnly off — every agency but JMA passes through',
    );

    var enabled = false;
    final source = EewRealtimeSource(
      () => const Stream<SseEvent>.empty(),
      cwaOnly: () => enabled,
    );
    expect(
      source.decode(payload).map((e) => e.id),
      unorderedEquals(['a', 'b']),
      reason: 'still off — the closure has not flipped yet, JMA still dropped',
    );

    enabled = true;
    expect(
      source.decode(payload).map((e) => e.id),
      unorderedEquals(['a', 'b']),
      reason:
          'flipping the same closure (mirroring EewCwaOnlySettings.enabled '
          'changing) must be reflected on the very next decode',
    );
  });

  test('timestampOf is null → the channel uses connection/fetch-freshness', () {
    expect(_source().timestampOf([_eew()]), isNull);
  });

  test('sameData compares alert content, not list identity', () {
    final source = _source();
    expect(source.sameData(const [], const []), isTrue);
    expect(source.sameData([_eew(serial: 1)], [_eew(serial: 1)]), isTrue);
    expect(source.sameData([_eew(serial: 1)], [_eew(serial: 2)]), isFalse);
    expect(source.sameData(const [], [_eew()]), isFalse);
  });
}
