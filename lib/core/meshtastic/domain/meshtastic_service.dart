/// Domain surface for the LoRa mesh (Meshtastic) transport.
///
/// The interface and its models are **package-free**: they deliberately expose
/// none of `meshtastic_flutter` / `flutter_blue_plus` types, so the
/// presentation layer depends only on this file and the transport can be
/// swapped without touching a widget. The BLE impl lives in
/// `data/meshtastic_client_impl.dart`.
///
/// Connection and messaging are streams (push-style, like every other
/// realtime surface in the app); one-shot operations return [Result] so a
/// failure is explicit. Scanning is a stream whose error events carry
/// transport failures.
library;

import 'package:dpip/core/error/result.dart';

abstract class MeshtasticService {
  /// Requests Bluetooth/location permissions and verifies the adapter is on.
  ///
  /// Idempotent — the first scan or connect calls it implicitly, so a page
  /// that only sends can skip it. The OS may show a permission dialog.
  Future<Result<void>> initialize();

  /// Yields nearby Meshtastic radios until [timeout] elapses.
  ///
  /// Errors (permission denied, adapter off) surface as stream errors; the
  /// stream always ends after the timeout even if devices keep arriving.
  Stream<MeshDevice> scanForDevices({Duration timeout});

  /// Connects to a scanned device and downloads its configuration.
  ///
  /// Replaces any existing connection. Configuration can take a few seconds;
  /// watch [connectionStream] for `connecting` → `configuring` → `connected`.
  Future<Result<void>> connect(MeshDevice device);

  /// Connects to a radio by its BLE id without scanning first — how a saved
  /// radio is picked back up after a drop or an app restart.
  ///
  /// The id is only guaranteed meaningful to this app on iOS, so a failure
  /// here is normal and the caller should fall back to [scanForDevices].
  Future<Result<void>> connectToId(String id);

  /// Who currently holds the BLE link to [deviceId].
  ///
  /// A radio speaks its phone protocol to **one** client at a time: two apps
  /// draining the same mailbox steal each other's packets. This is the only
  /// signal either platform gives us about that.
  Future<MeshLinkOwner> linkOwner(String deviceId);

  /// Drops the connection and clears cached nodes.
  Future<Result<void>> disconnect();

  /// Broadcasts [text] on [channel] (0 = the primary channel).
  ///
  /// Fails with a typed failure when not connected or not configured.
  Future<Result<void>> sendText(String text, {int channel = 0});

  /// Connection lifecycle: connecting / configuring / connected / error …
  Stream<MeshConnectionStatus> get connectionStream;

  /// Every node known to the mesh (including the local radio).
  Stream<MeshNode> get nodeStream;

  /// Incoming mesh packets that carry text.
  Stream<MeshMessage> get messageStream;

  /// Every decoded packet the radio delivers, whatever its app port — the
  /// seam the DPIP data plane listens on (see `dpip_mesh_gateway.dart`).
  Stream<MeshDataPacket> get dataStream;

  /// Broadcasts [payload] on [portnum] over [channel] (the counterpart of
  /// [dataStream]).
  ///
  /// [portnum] is a Meshtastic app port; DPIP traffic uses
  /// [MeshPorts.private]. Payloads are capped by the LoRa frame — see
  /// [MeshPorts.maxPayloadBytes].
  Future<Result<void>> sendData({
    required int portnum,
    required List<int> payload,
    int channel = 0,
    bool wantAck = false,
  });

  /// Packet counters for the current session.
  ///
  /// Exists because a healthy mesh link is mostly **silent**: between events
  /// there is nothing on screen to distinguish "connected and listening" from
  /// "the link died ten minutes ago". A rising receive count is the cheapest
  /// honest proof that the radio is still talking to us.
  MeshTraffic get traffic;

  /// [traffic] on every packet in or out — what a heartbeat indicator watches.
  Stream<MeshTraffic> get trafficStream;

  /// Everything the attached radio has told us about itself, or null before
  /// the config download finishes.
  MeshRadioInfo? get radioInfo;

  /// The radio's channel table as last downloaded (empty before that).
  List<MeshChannel> get channels;

  /// The radio's LoRa region code (`TW`, `EU_868`, `UNSET`…), or null before
  /// the config download.
  String? get region;

