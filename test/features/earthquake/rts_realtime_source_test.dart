import 'dart:convert';

import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/features/earthquake/data/rts_realtime_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// A source with a never-emitting connection: these tests exercise the pure
/// mapping ([RtsRealtimeSource.decode]) and the freshness override, not the
/// transport (covered by `test/core/realtime/sse_realtime_source_test.dart`).
RtsRealtimeSource _source() =>
    RtsRealtimeSource(() => const Stream<SseEvent>.empty());

void main() {
  test('decode parses the SSE data: payload — same JSON as the GET', () {
    final data = jsonEncode({
      'station': {
        '2012144': {'pga': 2.79, 'pgv': 0.52, 'i': -2.9, 'I': -3},
      },
      'box': <String, dynamic>{},
      'int': <dynamic>[],
      'time': 1783968266383,
    });

    final rts = _source().decode(data);
    expect(rts.time, 1783968266383);
    expect(rts.station['2012144']!.intensity, -3);
  });

  test('timestampOf is null → event-recency freshness, not payload age', () {
    final rts = _source().decode(jsonEncode({'time': 1783968266383}));
    expect(_source().timestampOf(rts), isNull);
  });
}
