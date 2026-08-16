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

  /// Sends [payload] on [portnum] over [channel] (the counterpart of
  /// [dataStream]) — to the whole mesh, or to [destination] alone.
  ///
  /// [portnum] is a Meshtastic app port; DPIP traffic uses
  /// [MeshPorts.private] and broadcasts (no [destination]), because a warning
  /// is for everyone in range. [destination] addresses one node instead, which
  /// some ports *require*: the firmware refuses a multi-hop
  /// [MeshPorts.traceroute] to the broadcast address outright, since one probe
  /// would make every node that heard it answer every other — see [traceRoute].
  ///
  /// Payloads are capped by the LoRa frame — see [MeshPorts.maxPayloadBytes].
  /// [wantResponse] asks the destination to unicast a reply, which is how
  /// [traceRoute] collects its answer. [wantAck] asks the mesh to retransmit
  /// until the destination confirms.
  ///
  /// Returns the **packet id** it went out with — the only handle on a packet
  /// once it leaves. The radio names it in a refusal ([noticeStream]), and a
  /// reply carries it back, which is how a caller tells its own answer from
  /// someone else's.
  Future<Result<int>> sendData({
    required int portnum,
    required List<int> payload,
    int channel = 0,
    int? destination,
    bool wantAck = false,
    bool wantResponse = false,
  });

  /// Asks the mesh for the path [nodeNum] is reached by, and yields it on
  /// [routeStream] when the destination answers.
  ///
  /// One request + one reply on the air (each re-flooded by the hops it
  /// passes), 30 s of firmware cooldown between attempts, and only nodes on
  /// the same channel key can participate — the cheapest on-demand path
  /// probe the mesh offers.
  ///
  /// Addressed to [nodeNum], never broadcast: the radio's own firmware drops a
  /// multi-hop traceroute aimed at the broadcast address and warns the phone
  /// (`Multi-hop traceroute to broadcast address is not allowed`), because
  /// one such probe would amplify into every node interrogating every other.
  Future<Result<int>> traceRoute(int nodeNum);

  /// Traceroute replies ([MeshPorts.traceroute] packets), decoded.
  Stream<MeshRoute> get routeStream;

  /// The attached radio's own packet counters, as it reports them.
  ///
  /// The cheapest ground truth in the app: the firmware sends `LocalStats`
  /// straight down the BLE link every ~15 minutes and never over the air, so
  /// reading it costs nothing at all. It answers what no other signal can —
  /// how many packets the *modem* actually saw versus how many survived the
  /// link to us, how many were corrupt, how many were duplicates the mesh
  /// already had, and how often this radio relayed for someone else.
  Stream<MeshLocalStats> get localStatsStream;

  /// The last [localStatsStream] value, or null before the first arrives.
  MeshLocalStats? get localStats;

  /// The radio talking back about something we asked it to do — a refusal, a
  /// rate limit, a warning.
  ///
  /// Without this every in-radio rejection is indistinguishable from silence:
  /// the send returns [Ok] (the packet did reach the radio), nothing goes on
  /// the air, and the caller waits out its timeout for an answer that was
  /// never coming. The radio said what was wrong — this is where it is heard.
  Stream<MeshNotice> get noticeStream;

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

  /// Sets the radio's clock to [utc], unless it already has a better source.
  ///
  /// The radio stamps every packet it delivers with its own RTC, and DPIP does
  /// not otherwise set it — so a radio that inherited a wrong time from a
  /// mis-set phone or a mesh peer times-stamps the whole conversation and the
  /// whole node table wrongly, and the app ages both against a calibrated
  /// clock. One local admin write fixes the source instead of every consumer.
  ///
  /// Safe to send unconditionally: the firmware ranks its own time sources and
  /// refuses a downgrade, so a GPS-disciplined radio ignores it. Returns
  /// whether the write reached the radio.
  Future<Result<bool>> setRadioTime(DateTime utc);

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

  /// `TRACEROUTE_APP` — the on-demand path probe. The payload is a
  /// `RouteDiscovery` protobuf; see [traceRoute].
  static const int traceroute = 70;

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

  /// Received packet count per app port, for the diagnostics panel.
  ///
  /// Inbound only, deliberately: what arrives comes from every app on the
  /// mesh, so the breakdown says something. What leaves is only ever ours —
  /// chat and DPIP — and the totals already cover it.
  final Map<int, int> rxByPort;

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

/// One hop of a traced route.
class MeshRouteHop {
  const MeshRouteHop({required this.num, this.snr});

  /// Node id (hex elsewhere in the mesh UI). `0xFFFFFFFF` marks a hop the
  /// route crossed but could not name — its firmware predates the route
  /// fields, or it lacks the channel key.
  final int num;

  /// The signal this hop received the probe with, in dB. Null when the hop's
  /// firmware predates per-hop SNR (or the lists were a different length).
  final double? snr;
}

/// The path a traceroute found, in both directions.
///
/// LoRa links are asymmetric, which is why the route back is recorded
/// separately — the way back can differ from the way there.
class MeshRoute {
  const MeshRoute({
    required this.towards,
    required this.back,
    required this.target,
  });

  /// Nothing came back (a decode failure, or no reply at all).
  const MeshRoute.none() : towards = const [], back = const [], target = null;

  /// Origin → destination, both endpoints included.
  ///
  /// The wire carries only the hops *between* them — see [decodeMeshRoute],
  /// which puts the ends back. So a direct neighbour is a two-entry list, not
  /// an empty one.
  final List<MeshRouteHop> towards;

