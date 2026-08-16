/// The seam between DPIP's disaster feeds and the mesh.
///
/// Both directions in one interface, deliberately:
///
/// - **App → mesh** ([broadcast]): a device that still has internet re-emits
///   an alert onto the mesh, so nodes that have none still get it. Whoever
///   owns a feed (EEW, tsunami, …) encodes its own body and hands over a
///   [DpipMeshPacket] — the gateway knows nothing about the contents.
/// - **Mesh → app** ([inbound]): every DPIP packet the radio decodes, already
///   unwrapped from its envelope. A feed subscribes, decodes its own body, and
///   decides what to show. The gateway never notifies or renders.
///
/// Keeping this an interface (with the transport behind it) means a feed
/// depends on "DPIP packets in and out", not on Bluetooth: the same seam can
/// later carry a serial, TCP or MQTT link, and tests can pump packets through
/// without a radio.
///
/// **The gateway is not a delivery guarantee.** LoRa is a lossy, duty-cycle
/// limited broadcast medium with no acknowledgement in this direction; a
/// safety-critical feed must treat mesh delivery as best-effort — one more
/// path, never the only one, and never proof that a peer received anything.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';

abstract class DpipMeshGateway {
  /// DPIP packets decoded from the mesh, in arrival order.
  ///
  /// Broadcast: several feeds can listen at once. Packets that fail the
  /// envelope check (foreign traffic on the private port, an unknown kind, a
  /// newer envelope version) never reach here.
  Stream<DpipMeshPacket> get inbound;

  /// Broadcasts [packet] on the DPIP channel.
  ///
  /// Fails when the radio is not connected, the DPIP channel isn't
  /// provisioned yet, or the body exceeds [DpipMeshCodec.maxBodyBytes].
  Future<Result<void>> broadcast(DpipMeshPacket packet);

  /// Whether a broadcast could go out right now — the radio is connected and
  /// the DPIP channel exists on it.
  bool get isReady;
}
