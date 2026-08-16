import 'dart:typed_data';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/meshtastic/data/dpip_mesh_gateway_impl.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_mesh_service.dart';

void main() {
  late FakeMeshService service;
  int? channel;

  setUp(() {
    service = FakeMeshService()..isConnected = true;
    channel = 3;
  });

  DpipMeshGatewayImpl gateway() => DpipMeshGatewayImpl(service, () => channel);

  MeshDataPacket packet(
    List<int> payload, {
    int port = MeshPorts.private,
    int ch = 3,
  }) => MeshDataPacket(
    from: 7,
    channel: ch,
    portnum: port,
    payload: payload,
    timestamp: DateTime.utc(2026),
  );

  final dpipBytes = DpipMeshCodec.encode(
    DpipMeshPacket(kind: DpipMeshKind.eew, body: Uint8List.fromList([9])),
  );

  group('inbound', () {
    test('delivers a DPIP packet on the DPIP channel', () async {
      final received = gateway().inbound.first;
      service.data.add(packet(dpipBytes));
      expect((await received).kind, DpipMeshKind.eew);
    });

    test('ignores other app ports', () async {
      final seen = <DpipMeshPacket>[];
      final sub = gateway().inbound.listen(seen.add);
      service.data
        ..add(packet(dpipBytes, port: MeshPorts.text))
        ..add(packet(dpipBytes));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen, hasLength(1));
    });

    test(
      'ignores private traffic on another channel once provisioned',
      () async {
        final seen = <DpipMeshPacket>[];
        final sub = gateway().inbound.listen(seen.add);
        service.data.add(packet(dpipBytes, ch: 0));
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        expect(seen, isEmpty);
      },
    );

    test('accepts any channel before provisioning resolves', () async {
      channel = null;
      final received = gateway().inbound.first;
      service.data.add(packet(dpipBytes, ch: 0));
      expect((await received).kind, DpipMeshKind.eew);
    });

    test('drops payloads that are not DPIP envelopes', () async {
      final seen = <DpipMeshPacket>[];
      final sub = gateway().inbound.listen(seen.add);
      service.data.add(packet([1, 2, 3, 4, 5, 6]));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen, isEmpty);
    });
  });

  group('broadcast', () {
    test('encodes onto the DPIP channel and private port', () async {
      final result = await gateway().broadcast(
        DpipMeshPacket(
          kind: DpipMeshKind.tsunami,
          schema: 4,
          body: Uint8List.fromList([1, 2]),
        ),
      );
      expect(result, isA<Ok<void>>());
      final sent = service.sentData.single;
      expect(sent.portnum, MeshPorts.private);
      expect(sent.channel, 3);
      expect(sent.payload, [0x44, 0x50, 1, 3, 4, 1, 2]);
    });

    test('fails while the DPIP channel is not provisioned', () async {
      channel = null;
      final result = await gateway().broadcast(
        DpipMeshPacket(kind: DpipMeshKind.ping, body: Uint8List(0)),
      );
      expect(result, isA<Err<void>>());
      expect(service.sentData, isEmpty);
    });

    test('fails with no radio', () async {
      service.isConnected = false;
      final result = await gateway().broadcast(
        DpipMeshPacket(kind: DpipMeshKind.ping, body: Uint8List(0)),
      );
      expect(result, isA<Err<void>>());
      expect(service.sentData, isEmpty);
    });

    test('refuses an over-long body instead of truncating it', () async {
      final result = await gateway().broadcast(
        DpipMeshPacket(
          kind: DpipMeshKind.report,
          body: Uint8List(DpipMeshCodec.maxBodyBytes + 1),
        ),
      );
      expect(result, isA<Err<void>>());
      expect(service.sentData, isEmpty);
    });
  });

  test('isReady tracks the link and the channel', () {
    expect(gateway().isReady, isTrue);
    channel = null;
    expect(gateway().isReady, isFalse);
    channel = 3;
    service.isConnected = false;
    expect(gateway().isReady, isFalse);
  });
}
