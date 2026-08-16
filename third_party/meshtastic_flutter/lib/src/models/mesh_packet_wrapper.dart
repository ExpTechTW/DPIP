import 'dart:convert';

import '../../generated/mesh.pb.dart';
import '../../generated/portnums.pb.dart';

/// Wrapper class for MeshPacket with additional convenience methods
class MeshPacketWrapper {
  final MeshPacket packet;

  const MeshPacketWrapper(this.packet);

  /// The original packet
  MeshPacket get original => packet;

  /// Sender node ID
  int get from => packet.from;

  /// Destination node ID (0 for broadcast)
  int get to => packet.to;

  /// Channel this packet was sent on
  int get channel => packet.channel;

  /// Packet ID for tracking
  int get id => packet.id;

  /// Hop limit for routing
  int get hopLimit => packet.hopLimit;

  /// Priority level
  MeshPacket_Priority get priority => packet.priority;

  /// Whether this packet wants an ACK
  bool get wantAck => packet.wantAck;

  /// Timestamp when packet was received
  int get rxTime => packet.rxTime;

  /// Signal strength (RSSI)
  int get rxRssi => packet.rxRssi;

  /// Signal to noise ratio
  double get rxSnr => packet.rxSnr;

  /// The decoded data payload
  Data? get decoded => packet.hasDecoded() ? packet.decoded : null;

  /// The encrypted payload (if not decoded)
  List<int>? get encrypted => packet.hasEncrypted() ? packet.encrypted : null;

  /// The port number indicating the app/service
  PortNum? get portnum => decoded?.portnum;

  /// Whether this is a text message
  bool get isTextMessage => portnum == PortNum.TEXT_MESSAGE_APP;

  /// Whether this is telemetry data
  bool get isTelemetry => portnum == PortNum.TELEMETRY_APP;

  /// Whether this is a position update
  bool get isPosition => portnum == PortNum.POSITION_APP;

  /// Whether this is a node info update
  bool get isNodeInfo => portnum == PortNum.NODEINFO_APP;

  /// Whether this is a routing packet
  bool get isRouting => portnum == PortNum.ROUTING_APP;

  /// Whether this is an admin packet
  bool get isAdmin => portnum == PortNum.ADMIN_APP;

  /// Get the text message content (if this is a text message)
  String? get textMessage {
    if (!isTextMessage || decoded == null) return null;
    try {
      return utf8.decode(decoded!.payload, allowMalformed: true);
    } catch (e) {
      return null;
    }
  }

  /// Get the JSON payload as a string (if applicable)
  String? get jsonPayload {
    if (decoded == null) return null;
    try {
      return utf8.decode(decoded!.payload, allowMalformed: true);
    } catch (e) {
      return null;
    }
  }

  /// Whether this packet is encrypted
  bool get isEncrypted => packet.hasEncrypted();

  /// Whether this packet has been decoded
  bool get isDecoded => packet.hasDecoded();

  /// Whether this is a broadcast message (to == 0)
  bool get isBroadcast => to == 0;

  /// Whether this is a direct message (to != 0)
  bool get isDirectMessage => to != 0;

  /// Get a human-readable description of the packet type
  String get packetTypeDescription {
    if (portnum == null) return 'Unknown';

    switch (portnum!) {
      case PortNum.TEXT_MESSAGE_APP:
        return 'Text Message';
      case PortNum.REMOTE_HARDWARE_APP:
        return 'Remote Hardware';
      case PortNum.POSITION_APP:
        return 'Position';
      case PortNum.NODEINFO_APP:
        return 'Node Info';
      case PortNum.ROUTING_APP:
        return 'Routing';
      case PortNum.ADMIN_APP:
        return 'Admin';
      case PortNum.TELEMETRY_APP:
        return 'Telemetry';
      case PortNum.ZPS_APP:
        return 'ZPS';
      case PortNum.SIMULATOR_APP:
        return 'Simulator';
      case PortNum.TRACEROUTE_APP:
        return 'Traceroute';
      case PortNum.NEIGHBORINFO_APP:
        return 'Neighbor Info';
      case PortNum.ATAK_PLUGIN:
        return 'ATAK Plugin';
      case PortNum.MAP_REPORT_APP:
        return 'Map Report';
      case PortNum.PRIVATE_APP:
        return 'Private App';
      case PortNum.ATAK_FORWARDER:
        return 'ATAK Forwarder';
      default:
        return 'Unknown (${portnum!.value})';
    }
  }

  @override
  String toString() {
    return 'MeshPacketWrapper(from: $from, to: $to, channel: $channel, '
        'type: $packetTypeDescription, id: $id, encrypted: $isEncrypted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeshPacketWrapper && other.packet == packet;
  }

  @override
  int get hashCode => packet.hashCode;
}
