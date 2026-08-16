/// The DPIP-over-Meshtastic wire contract: what a DPIP packet looks like on
/// the mesh, and the channel it travels on.
///
/// DPIP rides `PRIVATE_APP` (256), never `TEXT_MESSAGE_APP` — disaster
/// payloads must never land in anyone's chat, and other Meshtastic clients
/// must be able to ignore them by port alone.
///
/// The frame is deliberately tiny. One LoRa frame carries
/// [MeshPorts.maxPayloadBytes]; at long-range presets airtime is the scarcest
/// resource on the mesh and a node may only transmit a few percent of the
/// time, so an envelope of five bytes is the whole budget that can be spent on
/// framing:
///
/// ```text
/// ┌──────┬──────┬─────────┬──────┬────────┬───────────────────────────┐
/// │ 'D'  │ 'P'  │ version │ kind │ schema │ body (≤ maxBodyBytes)     │
/// └──────┴──────┴─────────┴──────┴────────┴───────────────────────────┘
///    0      1        2       3       4      5…
/// ```
///
/// - `version` versions **this envelope**. A receiver drops an envelope it
///   doesn't know rather than guessing.
/// - `kind` says which disaster feed the body belongs to ([DpipMeshKind]).
/// - `schema` versions **that kind's body** independently, so one feed's
///   payload can evolve without a flag day across the mesh.
///
/// The transport never fragments: a body that doesn't fit is that kind's
/// problem to solve (send a digest and a fetch id, not the whole report).
library;

import 'dart:typed_data';

import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';

/// Which DPIP feed a packet carries. The numbers are **wire codes** — they are
/// the protocol, so never renumber one; retire it and add a new code.
enum DpipMeshKind {
  /// Earthquake early warning.
  eew(1),

  /// Earthquake report (post-event).
  report(2),

  /// Tsunami advisory.
  tsunami(3),

  /// Weather alert.
  weather(4),

  /// Liveness probe — carries no meaning beyond "a DPIP node is here".
  ping(9);

  const DpipMeshKind(this.code);

  /// The byte written to the wire.
  final int code;

  /// The kind for a wire [code], or null when this build doesn't know it (a
  /// newer app on the mesh sending a feed we don't handle yet).
  static DpipMeshKind? fromCode(int code) =>
      DpipMeshKind.values.where((k) => k.code == code).firstOrNull;
}

/// One DPIP payload, in or out.
class DpipMeshPacket {
  const DpipMeshPacket({
    required this.kind,
    required this.body,
    this.schema = 1,
    this.from,
    this.receivedAt,
  });

  final DpipMeshKind kind;

  /// Version of [body]'s layout, owned by [kind].
  final int schema;

  /// The kind-specific payload, opaque to the transport.
  final Uint8List body;

  /// Sending node — inbound only.
  final int? from;

  /// When this device received it — inbound only.
  final DateTime? receivedAt;

  @override
  String toString() =>
      'DpipMeshPacket(${kind.name} v$schema, ${body.length} B'
      '${from != null ? ', from 0x${from!.toRadixString(16)}' : ''})';
}

/// Encodes and decodes the envelope above. Pure — no I/O, no logging, so it
/// can be golden-tested against fixed bytes.
abstract final class DpipMeshCodec {
  const DpipMeshCodec._();

  /// `'D'`, `'P'` — cheap rejection of anything else riding `PRIVATE_APP`.
  static const int magic0 = 0x44;
  static const int magic1 = 0x50;

  /// Envelope version this build speaks.
  static const int version = 1;

  /// Bytes before the body.
  static const int headerBytes = 5;

  /// The largest body one frame can carry.
  static const int maxBodyBytes = MeshPorts.maxPayloadBytes - headerBytes;

  /// Serialises [packet]. Throws [ArgumentError] for an over-long body —
  /// truncating a disaster payload would be worse than failing loudly.
  static Uint8List encode(DpipMeshPacket packet) {
    if (packet.body.length > maxBodyBytes) {
      throw ArgumentError.value(
        packet.body.length,
        'body',
        'exceeds the $maxBodyBytes B DPIP body budget',
      );
    }
    if (packet.schema < 0 || packet.schema > 0xFF) {
      throw ArgumentError.value(packet.schema, 'schema', 'must fit in a byte');
    }
    final bytes = Uint8List(headerBytes + packet.body.length)
      ..[0] = magic0
      ..[1] = magic1
      ..[2] = version
      ..[3] = packet.kind.code
      ..[4] = packet.schema
      ..setRange(headerBytes, headerBytes + packet.body.length, packet.body);
    return bytes;
  }

  /// Parses [bytes], or returns null when they are not a DPIP envelope this
  /// build understands (foreign private-app traffic, a newer envelope
  /// version, an unknown kind, a truncated frame).
  static DpipMeshPacket? decode(
    List<int> bytes, {
    int? from,
    DateTime? receivedAt,
  }) {
    if (bytes.length < headerBytes) return null;
    if (bytes[0] != magic0 || bytes[1] != magic1) return null;
    if (bytes[2] != version) return null;
    final kind = DpipMeshKind.fromCode(bytes[3]);
    if (kind == null) return null;
    return DpipMeshPacket(
      kind: kind,
      schema: bytes[4],
      body: Uint8List.fromList(bytes.sublist(headerBytes)),
      from: from,
      receivedAt: receivedAt,
    );
  }
}

/// The channel DPIP traffic travels on.
///
/// Fixed by product decision, not by the user: every DPIP node must land on
/// the same channel or nothing decrypts. The name and the key together define
/// the channel hash the radios match on, so both are part of the contract.
abstract final class DpipMeshChannel {
  const DpipMeshChannel._();

  /// Channel name, as it appears on the radio.
  static const String name = 'DPIP';

  /// The pre-shared key, base64 `AQ==`. A single-byte PSK is Meshtastic
  /// shorthand for a well-known key (`0x01` = the default key) — this channel
  /// is about reaching every DPIP node, not about secrecy.
  ///
  /// **Open decision:** that key is published, so this channel gives no
  /// authenticity. Anyone within radio range can encrypt a well-formed
  /// [DpipMeshKind.eew] packet and every DPIP app that hears it will accept
  /// it. Fixing that needs a signature the app can verify (a public key
  /// shipped in the app, private keys held by DPIP's gateways), which fits in
  /// a new [DpipMeshPacket.schema] for each kind without touching the
  /// envelope. Until then, treat a mesh-sourced alert as unauthenticated.
  static const List<int> psk = [0x01];

  /// The LoRa region every DPIP radio in Taiwan must be on. A radio on the
  /// wrong region transmits on frequencies its neighbours never hear.
  static const String region = 'TW';

  /// What [MeshtasticService.ensureChannel] provisions.
  static const MeshChannelSpec spec = MeshChannelSpec(name: name, psk: psk);
}