  /// The attached radio's own node number, or null before the download.
  int? get myNodeNum;

  /// Makes sure a channel matching [spec] exists on the radio, creating it in
  /// a free slot when it doesn't; returns the channel index.
  ///
  /// Never overwrites a channel the user already uses — if every secondary
  /// slot is taken it fails rather than clobbering one.
  Future<Result<int>> ensureChannel(MeshChannelSpec spec);

  /// Sets the LoRa region.
  ///
  /// **Disruptive**: the firmware disables Bluetooth and reboots the radio
  /// when radio parameters change, so the link drops for ~10 s and every
  /// other Meshtastic client of that radio is affected too. Ask first.
  Future<Result<void>> applyRegion(String region);

  /// Whether a radio is connected and configured.
  bool get isConnected;
}

/// Who holds the BLE link to a radio.
enum MeshLinkOwner {
  /// Nobody on this phone — a normal connect.
  free,

  /// This app already has a link (a stale one is dropped before reconnecting).
  thisApp,

  /// Another app on this phone (typically the official Meshtastic client).
  /// Neither platform lets us close it; the user has to.
  otherApp,
}

/// Meshtastic app ports DPIP speaks, and the frame budget they share.
abstract final class MeshPorts {
  const MeshPorts._();

  /// `PRIVATE_APP` — the port range Meshtastic reserves for private
  /// application traffic. DPIP's disaster payloads ride here so they never
  /// land in anyone's chat.
  static const int private = 256;

  /// `TEXT_MESSAGE_APP`.
  static const int text = 1;

  /// Largest payload one mesh frame carries (`DATA_PAYLOAD_LEN`). A DPIP
  /// packet that doesn't fit must be split by its own schema — the transport
  /// never fragments.
  static const int maxPayloadBytes = 233;

  /// Share of [maxPayloadBytes] held back from anything a user composes.
  ///
  /// The transport only measures the payload, but what actually goes on air
  /// carries the `Data` and `MeshPacket` framing around it, and a radio may
  /// refuse a frame that lands right on the edge. Spending the last few bytes
  /// buys nothing and risks a message that silently doesn't send.
  static const double payloadHeadroom = 0.05;

  /// What a composed message may occupy, in **UTF-8 bytes** — not characters.
  /// One Chinese character costs three of these, so a character count would
  /// promise roughly three times the room that exists.
  static const int maxTextBytes = 221; // (233 * 0.95).floor()
}

/// Packets in and out since the app started, counted at the transport — one
/// place, whether or not anything is listening to a stream.
class MeshTraffic {
  const MeshTraffic({
    this.rxPackets = 0,
    this.txPackets = 0,
    this.rxBytes = 0,
    this.txBytes = 0,
    this.rxUndecoded = 0,
    this.rxByPort = const {},
    this.txByPort = const {},
    this.lastRx,
    this.lastTx,
  });

  final int rxPackets;
  final int txPackets;

  /// Payload bytes, not frame bytes — the transport never sees the on-air
  /// size, so this is what it can honestly report.
  final int rxBytes;
  final int txBytes;

  /// Packets the radio couldn't decrypt (a channel this radio has no key
  /// for). They still prove the link is alive, which is why they're counted.
  final int rxUndecoded;

  /// Packet count per app port, for the diagnostics panel.
  final Map<int, int> rxByPort;
  final Map<int, int> txByPort;

  final DateTime? lastRx;
  final DateTime? lastTx;

  bool get isEmpty => rxPackets == 0 && txPackets == 0;
}

/// A snapshot of the attached radio: who it is, what it runs, how it's doing.
class MeshRadioInfo {
  const MeshRadioInfo({
    required this.nodeNum,
    this.longName,
    this.shortName,
    this.hardware,
    this.firmware,
    this.role,
    this.region,
    this.modemPreset,
    this.hopLimit,
    this.txPower,
    this.batteryPercent,
    this.voltage,
    this.channelUtilization,
    this.airUtilTx,
    this.uptime,
    this.metricsAt,
    this.isLicensed = false,
    this.hasWifi = false,
    this.hasBluetooth = false,
  });

  /// The radio's own node number.
  final int nodeNum;

  final String? longName;
  final String? shortName;