  /// Destination → origin (only firmware ≥ 2.5 records it), same convention.
  final List<MeshRouteHop> back;

  /// The node the probe reached — taken from the reply's sender, not guessed
  /// from the hop list.
  ///
  /// It cannot be read off [towards]: the wire's route excludes both
  /// endpoints, so the last entry there is the final *relay* on a multi-hop
  /// path and nothing at all on a direct one.
  final int? target;

  /// Relays between the two ends — 0 for a direct neighbour.
  int get relayCount => towards.length < 2 ? 0 : towards.length - 2;
}

/// The attached radio's counters, cumulative since it booted.
///
/// Every field is a running total, so a consumer wants the *difference*
/// between two samples — and must check [uptime] first, because a reboot
/// zeroes the lot and a naive subtraction turns that into a huge negative
/// spike.
class MeshLocalStats {
  const MeshLocalStats({
    required this.uptime,
    required this.rxPackets,
    required this.rxBadPackets,
    required this.txPackets,
    required this.rxDupePackets,
    required this.txRelay,
    required this.txRelayCanceled,
    required this.heapFree,
    required this.heapTotal,
    this.channelUtilization,
    this.airUtilTx,
    this.nodesOnline,
    this.nodesTotal,
  });

  /// Time since boot — the reset detector. Going backwards between samples
  /// means every other counter restarted too.
  final Duration uptime;

  /// Packets the modem demodulated, including ones the phone never saw.
  final int rxPackets;

  /// Packets that failed their CRC. Rising while channel utilization is flat
  /// is interference, not congestion — nothing else separates the two.
  final int rxBadPackets;

  final int txPackets;

  /// Packets discarded because the mesh had already delivered them. Near zero
  /// means this radio sits on a single-path edge; high means dense, redundant
  /// coverage. That ratio *is* the resilience of its physical position.
  final int rxDupePackets;

  /// Packets this radio rebroadcast for the mesh.
  final int txRelay;

  /// Rebroadcasts abandoned because someone else got there first. A low share
  /// means this radio is the only path — the mesh depends on it; a high share
  /// means it is redundant.
  final int txRelayCanceled;

  final int heapFree;
  final int heapTotal;

  final double? channelUtilization;
  final double? airUtilTx;
  final int? nodesOnline;
  final int? nodesTotal;
}

/// Something the radio refused, limited or warned about.
///
/// [replyId] is the id of the packet it is about — match it against what
/// [MeshtasticService.sendData] returned to know whether it concerns you. It
/// is 0 for an unsolicited notice.
class MeshNotice {
  const MeshNotice({
    required this.replyId,
    required this.message,
    required this.isError,
  });

  final int replyId;
  final String message;

  /// Error rather than warning/info — the firmware's own severity.
  final bool isError;
}

/// A channel slot on the radio.
/// How many channel slots a Meshtastic radio has. Fixed by the firmware.
const int meshChannelSlots = 8;

/// Whether [value] can be a channel **index** rather than a channel **hash**.
///
/// `MeshPacket.channel` carries two different things depending on the packet:
///
/// * On a packet the radio could decrypt, it is the channel index — `0`–`7`.
/// * On one it could **not**, it is the channel *hash*: a single byte derived
///   from the channel's name and key, which is how a receiver decides which of
///   its channels is worth trying. Anything from `0` to `255`.
///
/// So a foreign mesh's traffic arrives claiming channel 242, 92, 227 — real
/// values seen on air — and any code that reads the field as an index invents
/// conversations, badges and notification titles for channels that do not
/// exist ("CH242"). The two cases are indistinguishable from the number alone,
/// which is why this is a named check rather than an inline `< 8`.
///
/// A hash *can* land in `0`–`7` by coincidence; that is unavoidable and
/// harmless, because a packet that reaches app code at all is one the radio
/// already decrypted.
bool isMeshChannelIndex(int value) => value >= 0 && value < meshChannelSlots;

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
    this.batteryLevel,
    this.voltage,
    this.lastHeard,
    this.latitude,
    this.longitude,
    this.snr = 0,
    this.viaMqtt = false,
    this.hopsAway,
  });

  /// Node id (radio number, hex elsewhere in the mesh UI).
  final int num;

  final String displayName;
  final int? batteryLevel;

  /// Pack voltage, when the node reports it. Battery *percent* is the radio's
  /// own estimate from this figure and reads 101% on external power; the volts
  /// are the raw measurement and the only one that shows a cell ageing.
  final double? voltage;
  final DateTime? lastHeard;
  final double? latitude;
  final double? longitude;
  final double snr;

  /// Heard only through an MQTT bridge — over the internet rather than over
  /// the air. Such a node may be on the other side of the world, so it is not
  /// evidence of radio reach.
  final bool viaMqtt;

  /// How many relays the node's last packet crossed to reach us — 0 for a
  /// direct neighbour, null when the radio does not know.
  ///
  /// Free: the firmware derives it from the plaintext LoRa header of packets
  /// it already heard, so it costs no transmission at all. It is a sample from
  /// the last packet, not a property of the node — a node whose path changes
  /// reports a different number without anything else changing.
  ///
  /// Null is *unknown*, never 0. A node running firmware older than the field,
  /// or one heard only through MQTT, has no hop distance; showing those as
  /// direct neighbours would overstate reach exactly where it matters.
  final int? hopsAway;
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
