import 'dart:convert';
import 'dart:typed_data';

import 'package:dpip/core/network/sse_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Emits [chunks] as UTF-8 byte segments, so tests can split frames (and even
/// multi-byte characters) across network chunk boundaries.
Stream<List<int>> _bytes(List<String> chunks) =>
    Stream.fromIterable(chunks.map(utf8.encode));

void main() {
  group('HttpSseClient.parse', () {
    test('parses the real EEW opening frames (retry, info, payload)', () async {
      // Exactly what the live endpoint sends on connect.
      final events = await HttpSseClient.parse(
        _bytes([
          'retry: 3000\n\n',
          'event: info\ndata: {"location":"lb-tpe1"}\n\n',
          'data: []\n\n',
        ]),
      ).toList();

      expect(events, hasLength(3));

      expect(events[0].retry, const Duration(seconds: 3));
      expect(events[0].data, isEmpty);
      expect(events[0].isDefault, isTrue);

      expect(events[1].name, 'info');
      expect(events[1].isDefault, isFalse);
      expect(events[1].data, '{"location":"lb-tpe1"}');

      expect(events[2].isDefault, isTrue);
      expect(events[2].data, '[]'); // same JSON the GET returns — format intact
    });

    test(
      'joins multiple data lines with newline, strips one trailing',
      () async {
        final events = await HttpSseClient.parse(
          _bytes(['data: a\ndata: b\n\n']),
        ).toList();
        expect(events.single.data, 'a\nb');
      },
    );

    test('skips comment / heartbeat lines', () async {
      final events = await HttpSseClient.parse(
        _bytes([': keep-alive\ndata: x\n\n']),
      ).toList();
      expect(events, hasLength(1));
      expect(events.single.data, 'x');
    });

    test(
      'reassembles a frame split across chunks, mid multi-byte char',
      () async {
        // '台' and '北' are 3 UTF-8 bytes each; cut mid-line and mid-character.
        final full = utf8.encode('data: 台北\n\n');
        final events = await HttpSseClient.parse(
          Stream.fromIterable([full.sublist(0, 8), full.sublist(8)]),
        ).toList();
        expect(events.single.data, '台北');
      },
    );

    test('strips only a single leading space after the colon', () async {
      final events = await HttpSseClient.parse(
        _bytes(['data:  x\n\n']),
      ).toList();
      expect(events.single.data, ' x');
    });

    test(
      'does not emit a frame that received no fields (double blank)',
      () async {
        final events = await HttpSseClient.parse(
          _bytes(['\n\ndata: y\n\n']),
        ).toList();
        expect(events, hasLength(1));
        expect(events.single.data, 'y');
      },
    );

    test(
      'accepts a Stream<Uint8List> (Dio response.stream runtime type)',
      () async {
        // Dio delivers the response body as Stream<Uint8List>; `Stream.transform`
        // reifies its input type from the receiver, so decoding must use
        // `utf8.decoder.bind` — this is the type the live feed actually passes,
        // and it must not throw a Utf8Decoder/StreamTransformer subtype error.
        final stream = Stream<Uint8List>.fromIterable([
          Uint8List.fromList(utf8.encode('data: []\n\n')),
        ]);
        final events = await HttpSseClient.parse(stream).toList();
        expect(events.single.data, '[]');
      },
    );
  });
}