  /// Board model (`HELTEC_V3`, `TBEAM`…) and firmware version string.
  final String? hardware;
  final String? firmware;

  /// Device role (`CLIENT`, `ROUTER`…).
  final String? role;

  /// LoRa region and modem preset — what decides who can hear this radio.
  final String? region;
  final String? modemPreset;
  final int? hopLimit;
  final int? txPower;

  /// Battery charge. A mains-powered radio reports 101; callers should show
  /// that as "plugged in" rather than a percentage.
  final int? batteryPercent;
  final double? voltage;

  /// Share of airtime seen busy, and share this radio spent transmitting —
  /// the two numbers that say whether the mesh around it is congested.
  final double? channelUtilization;
  final double? airUtilTx;

  final Duration? uptime;

  /// When the battery/airtime figures above were last reported. A charge
  /// reading without its age is worse than none — the radio only broadcasts
  /// telemetry every few minutes, so a stale number looks live.
  final DateTime? metricsAt;

  final bool isLicensed;
  final bool hasWifi;
  final bool hasBluetooth;

  /// Whether the radio is running off external power rather than a battery.
  bool get isPluggedIn => (batteryPercent ?? 0) > 100;
}

/// One decoded packet, whatever its app port.
class MeshDataPacket {
  const MeshDataPacket({
    required this.from,
    required this.channel,
    required this.portnum,
    required this.payload,
    required this.timestamp,
  });

  final int from;
  final int channel;
  final int portnum;
  final List<int> payload;
  final DateTime timestamp;
}

/// A channel slot on the radio.
class MeshChannel {
  const MeshChannel({
    required this.index,
    required this.name,
    required this.psk,
    required this.enabled,
  });

  final int index;
  final String name;

  /// Pre-shared key. A single byte is Meshtastic shorthand for a well-known
  /// key (`0x01` = the default key, base64 `AQ==`).
  final List<int> psk;

  /// Whether the slot is in use (role != DISABLED).
  final bool enabled;
}

/// The channel DPIP wants to exist on the radio.
class MeshChannelSpec {
  const MeshChannelSpec({required this.name, required this.psk});

  final String name;
  final List<int> psk;
}

/// Connection lifecycle of the attached radio.
enum MeshConnectionState {
  /// Not connected to any radio.
  disconnected,

  /// BLE link up, configuration download in progress.
  connecting,

  /// Connected and receiving configuration.
  configuring,

  /// Connected and ready for communication.
  connected,

  /// Connection lost or a fatal error.
  error,
}

/// A radio discovered by [MeshtasticService.scanForDevices].
class MeshDevice {
  const MeshDevice({required this.id, required this.name});

  /// BLE address (`remoteId`), stable across scans — the handle [connect]
  /// uses.
  final String id;

  /// Advertised platform name (empty on some radios).
  final String name;

  @override
  bool operator ==(Object other) => other is MeshDevice && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MeshDevice($id, $name)';
}

/// Connection status of the attached radio.
class MeshConnectionStatus {
  const MeshConnectionStatus({
    required this.state,
    this.deviceName,
    this.errorMessage,
  });

  final MeshConnectionState state;
  final String? deviceName;
  final String? errorMessage;
}

/// A node on the mesh (the local radio or any heard neighbor).
class MeshNode {
  const MeshNode({
    required this.num,
    required this.displayName,
    required this.isOnline,
    this.batteryLevel,
    this.lastHeard,
    this.latitude,
    this.longitude,
    this.snr = 0,
    this.viaMqtt = false,
  });

  /// Node id (radio number, hex elsewhere in the mesh UI).
  final int num;

  final String displayName;
  final bool isOnline;
  final int? batteryLevel;
  final DateTime? lastHeard;
  final double? latitude;
  final double? longitude;
  final double snr;

  /// Heard only through an MQTT bridge — over the internet rather than over
  /// the air. Such a node may be on the other side of the world, so it is not
  /// evidence of radio reach.
  final bool viaMqtt;
}

/// A received text packet from the mesh.
class MeshMessage {
  const MeshMessage({
    required this.from,
    required this.channel,
    required this.text,
    required this.timestamp,
  });

  final int from;
  final int channel;
  final String text;
  final DateTime timestamp;
}
