/// [DpipMeshGateway] over the BLE [MeshtasticService].
///
/// Thin by design: envelope in, envelope out, plus the two guards that keep
/// foreign traffic off the feed. The DPIP channel index is resolved lazily
/// through a callback because it is discovered at provisioning time (see
/// `MeshLink`) and changes when the radio changes.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh_gateway.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';

class DpipMeshGatewayImpl implements DpipMeshGateway {
  DpipMeshGatewayImpl(this._service, this._dpipChannel);

  final MeshtasticService _service;

  /// The provisioned DPIP channel index, or null before provisioning.
  final int? Function() _dpipChannel;

  @override
  Stream<DpipMeshPacket> get inbound => _service.dataStream
      .where((packet) => packet.portnum == MeshPorts.private)
      .where(_onDpipChannel)
      .map(
        (packet) => DpipMeshCodec.decode(
          packet.payload,
          from: packet.from,
          receivedAt: packet.timestamp,
        ),
      )
      .where((packet) => packet != null)
      .cast<DpipMeshPacket>()
      .map((packet) {
        Log.info('dpip mesh: received $packet');
        return packet;
      });

  /// Before provisioning resolves we can't tell which index is DPIP, so let
  /// the envelope check be the filter; afterwards, hold the line.
  bool _onDpipChannel(MeshDataPacket packet) {
    final channel = _dpipChannel();
    if (channel == null || packet.channel == channel) return true;
    Log.debug(
      'dpip mesh: ignoring private-port packet on channel ${packet.channel}',
    );
    return false;
  }

  @override
  bool get isReady => _service.isConnected && _dpipChannel() != null;

  @override
  Future<Result<void>> broadcast(DpipMeshPacket packet) async {
    final channel = _dpipChannel();
    if (channel == null) {
      return const Err(UnexpectedFailure('The DPIP channel is not ready'));
    }
    if (!_service.isConnected) {
      return const Err(UnexpectedFailure('No radio connected'));
    }
    final List<int> bytes;
    try {
      bytes = DpipMeshCodec.encode(packet);
    } on ArgumentError catch (error) {
      Log.warning('dpip mesh: refusing to send $packet — ${error.message}');
      return Err(UnexpectedFailure('${error.message}'));
    }
    Log.info('dpip mesh: broadcasting $packet on channel $channel');
    return _service.sendData(
      portnum: MeshPorts.private,
      payload: bytes,
      channel: channel,
    );
  }
}
