import 'dart:typed_data';

import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DpipMeshPacket packet(
    List<int> body, {
    DpipMeshKind kind = DpipMeshKind.eew,
  }) => DpipMeshPacket(kind: kind, schema: 2, body: Uint8List.fromList(body));

  group('wire format', () {
    // Pinned bytes: this is a protocol other builds (and other devices) have
    // to agree with, so a change here must be a deliberate version bump.
    test('is magic, version, kind, schema, body', () {
      expect(DpipMeshCodec.encode(packet([0xAA, 0xBB])), [
        0x44, // 'D'
        0x50, // 'P'
        1, // envelope version
        1, // DpipMeshKind.eew
        2, // body schema
        0xAA,
        0xBB,
      ]);
    });

    test('round-trips through decode', () {
      final decoded = DpipMeshCodec.decode(
        DpipMeshCodec.encode(packet([1, 2, 3], kind: DpipMeshKind.tsunami)),
        from: 42,
      );
      expect(decoded, isNotNull);
      expect(decoded!.kind, DpipMeshKind.tsunami);
      expect(decoded.schema, 2);
      expect(decoded.body, [1, 2, 3]);
      expect(decoded.from, 42);
    });

    test('carries an empty body', () {
      final decoded = DpipMeshCodec.decode(
        DpipMeshCodec.encode(packet(const [], kind: DpipMeshKind.ping)),
      );
      expect(decoded?.kind, DpipMeshKind.ping);
      expect(decoded?.body, isEmpty);
    });
  });

  group('rejects', () {
    test('anything shorter than the header', () {
      expect(DpipMeshCodec.decode([0x44, 0x50, 1, 1]), isNull);
    });

    test('foreign traffic on the private port', () {
      expect(DpipMeshCodec.decode([0x01, 0x02, 1, 1, 1, 9]), isNull);
    });

    test('an envelope version this build does not speak', () {
      final bytes = DpipMeshCodec.encode(packet([1]))..[2] = 99;
      expect(DpipMeshCodec.decode(bytes), isNull);
    });

    test('a kind this build does not know', () {
      final bytes = DpipMeshCodec.encode(packet([1]))..[3] = 0x7F;
      expect(DpipMeshCodec.decode(bytes), isNull);
    });
  });

  group('frame budget', () {
    test('accepts a body that exactly fills the frame', () {
      final body = Uint8List(DpipMeshCodec.maxBodyBytes);
      expect(
        DpipMeshCodec.encode(packet(body)).length,
        DpipMeshCodec.headerBytes + DpipMeshCodec.maxBodyBytes,
      );
    });

    test('refuses to truncate an over-long body', () {
      final body = Uint8List(DpipMeshCodec.maxBodyBytes + 1);
      expect(() => DpipMeshCodec.encode(packet(body)), throwsArgumentError);
    });
  });

  test('kind codes are the protocol and must not drift', () {
    expect(
      {for (final kind in DpipMeshKind.values) kind.name: kind.code},
      {'eew': 1, 'report': 2, 'tsunami': 3, 'weather': 4, 'ping': 9},
    );
    expect(DpipMeshKind.fromCode(3), DpipMeshKind.tsunami);
    expect(DpipMeshKind.fromCode(200), isNull);
  });

  test('the DPIP channel spec is the agreed one', () {
    expect(DpipMeshChannel.name, 'DPIP');
    expect(DpipMeshChannel.psk, [0x01]); // base64 AQ==
    expect(DpipMeshChannel.region, 'TW');
  });
}
