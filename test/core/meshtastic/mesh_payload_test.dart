/// Rendering a mesh packet body, which is only sometimes text.
///
/// `TEXT_MESSAGE_APP` is a port number, not a promise. Anything can be sent on
/// it, and the decoder used to run `utf8.decode(payload, allowMalformed: true)`
/// — which substitutes U+FFFD per bad sequence and drops the bytes on the
/// floor. A binary body arrived in the chat as a row of  that nothing could
/// undo, because by then the only copy of the bytes was gone.
library;

import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('render', () {
    test('valid utf-8 is text, and stays exactly itself', () {
      // 你好 — the multi-byte case the strict decode must not reject.
      const bytes = [0xe4, 0xbd, 0xa0, 0xe5, 0xa5, 0xbd];

      expect(MeshPayload.render(bytes), ('你好', false));
    });

    test('an invalid sequence becomes hex, not U+FFFD', () {
      // 0xff cannot begin a UTF-8 sequence.
      final (text, binary) = MeshPayload.render(const [0x01, 0xff, 0x02]);

      expect(binary, isTrue);
      expect(text, '01 ff 02');
      expect(text, isNot(contains('�')));
    });

    test('a truncated multi-byte sequence is binary', () {
      // The first two thirds of 你 — what a cut-short packet looks like.
      expect(MeshPayload.render(const [0xe4, 0xbd]).$2, isTrue);
    });

    test('an empty body is empty text, not an empty hex dump', () {
      // The bubble has its own placeholder for this, and routing it through
      // the binary label instead would read as "0 B of binary".
      expect(MeshPayload.render(const []), ('', false));
    });

    test('a protobuf misdirected onto the text port is binary', () {
      // Every byte here is below 0x80, so this decodes cleanly and the strict
      // UTF-8 test alone calls it text — six control characters that draw as
      // tofu, which is exactly the symptom this all exists to remove.
      final (text, binary) = MeshPayload.render(const [
        0x08,
        0x01,
        0x10,
        0x05,
        0x18,
        0x02,
      ]);

      expect(binary, isTrue);
      expect(text, '08 01 10 05 18 02');
    });

    test('tab, newline and carriage return are things people send', () {
      // The C0 rule has to stop here or a multi-line message becomes a dump.
      expect(MeshPayload.render('a\tb\nc\r\nd'.codeUnits), (
        'a\tb\nc\r\nd',
        false,
      ));
    });

    test('DEL is not', () {
      expect(MeshPayload.render(const [0x41, 0x7f]).$2, isTrue);
    });

    test('a lone BOM is binary, not an empty message', () {
      // utf8.decode swallows a leading BOM, so this decodes to '' — and the
      // bubble would report a three-byte packet as an empty one.
      final (text, binary) = MeshPayload.render(const [0xef, 0xbb, 0xbf]);

      expect(binary, isTrue);
      expect(text, 'ef bb bf');
    });

    test('a hex dump of text is still text', () {
      // The one thing that must NOT happen: a dump round-tripping into the
      // decoder and being classified as binary a second time.
      final (dump, _) = MeshPayload.render(const [0x01, 0xff]);

      expect(MeshPayload.render(dump.codeUnits), (dump, false));
    });
  });

  group('hex', () {
    test('every byte is two lowercase digits', () {
      expect(MeshPayload.hex(const [0x00, 0x0f, 0xa0, 0xff]), '00 0f a0 ff');
    });

    test('no bytes is the empty string, not a stray space', () {
      expect(MeshPayload.hex(const []), '');
    });

    test('the dump pastes into xxd -r -p', () {
      // Space-separated pairs is the format every hex tool accepts, which is
      // the whole reason for the shape — a copied dump has to be usable.
      expect(
        MeshPayload.hex(const [0x48, 0x69]).split(' '),
        everyElement(matches(RegExp(r'^[0-9a-f]{2}$'))),
      );
    });
  });

  group('hexBytes', () {
    test('counts what hex produced, for every length up to a full packet', () {
      // 233 is MeshPorts.maxPayloadBytes. 0 is included deliberately: the
      // count is derived from string length, and an empty dump is the one
      // input where an off-by-one would not be caught by any other case.
      for (var n = 0; n <= MeshPorts.maxPayloadBytes; n++) {
        final bytes = List.filled(n, 0xab);

        expect(
          MeshPayload.hexBytes(MeshPayload.hex(bytes)),
          n,
          reason: '$n byte(s) did not round-trip',
        );
      }
    });
  });
}
